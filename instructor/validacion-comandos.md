# Validación segura de comandos y salidas — curso v3

Validación ejecutada el **11 de julio de 2026**. El objetivo fue comprobar que
los comandos, salidas y guardias del material corresponden con Ubuntu 24.04 sin
instalar paquetes, crear usuarios, cambiar el firewall ni tocar discos del
sistema anfitrión.

## Entornos utilizados

| Entorno | Uso | Estado final |
|---|---|---|
| Host Ubuntu 24.04.4 LTS x86-64 | Lectura, archivos bajo `mktemp`, Docker y validación estática | Sin paquetes, usuarios, UFW, montajes ni LVM nuevos |
| Docker Compose 2.35.1 | Stack real Nginx–WordPress–MariaDB | Eliminado al cerrar la validación |
| Docker-in-Docker temporal con cgroup | Límite global de 2 GiB y de 1 GiB + hasta 2 GiB de swap | Contenedor y red eliminados |
| Contenedor Ubuntu 24.04 desechable | BIND, Kea y Netplan sin tocar red del host | Ejecutado con `--rm` |
| VM VirtualBox Ubuntu 24.04.4 temporal | SSH/SCP, swap, loop/LVM, systemd y UFW | VM, disco, seed, clave e imagen descargada eliminados |

Las VMs existentes del instructor no se modificaron. La VM de prueba utilizó
NAT y un reenvío temporal `127.0.0.1:2229 → 22`; nunca tuvo red puente.

## Resultado resumido

| Área | Prueba | Resultado |
|---|---|---|
| Correspondencia PDF | 53 apartados `1.1`–`13.4`, sin ausencias ni duplicados | OK |
| Retos | 13 capítulos, 13 retos, 13 enlaces y 13 anclas de solución | OK |
| Markdown | Fences balanceados y rutas locales existentes | OK |
| Bash | `bash -n` y ShellCheck 0.10.0 en todos los scripts del repositorio | OK |
| Compose | `docker compose config --quiet`, imágenes fijas y arranque ordenado | OK |
| Aplicación | MariaDB, WordPress y Nginx saludables; HTTP real mediante Nginx | OK |
| Concurrencia | Diez solicitudes simultáneas a `/healthz` | 10/10 OK |
| Memoria | Perfiles globales de 2 GiB y 1 GiB + swap, sin `OOMKilled` | OK |
| Persistencia | Reinicio de Compose, marcador en WordPress y fila de MariaDB | OK |
| Recuperación | Dump, archivos, manifiesto, SHA-256, borrado de volúmenes y restore | OK |
| SSH/SCP | VM efímera por clave, transferencia y hash local/remoto | OK |
| Almacenamiento | Imagen sparse, loop, GPT, PV/VG/LV, ext4, montaje y limpieza | OK |
| Seguridad | UFW conservó SSH; unidad systemd transitoria observada y retirada | OK |
| Configuración aislada | `named-checkzone`, `kea-dhcp4 -t` y `netplan generate --root-dir` | OK |
| Secretos | Archivos `600`, ignorados y ausentes de Git/logs | OK |
| Respaldo genérico | Backup/restore, destino interno rechazado y destino no vacío rechazado | OK |

La validación repetible de estructura está en
[`tests/validar-repositorio.sh`](../tests/validar-repositorio.sh).

## Stack de proyecto probado

Se descargaron y ejecutaron las etiquetas exactas:

```text
nginx:1.28.3-alpine
wordpress:7.0.0-php8.3-apache
mariadb:11.8.8-noble
```

Resultados observados en una ejecución representativa:

```text
db         healthy  OOMKilled=false  ~92 MiB / 320 MiB
wordpress  healthy  OOMKilled=false  ~19–27 MiB / 384 MiB
proxy      healthy  OOMKilled=false  ~6–8 MiB / 64 MiB
proxy port: 127.0.0.1:8080
db port:    sin publicación
backend:    internal=true
```

`/healthz` respondió `200`; la raíz de WordPress respondió `302` hacia
`http://127.0.0.1:8080/wp-admin/install.php` y la redirección terminó en `200`.
El puerto `:8080` es importante: sin él, el navegador saldría del túnel. El script
ya no considera suficiente el endpoint estático: también exige que la raíz
atravesada por Nginx y sus redirecciones entregue `200`, `301` o `302`. Así se detecta un WordPress
que abre TCP pero falla con HTTP 500 por no acceder a MariaDB.

Se creó un marcador dentro del volumen de WordPress y una tabla de evidencia
en MariaDB. Después se ejecutó:

1. respaldo con dump consistente, archivos y manifiesto;
2. SHA-256;
3. `down --volumes` mediante la restauración confirmada;
4. creación de volúmenes nuevos;
5. importación de base y archivos;
6. espera de health checks y HTTP real.

Ambos datos reaparecieron. El directorio de respaldos quedó `700`; archivo y
checksum, `600`.

## Prueba de memoria

Además de los límites por servicio, todo el daemon y el stack se encerraron en
un cgroup temporal:

| Perfil global | `memory.current` | Swap usada | Margen RAM | OOM |
|---|---:|---:|---:|---:|
| 2 GiB | 1,646,616,576 bytes | 0 | ~477 MiB | 0 |
| 1 GiB + hasta 2 GiB swap | 762,818,560 bytes | 42,606,592 bytes | ~296 MiB | 0 |

Con el perfil de 1 GiB los tres contenedores continuaron `healthy`, las diez
solicitudes concurrentes terminaron y `oom_kill` permaneció en cero. El margen
fue superior a los 100 MiB requeridos. El curso mantiene arranque secuencial y
no compila imágenes en EC2.

Se repitió además un **cold start** con daemon vacío y el límite de 1 GiB activo
desde antes del `pull`: descargó las tres imágenes, arrancó por dependencias y
terminó sin OOM. El pico tocó el límite y produjo reclamación (`max=2644`), pero
`oom=0`/`oom_kill=0`; después había unos 638 MiB de `inactive_file` reclamable.
Los servicios seguían sanos, 10/10 peticiones pasaron y la ruta completa
`302 → 200` conservó `:8080`.

## Validación en VM Ubuntu 24.04

La VM temporal tenía 1 GiB de RAM. `configurar-swap.sh 2` creó 2 GiB de swap y
dejó `vm.swappiness=10`. Una segunda invocación solicitando 1 GiB fue rechazada
sin redimensionar silenciosamente la swap existente.

### SSH y SCP

Se generó una clave ED25519 temporal, se copió `data/proyecto/app.conf` y se
comparó SHA-256 en ambos extremos:

```text
938a25b7942ceb24db88034a758bf9135ae252ec6e15e6225b8871654b499bfb
```

La clave y la VM fueron eliminadas al terminar.

### Loop y LVM

Los scripts crearon únicamente:

```text
storage-lab.img (512 MiB lógicos)
└─ /dev/loop0
   └─ /dev/loop0p1
      └─ vg_consultor_1000/lv_respaldos (320 MiB, ext4)
```

Se verificaron backing file, tipo loop, parent de la partición, PV, VG, LV y
fuente del montaje. La limpieza desmontó, retiró LV/VG/PV, liberó el loop y
eliminó la imagen; el dispositivo raíz siguió siendo `/dev/sda1`. También se
probó la limpieza de una creación parcial que sólo tenía imagen + loop.

La ejecución real reveló que `lsblk` podía incluir descendientes del LVM al
consultar `PKNAME`; se corrigieron scripts, capítulo y solución usando
`--nodeps`. Éste es el tipo de discrepancia que una revisión sólo sintáctica no
habría detectado.

### systemd y UFW

Una unidad transitoria `consultor-validation.service` pasó por `active/running`,
se inspeccionó y se retiró. UFW se habilitó con el perfil OpenSSH permitido; la
sesión SSH siguió activa. Después se ejecutó `ufw --force reset` y quedó
`inactive` dentro de la VM desechable.

## BIND, Kea, Netplan y cron

- `named-checkzone curso.test data/dns/db.curso.test` cargó el serial
  `2026071101` y terminó en `OK`.
- BIND se inició como `bind` sólo en TCP/UDP `127.0.0.1:1053`: respondió
  autoritativamente `web.curso.test → 192.0.2.80`, rechazó una consulta externa
  y cerró ambos sockets con `SIGTERM`; `controls {}` evitó abrir 953.
- `kea-dhcp4 -t data/dhcp/kea-dhcp4.conf` terminó con estado 0. El fixture usa
  sólo `lo` y socket UDP; no selecciona una interfaz de EC2 ni abre UDP/67.
- `netplan generate --root-dir <raiz-temporal>` aceptó `lab0` y generó
  `10-netplan-lab0.network`; no se ejecutó `netplan apply`.
- `crontab -n <archivo>` aceptó el candidato sin instalarlo.

## Pruebas negativas relevantes

| Caso | Resultado esperado observado |
|---|---|
| Backup dentro de su propio origen | Rechazado antes de crear archivo |
| Restauración hacia directorio no vacío | Rechazada |
| Apagado menor de 30 minutos | Uso inválido, sin programar nada |
| Swap existente con otro tamaño | Rechazada; archivo activo sin cambios |
| LVM sin autoridad `sudo` | Abortó antes de asociar un loop |
| Puerto MariaDB consultado con Compose | Sin publicación |
| Restore sin `--confirmar` | Estado 2 y ninguna destrucción |

## Pasos que requieren una cuenta AWS

No se ejecutaron, para no crear costos ni cambiar una cuenta real:

- alta de cuenta, MFA, Free account plan y AWS Budgets;
- lanzamiento o terminación de una EC2 real;
- cambio de créditos T3 a `standard`;
- Security Group con la IP pública `/32`;
- inspección de Billing, EC2 Global View y `DeleteOnTermination`;
- túnel contra una IPv4 pública de EC2.

Esos pasos son verificaciones de consola descritas en `prerrequisitos.md`. Los
flujos SSH, SCP, túnel local, Ubuntu 24.04 y perfil de 1 GiB se reprodujeron sin
depender de AWS. El material no promete costo cero a quien no confirme primero
la elegibilidad de su cuenta.

## Adecuaciones derivadas de las pruebas

- Health check de WordPress y comprobación HTTP fortalecidos.
- Nginx conserva el puerto de `Host`, evitando redirecciones fuera del túnel.
- Wrapper de WordPress ajustado para leer el secreto antes de delegar al
  entrypoint oficial, sin imprimirlo.
- Backups protegidos con modos `700`/`600`.
- Kea limitado a loopback y Netplan a la interfaz ficticia `lab0`.
- Guardias LVM alineadas y recuperación de estados parciales.
- Consulta `lsblk PKNAME` corregida con `--nodeps`.
- Swap existente de tamaño distinto ya no produce un falso éxito.
- Restauración vuelve a esperar WordPress después de reiniciarlo.
- MariaDB se valida mediante `docker compose port`, no por un `ss` ambiguo del
  host.

## Garantía de limpieza

- No se instalaron paquetes, usuarios, sudoers, reglas UFW ni LVM en el host.
- No se usaron discos, particiones, montajes o swaps del host.
- La VM temporal, su VMDK, seed ISO, OVA y clave privada fueron eliminados.
- Los contenedores y volúmenes del proyecto se eliminaron sin ejecutar
  `docker system prune`.
- Los únicos artefactos persistentes son los archivos versionables de este
  repositorio.
