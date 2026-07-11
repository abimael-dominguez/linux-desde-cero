# 2. Instalación y configuración inicial

## Objetivos

Al terminar este capítulo podrás:

- preparar una EC2 Ubuntu 24.04 ajustada al presupuesto del curso;
- conectarte por SSH entendiendo cada parámetro;
- programar y cancelar un apagado preventivo;
- reconocer la jerarquía principal y el almacenamiento montado;
- crear explícitamente el usuario `deploy` y el grupo `ops`;
- comprobar la configuración sin conceder privilegios innecesarios.

## Contexto y alcance

En AWS no instalaremos Ubuntu desde una ISO: la AMI ya contiene el sistema instalado. El trabajo de este módulo es **seleccionar, verificar y configurar** esa instalación.

| Recurso | Valor del curso |
|---|---|
| Región | `us-east-1` |
| AMI | Ubuntu Server 24.04 LTS, x86-64 y elegible según la cuenta |
| Instancia recomendada | `t3.small` para el plan gratuito nuevo |
| Perfil anterior | `t3.micro`, sólo si la cuenta conserva ese beneficio |
| Disco raíz | 20 GiB `gp3`, cifrado y con eliminación al terminar la EC2 |
| Administrador | `ubuntu` |
| Usuario operativo | `deploy` |
| Grupo | `ops` |
| Proyecto | `/srv/consultor-linux` |

“Free Tier” no significa que cualquier recurso sea gratuito. Antes de crear la instancia sigue [prerrequisitos.md](prerrequisitos.md), revisa la etiqueta de elegibilidad de tu cuenta y configura las alertas de presupuesto.

Los textos entre `< >` describen parámetros y no se copian literalmente. Los bloques marcados como ejemplos completos ya contienen los nombres `ubuntu`, `deploy`, `ops` y `/srv/consultor-linux`.

## Modelo mental

```text
equipo del alumno                     AWS
┌──────────────────┐      SSH      ┌──────────────────────┐
│ llave privada    │ ────────────► │ EC2 Ubuntu 24.04     │
│ cliente ssh      │   TCP/22      │ usuario: ubuntu      │
└──────────────────┘                │ disco raíz: 20 GiB   │
                                    └──────────────────────┘
                                             │
                           / ── /etc /home /srv /var /tmp
```

El **Security Group** filtra tráfico en AWS. Los permisos de archivos y `sudo` controlan acciones dentro de Ubuntu. Son capas diferentes.

## 2.1 Crear la EC2 sin recursos adicionales

En la consola de AWS confirma, antes de pulsar **Launch instance**:

- una sola instancia y una sola AMI oficial de Ubuntu;
- tipo compatible con los beneficios vigentes de tu cuenta;
- créditos de CPU T3 en modo `standard`, no `unlimited`;
- 20 GiB `gp3`, cifrado, rendimiento predeterminado y `Delete on termination`;
- IPv4 pública automática, sin Elastic IP;
- regla de entrada SSH `TCP/22` desde **My IP** (`/32`), nunca `0.0.0.0/0`;
- etiquetas `Course=consultor-linux` y `DeleteAfter=<fecha-del-fin>`;
- sin RDS, balanceador, NAT Gateway, snapshots ni monitoreo detallado.

Después de iniciarla anota su IPv4 pública. Al detener y volver a iniciar la EC2 esa dirección normalmente cambia.

### Fallback local con VirtualBox

Si tu cuenta no tiene un beneficio vigente, crea una VM local con Ubuntu Server 24.04:

1. 2 vCPU, 2 GiB de RAM y disco virtual dinámico de 20 GiB;
2. red NAT; usa reenvío de puertos sólo si necesitas SSH desde el host;
3. usuario inicial `ubuntu` para que los ejemplos coincidan;
4. instalación mínima con OpenSSH Server;
5. una instantánea local **antes** del curso, no un snapshot de AWS.

Los comandos Linux serán los mismos. Los pasos de Billing y Security Groups no aplican a VirtualBox.

### ¿Qué cambiaría con Debian?

Debian también ofrece imágenes oficiales para nube y una instalación mínima para VirtualBox. Mantiene `apt`, systemd y la misma jerarquía general, pero la cuenta inicial de una imagen cloud puede llamarse `debian` y la política de `sudo` puede diferir. Para que una misma práctica produzca resultados comparables, el laboratorio obligatorio usa Ubuntu 24.04; Debian se presenta como alternativa, no como una segunda instalación paralela.

## 2.2 Conectarse por SSH

Sintaxis parametrizada:

```bash
ssh -i <ruta_llave_privada> <usuario>@<ip_publica>
```

| Marcador | Ejemplo | Cómo obtenerlo |
|---|---|---|
| `<ruta_llave_privada>` | `$HOME/.ssh/consultor-linux.pem` | Ruta donde guardaste el `.pem`. |
| `<usuario>` | `ubuntu` | Usuario de la AMI oficial de Ubuntu. |
| `<ip_publica>` | valor de EC2 | Consola: **Public IPv4 address**. |

Bloque copiable: sólo cambia el valor de `CLAVE`; la IP se solicita para evitar dejar una dirección obsoleta en el historial del documento.

```bash
CLAVE="$HOME/.ssh/consultor-linux.pem"
read -r -p "IPv4 pública de la EC2: " IP_PUBLICA
chmod 600 "$CLAVE"
ssh -i "$CLAVE" "ubuntu@$IP_PUBLICA"
```

- `-i`: indica la llave privada de identidad.
- `chmod 600`: permite lectura y escritura sólo al propietario; OpenSSH rechaza llaves expuestas.
- `read -r -p`: muestra una pregunta y guarda la respuesta sin interpretar barras invertidas.
- Las comillas protegen rutas con espacios.

En la primera conexión OpenSSH preguntará por la autenticidad del host. Antes de aceptar, confirma que la IP corresponde a tu instancia. En conexiones posteriores un cambio inesperado de huella se investiga; no se elimina la advertencia automáticamente.

## 2.3 Verificar la instalación

Ya dentro de la EC2:

```bash
whoami
hostnamectl
cat /etc/os-release
systemd-detect-virt
cloud-init status
timedatectl
```

Salida representativa:

```text
ubuntu
Operating System: Ubuntu 24.04.x LTS
Virtualization: amazon
status: done
```

`cloud-init status` debe terminar en `done` antes de asumir que finalizó la configuración inicial. La virtualización puede aparecer como `amazon`, `kvm` u otro valor en el fallback local.

Los servidores suelen conservar UTC para correlacionar logs entre regiones. `timedatectl` permite verificarlo; no es necesario cambiar la zona horaria del sistema para mostrar horarios de CDMX en las instrucciones del curso.

Actualiza sólo el índice de paquetes en este punto:

```bash
sudo apt update
```

`apt update` descarga catálogos; no equivale a `apt upgrade` y no instala todas las actualizaciones. La gestión de paquetes se profundiza en el módulo 10.

## Apagado preventivo de seis horas

Al comenzar cada sesión programa una salvaguarda:

```bash
sudo shutdown -h +360 "Fin preventivo del laboratorio Consultor Linux"
```

- `-h`: detiene el sistema.
- `+360`: espera 360 minutos, es decir, seis horas.
- En EC2, el comportamiento normal configurado para un apagado iniciado por el sistema es detener la instancia; aun así debes verificarlo en la consola.

Si la clase termina antes, puedes apagar ahora:

```bash
sudo shutdown -h now
```

Si necesitas continuar y sólo quieres cancelar el apagado programado:

```bash
sudo shutdown -c
```

Un apagado no elimina el volumen EBS. Al final del curso se **terminará** la instancia y se comprobará que su volumen raíz también fue eliminado.

## 2.4 Jerarquía del sistema de archivos

Linux presenta una sola jerarquía que comienza en `/`.

| Ruta | Contenido práctico | Regla de seguridad |
|---|---|---|
| `/etc` | configuración del sistema y servicios | no editar sin respaldo y validador |
| `/home` | archivos personales | una carpeta por usuario humano |
| `/srv` | datos servidos por aplicaciones | aquí vivirá el proyecto |
| `/var/log` | logs variables | consultar antes de borrar |
| `/tmp` | temporales | no asumir persistencia |
| `/usr` | programas y bibliotecas instalados | no copiar aplicaciones a mano |
| `/dev` | representaciones de dispositivos | nunca elegir un disco por intuición |
| `/proc` y `/sys` | vistas del kernel | normalmente se consultan, no se editan |

Comandos de inspección copiables:

```bash
pwd
ls -ld / /etc /home /srv /var/log /tmp
lsblk -f
findmnt /
df -hT /
```

Salida representativa del almacenamiento:

```text
TARGET SOURCE       FSTYPE OPTIONS
/      /dev/root    ext4   rw,relatime,...

Filesystem Type Size Used Avail Use% Mounted on
/dev/root  ext4  20G  ...   ...  ...  /
```

- `lsblk -f`: enumera dispositivos, sistemas de archivos y montajes.
- `findmnt /`: encuentra qué origen sostiene la raíz.
- `df -hT /`: muestra capacidad en unidades legibles (`-h`) y tipo (`-T`).

Estos comandos son de lectura. En este capítulo no se particiona ni formatea ningún dispositivo.

## Crear `ops` y `deploy`

Primero comprueba si existen. `getent` no imprime nada y devuelve un estado distinto de cero cuando no encuentra el registro:

```bash
getent group ops
getent passwd deploy
```

En una instalación limpia no habrá salida. Ahora crea los objetos explícitamente.

Sintaxis parametrizada:

```bash
sudo groupadd <grupo>
sudo useradd -U -m -s <shell> -G <grupo_secundario> <usuario>
```

Ejemplo completo para copiar **una sola vez**:

```bash
sudo groupadd ops
sudo useradd -U -m -s /bin/bash -G ops deploy
getent passwd deploy
getent group ops
id deploy
```

Qué representa cada nombre:

- `ops` es el equipo que compartirá permisos.
- `deploy` es la cuenta operativa; no es el administrador `ubuntu`.
- `-U` crea el grupo principal privado `deploy`.
- `-m` crea `/home/deploy`.
- `-s /bin/bash` asigna Bash como shell de inicio.
- `-G ops` agrega el grupo secundario `ops`.

Salida representativa; UID y GID pueden variar:

```text
deploy:x:1001:1002::/home/deploy:/bin/bash
ops:x:1001:deploy
uid=1001(deploy) gid=1002(deploy) groups=1002(deploy),1001(ops)
```

No agregues `deploy` al grupo `sudo` y no le asignes una contraseña compartida. Las tareas administrativas siguen perteneciendo a `ubuntu`.

Asocia la raíz del proyecto con el equipo, pero conserva acceso de sólo lectura para `ops` hasta estudiar permisos:

```bash
sudo chown ubuntu:ops \
  /srv/consultor-linux \
  /srv/consultor-linux/evidencias
sudo chmod 0750 \
  /srv/consultor-linux \
  /srv/consultor-linux/evidencias
ls -ld /srv/consultor-linux
```

Salida esperada:

```text
drwxr-x--- ... ubuntu ops ... /srv/consultor-linux
```

## Práctica guiada resuelta — Línea base verificable

```bash
sudo install -d -o ubuntu -g ops -m 0750 \
  /srv/consultor-linux/evidencias/02

{
  printf 'distribucion='
  . /etc/os-release
  printf '%s\n' "$PRETTY_NAME"
  printf 'usuario_admin=%s\n' "$(whoami)"
  printf 'usuario_operativo='
  getent passwd deploy
  printf 'grupo_operativo='
  getent group ops
  findmnt -no SOURCE,FSTYPE,TARGET /
  df -hT /
} | tee /srv/consultor-linux/evidencias/02/linea-base.txt

test -s /srv/consultor-linux/evidencias/02/linea-base.txt \
  && echo "Línea base creada"
```

- `findmnt -n` omite encabezados y `-o` elige columnas.
- Los registros de `getent` documentan exactamente qué identidades existen.
- La evidencia es propiedad de `ubuntu`; `deploy` puede leerla gracias al grupo `ops` y al modo `0750` del directorio.

Compruébalo:

```bash
sudo -u deploy cat /srv/consultor-linux/evidencias/02/linea-base.txt
```

`sudo -u deploy` ejecuta únicamente `cat` como el usuario operativo. No convierte a `deploy` en administrador.

## Fallo controlado — Acceso no concedido todavía

Intenta crear un archivo en la raíz como `deploy`:

```bash
sudo -u deploy touch /srv/consultor-linux/no-debe-crearse.txt
printf 'código=%s\n' "$?"
```

Salida esperada:

```text
touch: cannot touch '/srv/consultor-linux/no-debe-crearse.txt': Permission denied
código=1
```

Diagnóstico:

```bash
id deploy
namei -l /srv/consultor-linux/no-debe-crearse.txt
ls -ld /srv/consultor-linux
test ! -e /srv/consultor-linux/no-debe-crearse.txt \
  && echo "El archivo no fue creado"
```

El grupo tiene `r-x`, no `w`. Es un control correcto, no un problema que deba “resolverse” con `chmod 777`. En el capítulo 4 diseñaremos un directorio compartido específico.

## Reversión y limpieza

Conserva `deploy`, `ops` y `/srv/consultor-linux`: los siguientes módulos dependen de ellos. Si abandonas por completo el laboratorio, primero inspecciona:

```bash
getent passwd deploy
getent group ops
find /srv/consultor-linux -maxdepth 2 -printf '%M %u %g %p\n'
```

La eliminación del usuario y del proyecto se realizará sólo en la limpieza final del curso, después de respaldar evidencias. No ejecutes `userdel`, `groupdel` ni borrados recursivos entre clases.

## Reto 2 — Auditoría inicial de una EC2

Genera `/srv/consultor-linux/evidencias/02/auditoria-inicial.txt` con: virtualización detectada, estado de `cloud-init`, sistema de archivos raíz, uso del disco, memoria y registro completo de `deploy`. Añade al final una línea `APROBADA` sólo si la distribución es Ubuntu 24.04 y el usuario pertenece a `ops`.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-2)

### Criterios de éxito

- La evidencia se genera con comandos y conserva valores reales.
- `grep` permite localizar `Ubuntu 24.04`, `deploy`, `ops` y `APROBADA`.
- `deploy` puede leer la evidencia, pero no modificarla.
- No se abrió ningún puerto nuevo ni se creó un recurso adicional en AWS.

## Checklist

- [ ] Elegí una instancia compatible con el beneficio real de mi cuenta.
- [ ] SSH sólo está permitido desde mi IP `/32`.
- [ ] Programé el apagado preventivo y sé cancelarlo.
- [ ] Distingo `/etc`, `/home`, `/srv`, `/var`, `/tmp`, `/dev` y `/proc`.
- [ ] Creé y comprobé el usuario `deploy` y el grupo `ops`.
- [ ] `deploy` no pertenece a `sudo`.
- [ ] Entiendo que detener EC2 no elimina EBS.
