# 11. Virtualización, contenedores y Docker Compose

## Objetivos

Al terminar este capítulo podrás:

- explicar la diferencia entre una máquina virtual, una imagen y un contenedor;
- instalar y comprobar Docker Engine y el complemento Compose en Ubuntu 24.04;
- reconocer el alcance de seguridad del socket de Docker;
- validar y levantar una aplicación compuesta sin construir imágenes en EC2;
- comprobar redes, volúmenes, secretos, health checks, puertos y límites;
- operar el stack dentro de la memoria disponible en `t3.small` y `t3.micro`.

## Antes de empezar

Ejecuta este capítulo como el usuario inicial de Ubuntu, normalmente `ubuntu`, desde la raíz del repositorio:

```bash
cd ~/linux-desde-cero
test -f proyecto-compose/compose.yaml && echo "Proyecto Compose encontrado"
test -x scripts/preparar-proyecto.sh && echo "Preparador encontrado"
```

Si no aparecen ambos mensajes, corrige la ruta del repositorio antes de continuar.

Comprueba los recursos de la EC2:

```bash
printf '%s\n' '--- memoria ---'
free -h
printf '%s\n' '--- disco raíz ---'
df -h /
printf '%s\n' '--- tipo de instancia desde IMDSv2 ---'
TOKEN="$(curl --fail --silent --show-error --request PUT \
  --header 'X-aws-ec2-metadata-token-ttl-seconds: 60' \
  http://169.254.169.254/latest/api/token 2>/dev/null || true)"

if [[ -n "$TOKEN" ]]; then
  curl --fail --silent --show-error \
    --header "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-type
  printf '\n'
else
  echo "IMDS no disponible: probablemente estás en una VM local"
fi
```

IMDS es el servicio de metadatos accesible únicamente desde la instancia. Se solicita un token IMDSv2 temporal; no contiene credenciales. En VirtualBox aparecerá el mensaje alternativo.

## 11.1 Máquina virtual frente a contenedor

```text
Máquinas virtuales                  Contenedores
┌──────────┐  ┌──────────┐         ┌──────────┐  ┌──────────┐
│ app + SO │  │ app + SO │         │ app+libs │  │ app+libs │
└────┬─────┘  └────┬─────┘         └────┬─────┘  └────┬─────┘
     └──── hipervisor ────┘              └─ motor + kernel host ─┘
              hardware                          hardware
```

| Aspecto | Máquina virtual | Contenedor |
|---|---|---|
| Kernel | Cada VM tiene el suyo | Comparte el kernel del host |
| Arranque | Normalmente segundos o minutos | Normalmente segundos |
| Aislamiento | Límite de hipervisor | Namespaces, cgroups y otras capas del kernel |
| Uso típico | Sistemas completos, kernels distintos | Empaquetar y ejecutar aplicaciones |
| Artefacto base | Imagen de disco/AMI | Imagen OCI por capas |

Una EC2 ya es una máquina virtual. Dentro de ella ejecutaremos contenedores. Docker no reemplaza a AWS ni convierte un contenedor en una VM.

### VirtualBox como ruta de respaldo

Si la cuenta no tiene Free Tier vigente, utiliza una VM con Ubuntu Server 24.04:

- 2 vCPU, 2 GiB de RAM y 20 GiB de disco dinámico para el perfil recomendado;
- adaptador NAT;
- reenvío TCP del puerto `2222` del host al `22` del invitado;
- sin publicar 80, 443 ni 3306.

Desde el equipo anfitrión, la sintaxis es:

```bash
ssh -p <puerto_host> <usuario_vm>@127.0.0.1
```

Ejemplo resuelto, si configuraste el puerto `2222` y el usuario `ubuntu`:

```bash
ssh -p 2222 ubuntu@127.0.0.1
```

Los capítulos restantes funcionan igual dentro de EC2 o de esta VM; sólo cambia el modo de conexión y el cierre de recursos.

El procedimiento visual completo se conserva en el [anexo de VirtualBox](extras/virtualbox-fallback.md).

## 11.2 Modelo mental de Docker

```text
cliente docker → socket /var/run/docker.sock → daemon dockerd
                                               ├─ imágenes
                                               ├─ contenedores
                                               ├─ redes
                                               └─ volúmenes
```

| Objeto | Definición | Ejemplo del curso |
|---|---|---|
| Imagen | Plantilla inmutable por capas | `nginx:1.28.3-alpine` |
| Contenedor | Instancia ejecutable de una imagen | servicio `proxy` |
| Red | Segmento virtual y DNS interno | red entre `proxy`, `wordpress` y `db` |
| Volumen | Datos persistentes fuera de la capa escribible | WordPress y MariaDB |
| Compose | Declaración de varios servicios | `proyecto-compose/compose.yaml` |
| Secreto | Archivo sensible montado en tiempo de ejecución | `db_password.txt` |

Eliminar un contenedor no elimina automáticamente sus volúmenes. A la inversa, `docker compose down --volumes` sí borra los volúmenes del proyecto y se reserva para la prueba de restauración y el cierre final.

## 11.3 Instalar Docker sin mezclar canales

El curso usa Docker Engine y Compose v2 desde el repositorio oficial de Docker. El script `bootstrap-ubuntu.sh` configura la llave, el repositorio y los paquetes mediante APT; no utiliza el instalador rápido obtenido con `curl | sh`.

No mezcles en el mismo host `docker.io`, un Snap de Docker y `docker-ce`: podrían aportar daemon, cliente y complementos de versiones incompatibles.

### Revisar y ejecutar el bootstrap

```bash
less scripts/bootstrap-ubuntu.sh
bash scripts/bootstrap-ubuntu.sh
```

Sal de `less` con `q`. El script:

- exige Ubuntu 24.04 y un usuario distinto de `root`;
- ejecuta `sudo -v` antes de cambiar el sistema;
- instala herramientas explícitas del curso;
- configura el repositorio oficial sólo si Docker no existe;
- instala `docker-ce`, `docker-ce-cli`, `containerd.io`, Buildx y Compose;
- no agrega al alumno al grupo `docker`.

### Consultar lo instalado

```bash
apt-cache policy docker-ce docker-compose-plugin
dpkg-query -W -f='${Status} ${Version}\n' \
  docker-ce docker-compose-plugin
sudo systemctl enable --now docker
```

La versión cambia conforme el repositorio publica actualizaciones. Ambos paquetes deben mostrar `install ok installed`.

Comprobación:

```bash
sudo docker version
sudo docker compose version
systemctl is-active docker
```

Salida representativa:

```text
Client: Docker Engine - Community
...
Server: Docker Engine - Community
...
Docker Compose version v2.x.x
active
```

El texto y la versión varían según el repositorio. Lo indispensable es que aparezcan cliente, servidor, Compose v2 y `active`.

### Por qué utilizamos `sudo docker`

El socket de Docker suele pertenecer a `root:docker`:

```bash
ls -l /var/run/docker.sock
```

Un miembro del grupo `docker` puede montar el sistema de archivos del host y obtener privilegios equivalentes a `root`. Por eso este curso **no** agrega automáticamente a `ubuntu` ni a `deploy` al grupo. Es más largo escribir `sudo`, pero deja explícita la elevación.

### Prueba mínima y limpieza

```bash
sudo docker run --rm alpine:3.22 sh -c \
  'printf "Contenedor: "; cat /etc/alpine-release'
```

- `run`: crea e inicia un contenedor.
- `--rm`: elimina el contenedor al terminar.
- `alpine:3.22`: imagen y etiqueta fija.
- `sh -c`: ejecuta el texto como un comando dentro del contenedor.

La imagen queda en caché, pero el contenedor temporal desaparece. No utilizamos `latest` porque una práctica debe poder repetirse con la misma base.

## 11.4 Leer Compose antes de ejecutarlo

El archivo del curso declara estos servicios:

| Servicio | Imagen fija | Responsabilidad | Publicación al host |
|---|---|---|---|
| `proxy` | `nginx:1.28.3-alpine` | Entrada y proxy inverso | `127.0.0.1:8080` |
| `wordpress` | `wordpress:7.0.0-php8.3-apache` | Aplicación, Apache y PHP | Ninguna |
| `db` | `mariadb:11.8.8-noble` | Base de datos | Ninguna |

No se construyen imágenes en EC2: se descargan imágenes publicadas con etiquetas fijas. Esto ahorra CPU, disco y créditos.

### Validación sin crear recursos

Desde la raíz del repositorio:

```bash
sudo docker compose -f proyecto-compose/compose.yaml config --quiet
sudo docker compose -f proyecto-compose/compose.yaml config --services
```

Salida esperada de servicios, aunque el orden puede variar:

```text
db
wordpress
proxy
```

- `-f`: selecciona explícitamente el archivo Compose.
- `config`: combina y valida el modelo.
- `--quiet`: no imprime el documento; devuelve éxito o error.
- `--services`: lista los nombres resultantes.

Comprueba que no se usa `latest`:

```bash
grep -nE '^ *image:' proyecto-compose/compose.yaml
if grep -nE \
  'image:[[:space:]]*[^#[:space:]]+:latest([[:space:]#]|$)|image:[[:space:]]*[^:/[:space:]]+([[:space:]#]|$)' \
  proyecto-compose/compose.yaml; then
  echo "Revisar: se encontró una imagen sin versión fija"
else
  echo "Etiquetas explícitas encontradas"
fi
```

La segunda expresión es una protección didáctica, no un analizador completo de YAML. La autoridad final es `docker compose config`.

## 11.5 Preparar y desplegar mediante un script legible

### Protección de memoria para `t3.micro`

Si la consola confirma que tu instancia es `t3.micro` y `free -h` muestra cerca de 1 GiB de RAM, crea 2 GiB de swap con el script acotado del curso:

```bash
less scripts/configurar-swap.sh
sudo bash scripts/configurar-swap.sh 2
swapon --show
sysctl vm.swappiness
```

Sal de `less` con `q`. La salida debe identificar `/swapfile-consultor-linux`, aproximadamente `2G`, y `vm.swappiness = 10`. El script sólo administra ese archivo y una configuración llamada `99-consultor-linux-swap.conf`; aborta si encuentra un objeto inesperado con el mismo nombre.

Comprueba que aún hay espacio suficiente:

```bash
df -h /
```

No continúes con menos de 8 GiB libres: las imágenes, volúmenes y dos copias del respaldo necesitan margen. En `t3.small`, la swap no es un requisito; sigue la indicación del instructor.

Reversión, únicamente después de detener el stack:

```bash
sudo bash scripts/configurar-swap.sh --eliminar
```

### Secretos y arranque

No escribas contraseñas dentro de `compose.yaml`. El preparador realiza de forma visible el flujo completo:

1. detecta si Docker se ejecuta directamente o mediante `sudo`;
2. genera los dos secretos si no existen y conserva los existentes;
3. valida Compose;
4. descarga imágenes de una en una;
5. inicia MariaDB, espera su health check y continúa con WordPress y Nginx;
6. comprueba `/healthz` por loopback.

Antes de ejecutarlo, léelo:

```bash
less scripts/preparar-proyecto.sh
```

Sal con `q`. Después ejecuta:

```bash
bash scripts/preparar-proyecto.sh
```

No antepongas `sudo` al script completo. El propio script eleva únicamente los comandos de Docker cuando es necesario, por lo que los secretos quedan propiedad del alumno.

Artefactos creados:

```text
proyecto-compose/secrets/db_root_password.txt
proyecto-compose/secrets/db_password.txt
```

Comprueba metadatos, no el contenido:

```bash
stat -c '%a %U:%G %n' proyecto-compose/secrets/*.txt
git check-ignore proyecto-compose/secrets/*.txt
```

Salida representativa:

```text
600 ubuntu:ubuntu proyecto-compose/secrets/db_password.txt
600 ubuntu:ubuntu proyecto-compose/secrets/db_root_password.txt
proyecto-compose/secrets/db_password.txt
proyecto-compose/secrets/db_root_password.txt
```

- modo `600`: sólo el propietario puede leer y escribir;
- `git check-ignore`: devuelve las rutas si están protegidas de un commit accidental.

No uses `cat` para demostrar una contraseña frente al grupo ni la pegues en evidencias.

### Cómo recibe WordPress el secreto sin imprimirlo

Compose monta `db_password` en `/run/secrets/db_password`. El archivo está protegido para que no sea legible por cualquier proceso. El contenedor de WordPress utiliza el wrapper versionado `proyecto-compose/wordpress/entrypoint.sh`:

1. comienza con los privilegios iniciales del contenedor;
2. comprueba que `/run/secrets/db_password` sea legible;
3. carga el valor en `WORDPRESS_DB_PASSWORD` **sin escribirlo en la salida**;
4. elimina la variable `WORDPRESS_DB_PASSWORD_FILE` para evitar ambigüedad;
5. entrega el control al entrypoint oficial de WordPress, que finalmente inicia Apache con su usuario de servicio.

Puedes revisar y validar el wrapper sin leer el secreto:

```bash
sed -n '1,160p' proyecto-compose/wordpress/entrypoint.sh
bash -n proyecto-compose/wordpress/entrypoint.sh
test -x proyecto-compose/wordpress/entrypoint.sh \
  && echo "Wrapper ejecutable y con sintaxis válida"
sudo docker compose -f proyecto-compose/compose.yaml exec -T wordpress \
  sh -c 'test -r /run/secrets/db_password && echo "Secreto legible dentro del contenedor"'
```

La última comprobación sólo prueba permisos y muestra un mensaje fijo; no muestra la contraseña. Tampoco incluyas variables de entorno sensibles en logs o evidencias.

## 11.6 Entender la secuencia y verificar recursos

### Comandos que automatizó el preparador

El preparador ya ejecutó el equivalente de esta secuencia; **no necesitas repetirla** si terminó con `Stack preparado`. Se presenta para que puedas operar y diagnosticar sin tratar el script como una caja negra:

```bash
sudo docker compose -f proyecto-compose/compose.yaml pull db
sudo docker compose -f proyecto-compose/compose.yaml pull wordpress
sudo docker compose -f proyecto-compose/compose.yaml pull proxy
```

Las descargas secuenciales facilitan identificar un fallo y reducen picos de actividad.

El arranque conceptual también es secuencial:

```bash
sudo docker compose -f proyecto-compose/compose.yaml up -d --wait db
sudo docker compose -f proyecto-compose/compose.yaml up -d --wait wordpress
sudo docker compose -f proyecto-compose/compose.yaml up -d --wait proxy
```

- `up`: crea o actualiza los recursos declarados.
- `-d`: deja los contenedores en segundo plano.
- `--wait`: espera hasta que los servicios estén `running` o `healthy`.

El script implementa esperas explícitas equivalentes para poder dar mensajes concretos por servicio. En `t3.micro`, el orden limita picos y localiza mejor un fallo.

Comprueba el disco después de las descargas:

```bash
sudo docker system df
df -h /
```

No ejecutes `docker system prune`: puede borrar recursos que no pertenecen a esta práctica. Si el preparador falla, no lo repitas a ciegas: revisa `ps` y `logs` usando el comando que su mensaje propone.

### Estado esperado

```bash
sudo docker compose -f proyecto-compose/compose.yaml ps
sudo docker stats --no-stream
```

Salida representativa abreviada:

```text
NAME         SERVICE     STATUS                   PORTS
...-db-1    db          Up ... (healthy)
...-wordpress-1 wordpress Up ... (healthy)
...-proxy-1 proxy       Up ... (healthy)          127.0.0.1:8080->80/tcp
```

Los nombres incorporan el nombre del proyecto y pueden variar. Revisa:

- ningún contenedor aparece como `unhealthy`, `exited` o `restarting`;
- sólo `proxy` publica un puerto;
- el destino del host es exactamente `127.0.0.1:8080`;
- en `t3.micro` quedan al menos 100 MiB disponibles según `free -m`.

```bash
free -m
df -h /
```

Si no se cumple el margen, detén el stack y pide ayuda; no añadas otro servicio.

## 11.7 Redes, nombres y puertos

Compose proporciona resolución DNS interna por nombre de servicio.

```bash
sudo docker compose -f proyecto-compose/compose.yaml exec -T proxy \
  getent hosts wordpress
sudo docker compose -f proyecto-compose/compose.yaml exec -T wordpress \
  getent hosts db
```

- `exec`: ejecuta dentro de un contenedor existente.
- `-T`: no reserva una terminal interactiva; es apropiado para scripts.
- `wordpress` y `db`: nombres DNS internos, no direcciones que debas fijar.

Comprueba las publicaciones:

```bash
sudo docker compose -f proyecto-compose/compose.yaml port proxy 80
if sudo docker compose -f proyecto-compose/compose.yaml port db 3306; then
  echo "FALLO: db publicó el puerto 3306"
else
  echo "OK: db no publicó el puerto 3306"
fi
sudo ss -lnt '( sport = :8080 )'
```

Salida esperada:

```text
127.0.0.1:8080
State  Recv-Q Send-Q Local Address:Port ...
LISTEN ...             127.0.0.1:8080 ...
```

Compose puede imprimir `no port 3306/tcp...`; es el fallo esperado de la consulta y confirma que `db` no publicó ese puerto. No uses `ss` para atribuir el puerto 3306 a Compose: el host podría tener otra base de datos nativa. `127.0.0.1` significa que ni siquiera una regla permisiva del Security Group expone directamente la aplicación web por ese socket.

## 11.8 Comprobar HTTP y abrir un túnel SSH

### Desde la EC2

```bash
curl --silent --show-error --output /dev/null \
  --write-out 'HTTP %{http_code}\n' \
  http://127.0.0.1:8080/
```

Una instalación nueva de WordPress suele responder `HTTP 200` o redirigir con `HTTP 301/302`. Un `502` indica que Nginx no puede comunicarse con WordPress.

### Desde tu computadora

El túnel se abre en **otra terminal de tu computadora**, no dentro de EC2.

Sintaxis parametrizada:

```bash
ssh -i <ruta_clave.pem> -L <puerto_local>:127.0.0.1:8080 ubuntu@<ipv4_ec2>
```

| Marcador | Ejemplo | Propósito |
|---|---|---|
| `<ruta_clave.pem>` | `~/.ssh/consultor-linux.pem` | Clave privada de la instancia |
| `<puerto_local>` | `8080` | Puerto que abrirá tu computadora |
| `<ipv4_ec2>` | IPv4 actual de la consola | Destino SSH; cambia después de detener/iniciar |

Ejemplo para copiar después de sustituir `IP_ACTUAL`:

```bash
CLAVE="$HOME/.ssh/consultor-linux.pem"
IP_EC2="IP_ACTUAL"
chmod 600 "$CLAVE"
ssh -i "$CLAVE" -L 8080:127.0.0.1:8080 "ubuntu@$IP_EC2"
```

Mantén esa sesión abierta y visita `http://127.0.0.1:8080` en el navegador local. El túnel viaja por el único puerto público permitido: SSH.

## 11.9 Volúmenes, persistencia y logs

Lista los volúmenes del proyecto:

```bash
sudo docker compose -f proyecto-compose/compose.yaml config --volumes
sudo docker volume ls \
  --filter label=com.docker.compose.project=consultor-linux
```

Detener e iniciar no debe borrar datos:

```bash
sudo docker compose -f proyecto-compose/compose.yaml stop
sudo docker compose -f proyecto-compose/compose.yaml start
sudo docker compose -f proyecto-compose/compose.yaml ps
```

Inspecciona logs sin inundar la terminal:

```bash
sudo docker compose -f proyecto-compose/compose.yaml logs \
  --tail 30 --timestamps proxy wordpress db
```

- `--tail 30`: limita cada servicio a las últimas 30 líneas.
- `--timestamps`: ayuda a correlacionar eventos.

El archivo Compose limita el controlador de logs a 10 MiB por archivo y tres archivos. Comprueba la configuración efectiva de un contenedor:

```bash
PROXY_ID="$(sudo docker compose -f proyecto-compose/compose.yaml ps -q proxy)"
sudo docker inspect --format \
  '{{json .HostConfig.LogConfig}}' "$PROXY_ID"
```

La salida debe incluir `max-size` con `10m` y `max-file` con `3`.

## 11.10 Fallo controlado: la base de datos deja de responder

Detén únicamente `db`:

```bash
sudo docker compose -f proyecto-compose/compose.yaml stop db
sudo docker compose -f proyecto-compose/compose.yaml ps
curl --max-time 5 --silent --show-error \
  http://127.0.0.1:8080/ > /dev/null || true
```

Diagnostica desde afuera hacia adentro:

```bash
sudo docker compose -f proyecto-compose/compose.yaml logs --tail 20 proxy
sudo docker compose -f proyecto-compose/compose.yaml logs --tail 30 wordpress
sudo docker compose -f proyecto-compose/compose.yaml ps db
```

No borres volúmenes ni recrees todo el servidor. La evidencia ya muestra que `db` está detenido.

Recuperación:

```bash
sudo docker compose -f proyecto-compose/compose.yaml start db
sudo docker compose -f proyecto-compose/compose.yaml up -d --wait db
sudo docker compose -f proyecto-compose/compose.yaml restart wordpress
sudo docker compose -f proyecto-compose/compose.yaml up -d --wait proxy
curl --silent --show-error --output /dev/null \
  --write-out 'HTTP %{http_code}\n' \
  http://127.0.0.1:8080/
```

La base se detuvo de forma ordenada, por lo que sus datos deben seguir en el volumen.

## 11.11 Práctica resuelta: ficha técnica del despliegue

Crea una evidencia que no revele secretos:

```bash
mkdir -p /srv/consultor-linux/evidencias

{
  echo '# Ficha técnica de Compose'
  date --iso-8601=seconds
  echo
  echo '## Servicios'
  sudo docker compose -f proyecto-compose/compose.yaml config --services
  echo
  echo '## Estado'
  sudo docker compose -f proyecto-compose/compose.yaml ps
  echo
  echo '## Puerto publicado'
  sudo docker compose -f proyecto-compose/compose.yaml port proxy 80
  echo
  echo '## Recursos'
  free -h
  df -h /
  echo
  echo '## Respuesta'
  curl --silent --show-error --output /dev/null \
    --write-out 'HTTP %{http_code}\n' \
    http://127.0.0.1:8080/
} | tee /srv/consultor-linux/evidencias/compose.txt
```

Comprueba la evidencia:

```bash
test -s /srv/consultor-linux/evidencias/compose.txt \
  && echo "Evidencia creada"
grep -E '127\.0\.0\.1:8080|HTTP [123][0-9][0-9]' \
  /srv/consultor-linux/evidencias/compose.txt
```

No incluyas `docker compose config` completo en la evidencia: según cómo esté escrito un proyecto, una expansión indiscriminada podría mostrar variables sensibles.

## 11.12 Errores frecuentes

- **Usar `docker-compose`.** Compose v2 se invoca como `docker compose`.
- **Agregar usuarios al grupo `docker` sin entender el alcance.** Equivale prácticamente a conceder administración del host.
- **Publicar `3306:3306`.** WordPress alcanza `db` por la red interna.
- **Publicar `8080:80` sin dirección.** Eso escucha en todas las interfaces; el curso exige `127.0.0.1:8080:80`.
- **Usar direcciones IP de contenedor.** Cambian; utiliza nombres de servicio.
- **Creer que un contenedor conserva datos por sí mismo.** La persistencia vive en volúmenes.
- **Ejecutar `down --volumes` como “reinicio”.** Ese comando elimina los datos persistentes.
- **Usar `latest`.** Hace que dos ejecuciones puedan usar software distinto.
- **Construir imágenes en `t3.micro`.** Aumenta picos de CPU, memoria y disco sin aportar valor al objetivo.

## 11.13 Reto: demostrar aislamiento y persistencia

Sin mostrar contraseñas, crea `/srv/consultor-linux/evidencias/aislamiento-contenedores.txt` con evidencia de que:

1. existen exactamente los servicios `proxy`, `wordpress` y `db`;
2. sólo `proxy` tiene un puerto publicado;
3. dicho puerto está ligado a `127.0.0.1:8080`;
4. `wordpress` resuelve el nombre `db`;
5. los tres servicios están sanos después de un `stop` y `start`;
6. la respuesta HTTP sigue siendo válida.

### Pistas

- Usa `config --services`, `port`, `exec -T`, `ps` y `curl`.
- `docker compose port db 3306` debe fallar o no imprimir nada; documenta ese resultado sin detener el guion.
- No uses `docker inspect` sobre secretos ni `cat proyecto-compose/secrets/*`.

### Criterios de éxito

- La evidencia contiene una sección por requisito.
- No aparece ninguna contraseña ni el contenido de un secreto.
- `db` no publica `3306` al host.
- `proxy` publica exactamente `127.0.0.1:8080`.
- Los datos y servicios sobreviven a detener e iniciar el proyecto.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-11)

## Cierre seguro de la práctica

Si continuarás inmediatamente con seguridad y el proyecto final, deja el stack activo. Si terminarás por hoy, detén los contenedores sin borrar volúmenes:

```bash
sudo docker compose -f proyecto-compose/compose.yaml stop
sudo shutdown -h +360
```

`+360` significa dentro de 360 minutos, es decir, seis horas. Es una protección; al terminar la clase detén la instancia desde AWS y confirma que llega a `Stopped`. Para cancelar un apagado programado:

```bash
sudo shutdown -c
```

## Resumen y checklist

- [ ] Distingo VM, imagen, contenedor y volumen.
- [ ] Instalé Docker y Compose v2 desde un solo canal.
- [ ] Entiendo por qué el grupo `docker` es privilegiado.
- [ ] Validé Compose antes de crear recursos.
- [ ] Generé secretos locales ignorados por Git.
- [ ] Arranqué `db`, `wordpress` y `proxy` de manera controlada.
- [ ] Verifiqué health checks, memoria y disco.
- [ ] Confirmé que sólo loopback publica el puerto 8080.
- [ ] Probé el acceso mediante túnel SSH.
- [ ] No ejecuté `docker system prune` ni borré los volúmenes.
