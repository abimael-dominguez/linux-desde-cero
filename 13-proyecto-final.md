# 13. Proyecto final: servidor Linux administrable y recuperable

## Objetivos

En este proyecto integrarás los trece módulos para entregar una EC2 que:

- se administra mediante identidades, permisos y SSH con clave;
- ejecuta un stack Nginx → WordPress/Apache → MariaDB;
- expone la aplicación sólo por loopback y un túnel SSH;
- conserva datos en volúmenes, limita recursos y rota logs;
- genera un respaldo con checksum y supera una restauración destructiva;
- deja evidencia y un runbook sin contraseñas;
- se elimina al terminar para evitar consumo innecesario de créditos.

No gana quien copia más comandos. El objetivo es poder responder, para cada paso: **qué cambia, cómo se comprueba, cómo se diagnostica y cómo se revierte**.

## 13.1 Caso de trabajo

Una organización necesita validar WordPress sin publicar todavía un sitio en Internet. El consultor debe entregar un entorno temporal para evaluación:

- una sola EC2 Ubuntu Server 24.04;
- `t3.small` para cuentas nuevas con plan gratuito basado en créditos, o `t3.micro` para el beneficio anterior si continúa vigente;
- un único volumen raíz `gp3` cifrado de 20 GiB;
- una IPv4 pública temporal, sin Elastic IP;
- un Security Group con TCP/22 desde la IP del alumno `/32`;
- ninguna base administrada, balanceador, NAT Gateway, Route 53, snapshot ni volumen adicional;
- máximo 30 horas encendida durante todo el curso;
- respaldo final descargado a la computadora del alumno.

El proyecto no promete costo cero para cualquier cuenta. Antes de crear recursos se debe comprobar el plan, los créditos y la vigencia de Free Tier. Si no existe cobertura, se usa VirtualBox.

## 13.2 Arquitectura final

```text
Computadora del alumno
  navegador → http://127.0.0.1:8080
  SSH/SCP ───────────────┐
                         │ TCP/22 desde IP /32
                         ▼
┌──────────────────── EC2 Ubuntu 24.04 ─────────────────────┐
│ sshd                                                     │
│   └─ túnel local → 127.0.0.1:8080                        │
│                         │                                 │
│                    [proxy] Nginx                          │
│                         │ red frontend                    │
│                  [wordpress] Apache/PHP                   │
│                         │ red backend interna             │
│                       [db] MariaDB                         │
│                         │                                 │
│              volúmenes + respaldo + checksum             │
└───────────────────────────────────────────────────────────┘
```

### Contrato de servicios

| Servicio | Imagen | Puerto del host | Persistencia | Límite del perfil `t3.micro` |
|---|---|---|---|---:|
| `proxy` | `nginx:1.28.3-alpine` | `127.0.0.1:8080` | configuración versionada | 64 MiB |
| `wordpress` | `wordpress:7.0.0-php8.3-apache` | ninguno | archivos de WordPress | 384 MiB |
| `db` | `mariadb:11.8.8-noble` | ninguno | datos de MariaDB | 320 MiB |

MariaDB usa un buffer pool de 64 MiB, máximo 20 conexiones y Performance Schema desactivado. Los logs usan rotación de 10 MiB y un máximo de tres archivos. No se usa la etiqueta `latest`.

## 13.3 Entregables

Al terminar debes conservar en tu computadora:

```text
entrega-consultor-linux/
├── evidencias/
│   ├── servicio-nginx.txt
│   ├── compose.txt
│   ├── hardening.txt
│   └── proyecto-final.txt
├── runbook.md
├── consultor-linux-<timestamp>.tar.gz
└── consultor-linux-<timestamp>.tar.gz.sha256
```

No incluyas:

- archivos `.pem`;
- contraseñas o secretos de Compose;
- contenido de `/etc/shadow`;
- tokens de IMDS o credenciales AWS;
- dumps adicionales sin cifrar fuera del respaldo controlado.

## 13.4 Inicio seguro de la sesión

### Paso 1. Programar una protección de apagado

Antes, confirma en la consola que **Instance initiated shutdown behavior** está configurado como `Stop`. La sintaxis del protector es:

```bash
bash scripts/programar-apagado.sh <minutos>
```

El marcador `<minutos>` no se copia literalmente. Ejemplo completo para seis horas:

```bash
cd ~/linux-desde-cero
bash scripts/programar-apagado.sh 360
```

El script acepta entre 30 y 720 minutos y ejecuta `sudo shutdown -h +360` para este ejemplo. Esto no sustituye el cierre manual al terminar, pero limita el olvido. Comprueba la programación:

```bash
shutdown --show
```

Si necesitas cancelarla porque el instructor extenderá una prueba:

```bash
sudo shutdown -c
```

### Paso 2. Confirmar contexto

```bash
whoami
hostnamectl --static
cat /etc/os-release | grep '^PRETTY_NAME='
free -h
df -h /
git -C ~/linux-desde-cero status --short
bash ~/linux-desde-cero/scripts/verificar-entorno.sh
```

Resultado esperado:

- usuario `ubuntu` para administración;
- Ubuntu 24.04 LTS;
- al menos 8 GiB libres antes de descargar imágenes, crear volúmenes y conservar respaldos;
- repositorio sin secretos rastreados.

`verificar-entorno.sh` reúne las comprobaciones de versión, arquitectura, memoria, swap, disco y comandos. Termina con estado distinto de cero si detecta un requisito bloqueante y distingue `AVISO` de `ERROR`.

### Paso 3. Confirmar AWS desde la consola

Antes de desplegar, revisa:

- una sola instancia del curso;
- tipo correcto (`t3.small` o `t3.micro` según la cuenta);
- créditos de CPU en modo `standard`, no `unlimited`;
- volumen raíz de 20 GiB con `Delete on termination` activado;
- ninguna Elastic IP;
- Security Group con una sola entrada SSH desde tu `/32`;
- etiquetas `Course=consultor-linux` y `DeleteAfter=<fecha>`;
- presupuesto de USD 5 configurado sobre costo antes de créditos, con alertas al 50 %, 80 % y 100 %.

La consola es la fuente para costos y recursos AWS; los comandos dentro de Linux no pueden demostrar por sí solos que no existe otro volumen o una Elastic IP olvidada.

## 13.5 Preparar el proyecto

Sitúate en la raíz:

```bash
cd ~/linux-desde-cero
```

### Revisar archivos antes de ejecutar

```bash
find proyecto-compose -maxdepth 3 -type f \
  ! -path '*/secrets/*' -print | sort
```

Debes reconocer:

```text
proyecto-compose/README.md
proyecto-compose/apache/low-memory.conf
proyecto-compose/compose.yaml
proyecto-compose/nginx/default.conf
proyecto-compose/php/consultor.ini
proyecto-compose/wordpress/entrypoint.sh
```

No es necesario imprimir los secretos.

### Confirmar que no hay secretos versionados

```bash
if git ls-files 'proyecto-compose/secrets/*' | grep -q .; then
  echo "FALLO: hay secretos rastreados por Git"
else
  echo "OK: no hay secretos rastreados"
fi
```

El script de preparación los generará después de validar los artefactos. No los crees a mano ni los guardes en Git.

### Validar Compose y Nginx

```bash
sudo docker compose -f proyecto-compose/compose.yaml config --quiet
bash -n proyecto-compose/wordpress/entrypoint.sh
sudo docker run --rm \
  --add-host wordpress:127.0.0.1 \
  --volume "$PWD/proyecto-compose/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx:1.28.3-alpine nginx -t
```

- `--volume origen:destino:ro`: monta la configuración como sólo lectura.
- `bash -n`: valida la sintaxis del wrapper de WordPress sin ejecutarlo ni leer secretos.
- `nginx -t`: prueba sintaxis sin dejar un servidor ejecutándose.
- `--rm`: elimina el contenedor de validación.

Salida esperada:

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

La imagen puede imprimir antes mensajes de su *entrypoint*. Los dos renglones finales son la evidencia de validación.

### Confirmar imágenes y publicación

```bash
grep -nE '^ *image:' proyecto-compose/compose.yaml
grep -n '127.0.0.1:8080:80' proyecto-compose/compose.yaml
```

Debes encontrar las tres etiquetas fijas y una publicación ligada a loopback. Una búsqueda textual ayuda a revisar, pero la validación de Compose sigue siendo obligatoria.

## 13.6 Desplegar y comprobar

### Preparación, descarga y arranque secuencial

Lee la interfaz y ejecuta el script sin elevarlo completo:

```bash
less scripts/preparar-proyecto.sh
bash scripts/preparar-proyecto.sh
```

Sal de `less` con `q`. El script genera secretos, valida Compose, descarga las imágenes una por una e inicia `db`, `wordpress` y `proxy` en ese orden, esperando la salud de cada capa. Detecta por sí mismo si Docker necesita `sudo`.

Comprueba que los secretos creados no son públicos ni rastreados:

```bash
stat -c '%a %U:%G %n' proyecto-compose/secrets/*.txt
git check-ignore proyecto-compose/secrets/*.txt
```

Los dos archivos deben mostrar modo `600` y ambas rutas deben aparecer en la segunda salida.

Si el preparador termina con error:

```bash
sudo docker compose -f proyecto-compose/compose.yaml ps
sudo docker compose -f proyecto-compose/compose.yaml logs --tail 50 --timestamps
```

Corrige la causa; no aumentes límites ni borres volúmenes a ciegas.

### Lista de comprobación técnica

```bash
sudo docker compose -f proyecto-compose/compose.yaml ps
sudo docker compose -f proyecto-compose/compose.yaml port proxy 80
if sudo docker compose -f proyecto-compose/compose.yaml port db 3306; then
  echo "FALLO: db publicó el puerto 3306"
else
  echo "OK: db no publicó el puerto 3306"
fi
sudo ss -lnt '( sport = :8080 )'
sudo docker compose -f proyecto-compose/compose.yaml exec -T wordpress \
  getent hosts db
curl --silent --show-error --output /dev/null \
  --write-out 'HTTP %{http_code}\n' \
  http://127.0.0.1:8080/
free -m
df -h /
sudo docker stats --no-stream
```

Estado aprobado:

- tres servicios `running` o `healthy`;
- `proxy` publica `127.0.0.1:8080`;
- `db` no publica puerto;
- `wordpress` resuelve `db`;
- HTTP responde `200`, `301` o `302`;
- ningún contenedor está `OOMKilled`;
- disco por debajo de 70 %;
- al menos 100 MiB disponibles en `t3.micro`.

El control de MariaDB se hace con `docker compose port db 3306`, no buscando cualquier socket 3306 con `ss`: otro servicio instalado directamente en el host podría usar ese número y producir una conclusión falsa.

### Comprobar límites y rotación

```bash
for SERVICIO in proxy wordpress db; do
  ID="$(sudo docker compose -f proyecto-compose/compose.yaml ps -q "$SERVICIO")"
  sudo docker inspect --format \
    "$SERVICIO memory={{.HostConfig.Memory}} log={{json .HostConfig.LogConfig}}" \
    "$ID"
done
```

`Memory` se muestra en bytes y debe ser distinto de cero. El log debe incluir `max-size=10m` y `max-file=3`.

## 13.7 Completar WordPress mediante el túnel

En una terminal de tu **computadora**, no dentro de EC2:

```bash
CLAVE="$HOME/.ssh/consultor-linux.pem"
IP_EC2="IP_ACTUAL"
chmod 600 "$CLAVE"
ssh -i "$CLAVE" -L 8080:127.0.0.1:8080 "ubuntu@$IP_EC2"
```

Sustituye `IP_ACTUAL` por la IPv4 pública actual de la consola. Luego abre `http://127.0.0.1:8080` en el navegador.

Para el asistente de WordPress:

1. selecciona idioma;
2. usa `Consultor Linux` como título del sitio;
3. crea un administrador con nombre no trivial;
4. genera la contraseña con un administrador de contraseñas;
5. usa una dirección de demostración que controles o `alumno@example.invalid`;
6. crea una entrada llamada `Evidencia antes del respaldo` con una frase única.

No guardes la contraseña de WordPress en el repositorio ni en las evidencias. La frase única permite demostrar posteriormente que los datos fueron restaurados.

Comprueba desde EC2:

```bash
curl --fail --silent --show-error http://127.0.0.1:8080/ \
  | grep -F 'Consultor Linux' > /dev/null \
  && echo "Sitio configurado"
```

Si el tema no imprime el título en esa página, verifica visualmente la entrada y registra el código HTTP en lugar de forzar una búsqueda incorrecta.

## 13.8 Hardening y diagnóstico

Aplica lo estudiado en el capítulo 12 y registra el estado:

```bash
sudo ufw status verbose
sudo sshd -T | grep -E \
  '^(passwordauthentication|permitrootlogin|allowtcpforwarding|maxauthtries) '
systemctl is-active apparmor
sudo ss -lntp
sudo docker compose -f proyecto-compose/compose.yaml logs \
  --tail 20 --timestamps proxy wordpress db
```

Desde tu computadora abre una segunda sesión SSH y vuelve a comprobar el túnel. La entrega se rechaza si el alumno sólo puede entrar por una sesión antigua que quedó abierta.

### Diagnóstico de afuera hacia adentro

Ante una página no disponible, sigue este orden:

```text
1. ¿la sesión SSH sigue conectada?
2. ¿el túnel local escucha en la computadora?
3. ¿127.0.0.1:8080 escucha dentro de EC2?
4. ¿proxy está healthy?
5. ¿proxy resuelve y alcanza wordpress?
6. ¿wordpress resuelve y alcanza db?
7. ¿qué muestran los logs correlacionados por hora?
8. ¿hay memoria y disco disponibles?
```

No empieces destruyendo contenedores: primero conserva evidencia del fallo.

## 13.9 Crear y descargar el respaldo

### Generar en EC2

```bash
cd ~/linux-desde-cero
bash scripts/respaldo-proyecto.sh
```

El script produce:

```text
backups/consultor-linux-<timestamp>.tar.gz
backups/consultor-linux-<timestamp>.tar.gz.sha256
```

Selecciona y valida el más reciente:

```bash
RESPALDO="$(find backups -maxdepth 1 -type f \
  -name 'consultor-linux-*.tar.gz' -printf '%T@ %p\n' \
  | sort -nr | head -n 1 | cut -d' ' -f2-)"

test -n "$RESPALDO"
(cd "$(dirname "$RESPALDO")" \
  && sha256sum --check "$(basename "$RESPALDO").sha256")
tar -tzf "$RESPALDO" | sed -n '1,25p'
printf 'Archivo para descargar: %s\n' "$RESPALDO"
```

No continúes a la prueba destructiva si el checksum no informa `OK`.

### Descargar desde la computadora

Primero copia el nombre impreso, sin el prefijo `backups/`. En una terminal local:

```bash
CLAVE="$HOME/.ssh/consultor-linux.pem"
IP_EC2="IP_ACTUAL"
ARCHIVO="consultor-linux-TIMESTAMP.tar.gz"
DESTINO="$HOME/entrega-consultor-linux"

mkdir -p "$DESTINO"
scp -i "$CLAVE" \
  "ubuntu@$IP_EC2:~/linux-desde-cero/backups/$ARCHIVO" \
  "ubuntu@$IP_EC2:~/linux-desde-cero/backups/$ARCHIVO.sha256" \
  "$DESTINO/"
```

Sustituye `IP_ACTUAL` y `consultor-linux-TIMESTAMP.tar.gz` por valores reales. Después:

```bash
cd "$HOME/entrega-consultor-linux"
sha256sum --check "$ARCHIVO.sha256"
```

La copia local debe informar `OK`. Este archivo sobrevivirá aunque la EC2 sea terminada.

## 13.10 Incidente controlado: pérdida de los volúmenes

Esta prueba es deliberadamente destructiva. Sólo se autoriza cuando:

- el respaldo y su `.sha256` existen en EC2;
- el checksum local también dio `OK`;
- la entrada `Evidencia antes del respaldo` está visible;
- el instructor confirmó el momento de la práctica.

### Restaurar mediante la interfaz protegida

El script de restauración exige esta interfaz exacta:

```bash
bash scripts/restaurar-proyecto.sh <archivo.tar.gz> --confirmar
```

`<archivo.tar.gz>` es un marcador que debes sustituir; no se copia literalmente. Ejemplo resuelto con la variable creada en la sección anterior:

```bash
cd ~/linux-desde-cero
bash scripts/restaurar-proyecto.sh "$RESPALDO" --confirmar
```

| Argumento | Valor | Propósito |
|---|---|---|
| `<respaldo.tar.gz>` | variable `"$RESPALDO"` | Archivo que se validará y restaurará |
| `--confirmar` | literal | Reconoce que se reemplazarán los datos actuales |

Sin `--confirmar`, el script debe negarse a modificar volúmenes. No ejecutes manualmente una combinación de `rm`, `docker volume rm` o rutas internas de Docker.

Después de validar el checksum y el contenido del archivo, el script ejecuta `docker compose down --volumes` exclusivamente para `consultor-linux`, crea volúmenes nuevos, espera la salud de MariaDB, importa la base, restaura los archivos de WordPress y vuelve a levantar el proxy. Por eso esta práctica sí demuestra recuperación después de perder los volúmenes, no sólo una copia sobre datos existentes.

### Verificar recuperación

```bash
sudo docker compose -f proyecto-compose/compose.yaml ps
curl --silent --show-error --output /dev/null \
  --write-out 'HTTP %{http_code}\n' \
  http://127.0.0.1:8080/
sudo docker compose -f proyecto-compose/compose.yaml logs \
  --tail 20 --timestamps db wordpress proxy
```

En el navegador, confirma que reaparecen:

- el título `Consultor Linux`;
- la entrada `Evidencia antes del respaldo`;
- el contenido único escrito antes del incidente.

Ésta es la diferencia entre “tener un archivo” y “tener una estrategia de recuperación probada”.

## 13.11 Evidencia final reproducible

Crea el informe sin secretos:

```bash
mkdir -p /srv/consultor-linux/evidencias
INFORME="/srv/consultor-linux/evidencias/proyecto-final.txt"

{
  echo '# Proyecto final Consultor Linux'
  date --iso-8601=seconds
  echo "Host: $(hostname)"
  echo "Usuario: $(whoami)"
  echo
  echo '## Sistema'
  grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release
  uname -r
  echo
  echo '## Identidades'
  getent passwd deploy
  getent group ops
  echo
  echo '## Servicios Compose'
  sudo docker compose -f proyecto-compose/compose.yaml ps
  echo
  echo '## Red publicada'
  sudo docker compose -f proyecto-compose/compose.yaml port proxy 80
  if sudo docker compose -f proyecto-compose/compose.yaml port db 3306; then
    echo 'FALLO: db tiene puerto publicado'
  else
    echo 'OK: db sin puerto publicado'
  fi
  echo
  echo '## HTTP'
  curl --silent --show-error --output /dev/null \
    --write-out 'HTTP %{http_code}\n' \
    http://127.0.0.1:8080/
  echo
  echo '## Hardening'
  sudo ufw status verbose
  sudo sshd -T | grep -E \
    '^(passwordauthentication|permitrootlogin|allowtcpforwarding|maxauthtries) '
  echo "AppArmor: $(systemctl is-active apparmor)"
  echo
  echo '## Secretos: sólo metadatos'
  find proyecto-compose/secrets -maxdepth 1 -type f \
    -printf '%m %u:%g %p\n'
  echo
  echo '## Respaldo'
  (cd "$(dirname "$RESPALDO")" \
    && sha256sum --check "$(basename "$RESPALDO").sha256")
  echo
  echo '## Recursos'
  free -h
  df -h /
  sudo docker stats --no-stream
} | tee "$INFORME"

test -s "$INFORME" && echo "Evidencia creada"
```

Antes de entregarlo:

```bash
if grep -Ein 'password|BEGIN .*PRIVATE KEY|aws_secret' "$INFORME"; then
  echo "Revisar manualmente posibles datos sensibles"
else
  echo "No se detectaron patrones sensibles obvios"
fi
```

La búsqueda es preventiva y puede señalar palabras de configuración como `passwordauthentication`; revisa el contexto. No garantiza por sí sola que un documento sea seguro.

## 13.12 Runbook de operación

Crea `runbook.md` con instrucciones breves que otra persona pueda ejecutar. Debe incluir:

1. **Propósito y arquitectura.** Qué ejecuta el servidor y por qué sólo se accede por túnel.
2. **Inicio.** `docker compose up -d --wait` y comprobaciones.
3. **Parada no destructiva.** `docker compose stop`.
4. **Estado.** `ps`, `ss`, `curl`, memoria y disco.
5. **Logs.** Servicio, intervalo y límite de líneas.
6. **Respaldo.** Script, ubicación y checksum.
7. **Restauración.** Precondiciones y bandera `--confirmar`.
8. **Incidentes.** Secuencia de diagnóstico de afuera hacia adentro.
9. **Acceso.** Forma parametrizada del túnel, sin IP antigua ni ruta privada real.
10. **Cierre AWS.** Descarga, limpieza, terminación y revisión de Billing.

Un runbook no es una narración de la clase: es una secuencia operativa, con resultados esperados y condiciones para detenerse.

## 13.13 Reto integrador: entrega a otro consultor

Prepara una entrega que otro compañero pueda auditar sin preguntarte nada. Debe:

1. desplegar el stack desde un repositorio limpio;
2. mostrar tres servicios sanos y recursos dentro de límites;
3. demostrar que sólo loopback publica el servicio web;
4. acceder por túnel SSH;
5. conservar la entrada única de WordPress;
6. producir un respaldo y checksum;
7. destruir y restaurar datos mediante el script protegido;
8. generar `proyecto-final.txt` y `runbook.md` sin secretos;
9. descargar respaldo, checksum y evidencias a la computadora;
10. eliminar todos los recursos AWS del curso.

### Pistas

- Trabaja por fases: preparar, validar, desplegar, proteger, respaldar, destruir, restaurar y limpiar.
- No aceptes una captura de pantalla como única evidencia; conserva salida textual verificable.
- Usa siempre el nombre del servicio, no una IP de contenedor.
- La eliminación final se comprueba tanto en EC2 Global View como en Billing.

### Criterios de éxito

- La restauración recupera el contenido único creado antes del respaldo.
- `db` nunca estuvo publicado al host.
- El navegador sólo accedió mediante el túnel SSH.
- No hay secretos ni claves en Git o en la entrega.
- La evidencia identifica versiones, estados, puertos, checksum y recursos.
- La EC2 y su volumen raíz terminan eliminados.
- No quedan Elastic IP, snapshots, volúmenes adicionales ni Security Groups del curso.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-13)

## 13.14 Limpieza local del proyecto

Primero confirma que la copia local del respaldo sigue dando `OK`. Después, en EC2, el script puede detener sin borrar datos:

```bash
cd ~/linux-desde-cero
bash scripts/limpiar-proyecto.sh
```

Para el cierre definitivo, la eliminación de volúmenes requiere dos argumentos explícitos:

```bash
bash scripts/limpiar-proyecto.sh --eliminar-datos --confirmar
```

- `--eliminar-datos`: solicita retirar volúmenes persistentes del proyecto.
- `--confirmar`: reconoce que la acción es destructiva.

Comprobación:

```bash
sudo docker compose -f proyecto-compose/compose.yaml ps --all
sudo docker volume ls \
  --filter label=com.docker.compose.project=consultor-linux
```

No ejecutes `docker system prune`: podría afectar imágenes, redes o volúmenes ajenos al curso.

## 13.15 Terminación y comprobación de AWS

Detener es apropiado entre clases; **terminar** es lo correcto al concluir el curso.

### Antes de terminar

- [ ] Respaldo y `.sha256` están en la computadora.
- [ ] `sha256sum --check` informa `OK` localmente.
- [ ] Evidencias y runbook están descargados.
- [ ] No necesitas ningún archivo que exista sólo en EC2.

Apaga el sistema:

```bash
sudo shutdown -h now
```

### En la consola de AWS

1. espera a que la instancia aparezca `Stopped`;
2. selecciona **Terminate instance** y confirma;
3. comprueba que el volumen raíz con `DeleteOnTermination=true` desaparece;
4. confirma que no existen snapshots ni Elastic IP;
5. elimina el Security Group del curso cuando ya no esté asociado;
6. elimina el par de claves del curso en EC2;
7. conserva o destruye el `.pem` local según tu política, pero nunca lo subas a Git;
8. revisa **EC2 Global View** en todas las regiones usadas;
9. revisa Free Tier y Billing al día siguiente, porque el registro puede demorarse.

El volumen EBS continúa consumiendo créditos mientras la instancia está detenida. Sólo la terminación con borrado del volumen concluye ese recurso.

## 13.16 Rúbrica

| Área | Puntos | Evidencia mínima |
|---|---:|---|
| Linux, usuarios y permisos | 10 | `deploy`, `ops`, rutas y modos correctos |
| Servicios y diagnóstico | 10 | systemd, sockets y logs interpretados |
| Docker y Compose | 20 | tres servicios sanos, etiquetas fijas y límites |
| Red | 15 | loopback, red interna y túnel SSH |
| Seguridad | 15 | SG `/32`, UFW, SSH, AppArmor y secretos |
| Respaldo y restauración | 20 | checksum y contenido recuperado |
| Evidencia y runbook | 5 | documentos reproducibles y sin secretos |
| Cierre AWS | 5 | recursos eliminados y revisión global |
| **Total** | **100** | Aprobación sugerida: 80 |

Fallas críticas que impiden aprobar aunque el puntaje sume 80:

- contraseña, clave privada o token expuesto;
- SSH abierto a `0.0.0.0/0` al finalizar;
- MariaDB publicada al host;
- restauración no demostrada;
- EC2 o EBS olvidado después del cierre.

## Errores frecuentes

- **Usar una IP pública guardada de otra sesión.** Cambia al detener e iniciar una EC2 sin Elastic IP.
- **Completar WordPress antes de preparar persistencia.** Los datos desaparecerían al recrear el contenedor.
- **Respaldar sólo archivos.** WordPress también depende de la base de datos.
- **Destruir antes de descargar.** Conserva una copia verificada fuera de EC2.
- **Confundir `Stopped` con eliminado.** EBS sigue existiendo.
- **Compartir el `.pem` dentro de la entrega.** Es una credencial, no documentación.
- **Documentar una contraseña “temporal”.** Lo temporal suele terminar versionado.
- **Abrir 8080 para evitar el túnel.** Rompe el modelo de seguridad del proyecto.
- **Recrear todo ante un 502.** Primero revisa estado, DNS interno y logs.
- **Omitir el costo de IPv4 o CPU excedente.** Usa IPv4 temporal, T3 `standard`, límite de horas y alertas.

## Checklist final

- [ ] La arquitectura Nginx → WordPress/Apache → MariaDB funciona.
- [ ] Las imágenes tienen versiones fijas.
- [ ] Sólo `127.0.0.1:8080` está publicado por Compose.
- [ ] El acceso web ocurre mediante túnel SSH.
- [ ] UFW, OpenSSH y AppArmor fueron comprobados.
- [ ] Los secretos tienen modo `600` y Git los ignora.
- [ ] Los límites funcionan en el perfil elegido.
- [ ] El respaldo tiene checksum válido local y remoto.
- [ ] La restauración recuperó la evidencia de WordPress.
- [ ] El informe y el runbook no contienen secretos.
- [ ] La EC2, EBS y recursos relacionados fueron eliminados.
- [ ] Billing y EC2 Global View quedaron programados para revisión final.
