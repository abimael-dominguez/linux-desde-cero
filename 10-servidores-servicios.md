# 10. Servidores, servicios y paquetes

## Objetivos

Al terminar este capítulo podrás:

- distinguir un paquete, un proceso, un servicio y una aplicación compuesta;
- consultar, instalar, verificar y retirar software con APT;
- reconocer los flujos equivalentes de DNF y Snap sin mezclarlos;
- comprobar un servicio con `systemctl`, `ss`, `curl` y `journalctl`;
- explicar el papel de Nginx, Apache, WordPress y MariaDB;
- decidir qué servicios **no** conviene publicar en una EC2 de laboratorio.

## Antes de empezar

Este capítulo se ejecuta como el usuario administrador inicial de Ubuntu, normalmente `ubuntu`. No necesitas abrir los puertos 80, 443, 3306, 53, 67 ni 25 en el Security Group. Todas las comprobaciones se harán desde la propia EC2.

Comprueba el contexto:

```bash
whoami
cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION_ID)='
free -h
df -h /
```

Salida representativa:

```text
ubuntu
PRETTY_NAME="Ubuntu 24.04.x LTS"
VERSION_ID="24.04"
               total        used        free      shared  buff/cache   available
Mem:           1.0Gi       ...
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        19G  ...   ...    ...  /
```

Los valores de memoria y disco cambiarán. Antes de instalar algo, confirma que `/` tiene al menos 2 GiB disponibles.

## 10.1 Modelo mental: del paquete al servicio

```text
repositorio → paquete → archivos instalados → proceso → puerto o socket → cliente
   APT         nginx      /usr/sbin/nginx      nginx       127.0.0.1:80     curl
```

| Concepto | Qué representa | Cómo observarlo |
|---|---|---|
| Paquete | Unidad que instala archivos y dependencias | `apt show nginx` |
| Proceso | Programa que se está ejecutando | `pgrep -a nginx` |
| Servicio | Proceso administrado, normalmente por systemd | `systemctl status nginx` |
| Puerto | Punto de entrada de red de un proceso | `ss -lntp` |
| Log | Evidencia de eventos y errores | `journalctl -u nginx` |
| Aplicación compuesta | Varios servicios que colaboran | Nginx + WordPress + MariaDB |

Instalar un paquete no demuestra que el servicio esté sano. Una comprobación profesional recorre toda la cadena:

```text
unidad activa → proceso vivo → puerto escuchando → petición válida → log coherente
```

## 10.2 Administración de paquetes con APT

APT es la interfaz habitual de alto nivel en Ubuntu y Debian. `dpkg` mantiene la base local de paquetes; APT, además, consulta repositorios y resuelve dependencias.

### Sintaxis parametrizada

```bash
apt search <texto>
apt show <paquete>
sudo apt update
sudo apt install <paquete>
sudo apt remove <paquete>
```

| Parámetro | Valor de este capítulo | Significado |
|---|---|---|
| `<texto>` | `nginx` | Texto que se buscará en nombres y descripciones |
| `<paquete>` | `nginx` | Nombre exacto que administrará APT |

Los marcadores `<...>` se sustituyen; no se escriben literalmente.

### Consultar antes de instalar

```bash
apt search '^nginx$'
apt show nginx
apt-cache policy nginx
```

- `search`: busca paquetes. El patrón `^nginx$` pide el nombre exacto.
- `show`: presenta descripción, dependencias y tamaño.
- `policy`: muestra la versión instalada y la versión candidata.
- Estos tres comandos son de consulta; no cambian el sistema.

Salida representativa de `apt-cache policy nginx` antes de instalar:

```text
nginx:
  Installed: (none)
  Candidate: 1.24.0-...
```

La versión exacta depende de las actualizaciones de Ubuntu 24.04. No copies una versión esperada: verifica la candidata de tu repositorio.

### Actualizar el índice e instalar

```bash
sudo apt update
apt install --simulate nginx
sudo apt install --yes nginx
```

- `apt update` descarga el **índice** disponible; no actualiza por sí solo todos los programas.
- `--simulate` muestra el plan sin instalar; revisa paquetes, espacio y acciones.
- `install` instala el paquete y sus dependencias.
- `--yes` acepta la confirmación. Úsalo sólo después de leer el resumen de cambios.
- `sudo` eleva exclusivamente el comando que lo necesita.

Comprueba qué se instaló:

```bash
dpkg-query -W -f='${Status} ${Version}\n' nginx
systemctl is-enabled nginx
systemctl is-active nginx
```

Salida representativa:

```text
install ok installed 1.24.0-...
enabled
active
```

`enabled` significa que la unidad está configurada para iniciar con el sistema; `active` describe su estado actual. Son preguntas diferentes.

### Actualizaciones: observar antes de aplicar

```bash
apt list --upgradable
```

En clase no ejecutes una actualización completa justo antes de una práctica importante. En producción se actualiza con respaldo, ventana, pruebas y plan de reversión. La instalación limpia de EC2 sí debe recibir parches durante su preparación.

### Reversión opcional

Conservaremos Nginx para la práctica resuelta. Cuando hayas terminado el capítulo, puedes retirar sólo el paquete:

```bash
sudo systemctl disable --now nginx
sudo apt remove nginx
sudo apt autoremove --dry-run
```

`autoremove --dry-run` **simula** qué dependencias quedarían sin uso. Lee la lista antes de ejecutar el comando sin `--dry-run`. No uses `purge` si aún necesitas conservar configuraciones para investigar.

## 10.3 DNF y Snap: mismo objetivo, distinto modelo

No intentes ejecutar los siguientes comandos de DNF en Ubuntu. Se muestran para que puedas trasladar el flujo a Fedora, Red Hat Enterprise Linux o distribuciones compatibles.

| Intención | Ubuntu/Debian | Fedora/RHEL |
|---|---|---|
| Buscar | `apt search nginx` | `dnf search nginx` |
| Ver información | `apt show nginx` | `dnf info nginx` |
| Instalar | `sudo apt install nginx` | `sudo dnf install nginx` |
| Actualizar metadatos | `sudo apt update` | `sudo dnf makecache` |
| Retirar | `sudo apt remove nginx` | `sudo dnf remove nginx` |

En sistemas actuales de la familia RHEL, `dnf` es la herramienta principal; `yum` puede existir como nombre compatible. Verifica siempre la distribución antes de copiar instrucciones:

```bash
. /etc/os-release
printf 'Distribución: %s %s\n' "$ID" "$VERSION_ID"
command -v apt || true
command -v dnf || true
```

Snap distribuye aplicaciones autocontenidas y actualizables de forma independiente:

```bash
snap version
snap list
snap info <nombre>
```

Ejemplo consultable en Ubuntu:

```bash
snap info core24
```

En este curso no instalaremos el stack web mediante Snap: mezclar APT, Snap y contenedores para una misma aplicación complica rutas, actualizaciones y diagnóstico.

## 10.4 Operar un servicio con systemd

### Comandos y significado

```bash
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx
systemctl status nginx --no-pager
```

| Acción | Resultado |
|---|---|
| `start` | Inicia un servicio detenido |
| `stop` | Detiene el servicio |
| `restart` | Detiene e inicia; puede interrumpir conexiones |
| `reload` | Pide releer la configuración sin un reinicio completo |
| `status` | Muestra estado, PID y eventos recientes |
| `--no-pager` | Imprime sin abrir el visor interactivo |

No todos los servicios implementan `reload`. Consulta `systemctl reload nginx` sólo después de validar la configuración.

### Validar antes de recargar

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Salida esperada de la validación:

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

La regla operativa es:

```text
editar → validar → recargar → comprobar → revisar logs
```

## 10.5 Apache, Nginx, WordPress y la base de datos

El proyecto final usará esta composición:

```text
navegador
    │ túnel SSH hacia 127.0.0.1:8080
    ▼
Nginx (proxy inverso)
    │ HTTP, red interna de Docker
    ▼
WordPress + Apache + PHP
    │ protocolo de MariaDB, red interna
    ▼
MariaDB + volumen persistente
```

| Componente | Responsabilidad | Lo que no debe hacer |
|---|---|---|
| Nginx | Recibir HTTP y reenviar peticiones | Guardar los datos de WordPress |
| Apache/PHP | Ejecutar WordPress | Exponer MariaDB a Internet |
| WordPress | Lógica y contenido del sitio | Administrar el host Linux |
| MariaDB | Persistir datos estructurados | Publicar el puerto 3306 |

Apache y Nginx no son “mejor” o “peor” de forma absoluta. En el proyecto, la imagen de WordPress ya contiene Apache/PHP y Nginx sirve como entrada única. Así cada componente tiene una responsabilidad clara.

Los artefactos del proyecto estarán en:

```text
proyecto-compose/
├── compose.yaml
├── nginx/default.conf
└── secrets/                 # generado localmente; no se versiona
```

Todavía no levantes el stack. En el capítulo 11 revisarás primero la configuración y los límites de recursos.

## 10.6 Servicios de infraestructura: qué practicar y qué sólo contextualizar

### DNS

DNS traduce nombres a registros. Consultar DNS no equivale a operar un servidor DNS autoritativo.

```bash
getent ahosts example.com
resolvectl query example.com
```

Si `dig` está instalado:

```bash
dig +short A example.com
dig +short MX example.com
```

- `A`: dirección IPv4.
- `MX`: servidores que reciben correo para el dominio.
- `+short`: reduce la salida a la respuesta.

El laboratorio opcional de BIND debe escuchar únicamente en loopback y en un puerto alto. Nunca abras el puerto 53 público para una demostración.

Para practicar sin iniciar un servidor, sigue el [anexo de validación DNS con BIND](extras/dns-bind.md). Allí `named-checkzone` comprueba la zona ficticia `curso.test` y termina.

### DHCP

DHCP entrega configuración de red a los clientes. En una VPC de AWS esa función la proporciona la infraestructura de AWS. Un DHCP iniciado por un alumno podría interferir con una red local; por ello sólo se estudia y valida una configuración de Kea sin arrancar el servicio.

Ejemplo de validación, únicamente si el anexo y el paquete están instalados:

```bash
sudo kea-dhcp4 -t <ruta_configuracion>
```

`-t` prueba la sintaxis y termina. `<ruta_configuracion>` debe sustituirse por la ruta del archivo del anexo; no copies el marcador literalmente.

El [anexo de DHCP con Kea](extras/dhcp-kea.md) proporciona el ejemplo copiable y una red reservada para documentación. No inicia el servidor.

### Correo

Un sistema de correo real requiere DNS directo e inverso, SPF, DKIM, DMARC, reputación y monitoreo. No se desplegará un servidor SMTP público desde la EC2 del curso. Sí debes reconocer los roles:

```text
cliente → MSA/MTA → DNS MX → MTA receptor → buzón
```

El [anexo de correo](extras/correo-linux.md) amplía los roles y propone consultar registros MX sin enviar mensajes.

### FTP

FTP transmite credenciales y datos sin protección en su forma clásica y requiere múltiples conexiones. Para transferencias administrativas utilizaremos SFTP o SCP sobre SSH.

## 10.7 Práctica resuelta: comprobar Nginx de extremo a extremo

### Propósito

Demostrar que el paquete, la unidad, el proceso, el puerto y la respuesta HTTP coinciden. La prueba se realiza dentro de EC2, sin abrir el puerto 80 en AWS.

### Paso 1. Validar la configuración y arrancar

```bash
sudo nginx -t
sudo systemctl enable --now nginx
```

- `enable`: configura el inicio futuro.
- `--now`: además aplica el arranque en este momento.

### Paso 2. Comprobar unidad y procesos

```bash
systemctl is-active nginx
pgrep -a nginx
```

Salida representativa:

```text
active
1234 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
1235 nginx: worker process
```

Los PID serán diferentes.

### Paso 3. Comprobar el puerto local

```bash
sudo ss -lntp '( sport = :80 )'
```

- `-l`: sólo sockets en escucha.
- `-n`: no traduce números a nombres.
- `-t`: TCP.
- `-p`: incluye el proceso; requiere privilegios para todos los detalles.
- `sport = :80`: filtra por puerto de origen local 80.

La salida debe contener `LISTEN` y `nginx`. Esto no implica que el puerto esté abierto en el Security Group.

### Paso 4. Hacer una petición

```bash
curl --fail --silent --show-error --head http://127.0.0.1/
```

Salida representativa:

```text
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Content-Type: text/html
```

- `--head`: solicita únicamente encabezados.
- `--fail`: devuelve un estado distinto de cero ante errores HTTP 400 o superiores.
- `--silent`: oculta la barra de progreso.
- `--show-error`: conserva el mensaje si falla.

Comprueba el estado del último comando:

```bash
printf 'Estado de curl: %s\n' "$?"
```

`0` indica éxito.

### Paso 5. Revisar evidencia

```bash
sudo journalctl -u nginx --since '-10 minutes' --no-pager
sudo tail -n 5 /var/log/nginx/access.log
```

El `access.log` debe incluir una petición `HEAD /` con estado `200`.

### Paso 6. Detener para ahorrar memoria antes de Docker

```bash
sudo systemctl disable --now nginx
systemctl is-active nginx || true
```

Salida esperada final:

```text
inactive
```

El paquete permanece instalado como referencia, pero el proceso ya no consume memoria ni ocupa el puerto 80.

## 10.8 Fallo controlado: distinguir “paquete instalado” de “servicio disponible”

Con Nginx detenido, ejecuta:

```bash
dpkg-query -W -f='${Status}\n' nginx
systemctl is-active nginx || true
curl --connect-timeout 2 http://127.0.0.1/ || true
```

Interpretación:

- APT informa `install ok installed`: los archivos existen.
- systemd informa `inactive`: no hay servicio activo.
- `curl` muestra que no puede conectarse: no existe una ruta funcional.

Recuperación y verificación:

```bash
sudo systemctl start nginx
curl --fail --silent http://127.0.0.1/ > /dev/null
echo "Nginx recuperado"
sudo systemctl stop nginx
```

No ocultes errores con `|| true` en automatizaciones reales. Aquí se usa sólo porque el fallo es intencional y queremos continuar la práctica.

## 10.9 Errores frecuentes

- **Abrir el puerto 80 “para que funcione `curl`”.** `curl 127.0.0.1` es local y no necesita reglas de AWS.
- **Confundir `enable` con `start`.** Uno configura el próximo arranque; el otro cambia el estado actual.
- **Recargar una configuración inválida.** Ejecuta primero `nginx -t`.
- **Instalar Apache y Nginx nativos a la vez.** Ambos intentarán usar el puerto 80 si no cambias la configuración.
- **Publicar MariaDB en `0.0.0.0:3306`.** La aplicación hablará con ella por una red interna de Docker.
- **Usar `yum` por costumbre en Ubuntu.** Identifica primero la familia de distribución.
- **Creer que un presupuesto de AWS detiene la instancia.** Un presupuesto alerta; no sustituye el apagado y la revisión de recursos.

## 10.10 Reto: expediente operativo de un servicio

Sin copiar la práctica línea por línea, crea un expediente de Nginx en `/srv/consultor-linux/evidencias/servicio-nginx.txt` que contenga:

1. versión instalada del paquete;
2. estado de la unidad;
3. proceso principal;
4. socket TCP en escucha;
5. código HTTP recibido desde loopback;
6. las últimas cinco líneas del log de acceso.

No abras puertos en AWS y no dejes Nginx activo al terminar.

### Pistas

- `dpkg-query` permite definir el formato de salida.
- Agrupa comandos con `{ ...; }` para redirigir una sola vez.
- Algunos comandos necesitan `sudo` para mostrar proceso o logs.
- Usa `tee` si quieres ver y guardar al mismo tiempo.

### Criterios de éxito

- El archivo existe y tiene contenido legible.
- Cada sección tiene un título.
- La comprobación HTTP muestra un estado exitoso.
- `systemctl is-active nginx` informa `inactive` al finalizar.
- El Security Group conserva únicamente SSH desde la IP del alumno.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-10)

## Resumen y checklist

- [ ] Distingo paquete, proceso, servicio, puerto y aplicación compuesta.
- [ ] Consulté antes de instalar con APT.
- [ ] Validé Nginx antes de recargarlo.
- [ ] Comprobé servicio, proceso, socket, HTTP y logs.
- [ ] Puedo traducir el flujo básico de APT a DNF.
- [ ] Entiendo cuándo Snap añade otro modelo de distribución.
- [ ] Sé por qué DNS, DHCP, correo y FTP no se publican en este laboratorio.
- [ ] Dejé Nginx nativo detenido antes de continuar con Docker.
