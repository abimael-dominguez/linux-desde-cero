# 6. Redes y conectividad

## Objetivos

Al terminar este capítulo podrás:

- diagnosticar conectividad por capas: interfaz, IP, ruta, DNS, puerto y aplicación;
- interpretar direcciones, rutas y sockets con `ip` y `ss`;
- consultar DNS con el resolvedor del sistema y con `dig`;
- conectarte a EC2 y transferir evidencias mediante SSH y SCP;
- validar una configuración Netplan sin aplicarla ni arriesgar la sesión remota.

## Contexto, equipos y directorio inicial

En este módulo hay dos terminales. Identifica siempre en cuál estás:

| Terminal | Prompt aproximado | Para qué se usa |
|---|---|---|
| equipo local | `tu_usuario@tu_pc` | iniciar SSH y ejecutar SCP |
| EC2 Ubuntu | `ubuntu@ip-10-...` | diagnosticar la red del servidor |

Los comandos de diagnóstico se ejecutan **en EC2**, salvo que el texto diga
“en tu equipo local”. Prepara el laboratorio remoto:

```bash
LAB="$HOME/consultor-linux-lab/modulo-06"
mkdir -p "$LAB"
cd "$LAB"
printf 'Host=%s Usuario=%s Directorio=%s\n' "$(hostname)" "$USER" "$PWD"
```

No cambies la interfaz de red, la ruta por defecto ni la configuración activa
de Netplan durante una conexión SSH.

## Modelo mental: diagnosticar por capas

```text
aplicación (HTTP, SSH)       curl / ssh
             |
puerto y transporte          ss / TCP / UDP
             |
nombre                       resolvectl / dig
             |
ruta y gateway               ip route
             |
interfaz y dirección         ip address
             |
red AWS: ENI, subred, SG y rutas de la VPC
```

Investiga de abajo hacia arriba. Un `ping` exitoso no demuestra que una
aplicación funcione; uno fallido tampoco demuestra que el host esté apagado,
porque ICMP puede estar filtrado.

Conceptos indispensables:

- **IP** identifica una interfaz en una red; en EC2 verás normalmente una IP
  privada y AWS asociará temporalmente una IPv4 pública.
- **máscara/prefijo**, por ejemplo `/24`, delimita la red.
- **gateway** encamina tráfico a otras redes.
- **DNS** traduce nombres a registros; no transporta la aplicación.
- **puerto** identifica un servicio dentro de un host. SSH usa normalmente TCP 22.
- Un **Security Group** filtra tráfico en AWS; no aparece como un proceso local.

## Interfaces, direcciones y rutas con `ip`

### Sintaxis parametrizada

```text
ip -brief address show [dev <interfaz>]
ip route get <direccion_destino>
```

| Parámetro | Ejemplo | De dónde se obtiene |
|---|---|---|
| `<interfaz>` | `ens5` | primera columna de `ip -brief address` |
| `<direccion_destino>` | `1.1.1.1` | destino cuya ruta deseas consultar |

Ejemplo copiable:

```bash
ip -brief link
ip -brief address
ip route
ip route get 1.1.1.1
```

Salida representativa de EC2:

```text
lo               UNKNOWN        127.0.0.1/8 ::1/128
ens5             UP             10.0.1.25/24 ...
default via 10.0.1.1 dev ens5 proto dhcp src 10.0.1.25 metric 100
1.1.1.1 via 10.0.1.1 dev ens5 src 10.0.1.25 uid 1000
```

La interfaz y las IP cambian. `UP` indica estado administrativo, la línea
`default via` muestra el gateway y `src` la IP que el kernel elegiría como
origen. `ip route get` consulta una decisión; no envía paquetes al destino.

`ifconfig` y `route` pertenecen a `net-tools` y se conservan en sistemas
antiguos. Para operación actual se prefieren los subcomandos de `ip`.

## Puertos y conexiones con `ss`

### Sintaxis parametrizada

```bash
ss -lntp [sport = :<puerto>]
ss -tn state established
```

Ejemplo copiable en EC2:

```bash
ss -lnt
sudo ss -lntp 'sport = :22'
ss -tn state established
```

Flags:

- `-l`: sólo sockets en escucha;
- `-t`: TCP; `-u`: UDP;
- `-n`: no convierte puertos o IP en nombres;
- `-p`: proceso asociado; suele requerir `sudo` para todos los procesos.

Salida representativa:

```text
State  Recv-Q Send-Q Local Address:Port Peer Address:Port Process
LISTEN 0      4096         0.0.0.0:22        0.0.0.0:*   users:(("sshd",...))
```

`0.0.0.0:22` significa que el proceso escucha en todas las interfaces IPv4
locales. No significa que Internet pueda entrar: todavía intervienen el
Security Group, rutas, autenticación y configuración de SSH.

`netstat` es la referencia histórica; `ss` obtiene la información mediante
interfaces modernas del kernel y no requiere instalar `net-tools`.

## Comprobar conectividad y aplicación

Ubuntu mínimo puede requerir estas herramientas. Instálalas una sola vez:

```bash
sudo apt update
sudo apt install -y dnsutils iputils-ping iputils-tracepath traceroute curl openssh-client
```

Prueba por etapas:

```bash
ping -c 3 1.1.1.1
tracepath -m 5 1.1.1.1
traceroute -m 5 -w 2 1.1.1.1
curl --fail --silent --show-error --head --max-time 10 https://example.com/
```

- `ping -c 3`: envía tres solicitudes ICMP;
- `tracepath -m 5`: muestra hasta cinco saltos y no necesita privilegios;
- `traceroute -m 5 -w 2`: consulta como máximo cinco saltos y espera hasta dos
  segundos por respuesta; los `*` indican que ese salto no respondió, no que
  toda la red esté caída;
- `curl --head`: solicita cabeceras; `--fail` marca HTTP 4xx/5xx como error;
- `--max-time 10`: evita que una automatización espere indefinidamente.

Una respuesta HTTP comienza de forma similar a `HTTP/2 200` o `HTTP/1.1 200
OK`. Un proxy puede cambiar el protocolo o agregar cabeceras sin que sea un
fallo.

## DNS y DHCP

Consulta primero la configuración que usa el sistema y después un registro:

```bash
resolvectl status --no-pager | sed -n '1,35p'
resolvectl query example.com
getent ahostsv4 example.com
dig example.com A +short
dig example.com A +noall +answer
```

- `resolvectl` consulta a `systemd-resolved` y refleja la configuración por
  interfaz;
- `getent` usa la política completa de `/etc/nsswitch.conf`, que puede incluir
  `/etc/hosts` además de DNS;
- `dig` habla DNS y permite elegir tipo de registro;
- `A` solicita IPv4; `AAAA`, IPv6; `MX`, servidores de correo.

Las IP de `example.com` pueden cambiar. El criterio correcto es obtener al
menos una respuesta, no comparar contra una IP escrita en el manual.

En EC2, el DHCP de la VPC entrega IP, ruta y resolvedores. **No levantes un
servidor DHCP dentro de la VPC**: podría interferir con una red compartida. La
administración de un servidor DHCP se estudiará mediante configuración aislada,
no emitiendo ofertas.

## Netplan aislado: validar sin aplicar

Este ejercicio crea una raíz falsa dentro del laboratorio. La interfaz `lab0`
no existe y la configuración nunca se copia a `/etc/netplan`.

```bash
NETPLAN_ROOT="$LAB/netplan-root"
mkdir -p "$NETPLAN_ROOT/etc/netplan"

tee "$NETPLAN_ROOT/etc/netplan/50-laboratorio.yaml" > /dev/null <<'YAML'
network:
  version: 2
  renderer: networkd
  ethernets:
    lab0:
      match:
        name: "lab0"
      dhcp4: true
      optional: true
YAML

chmod 600 "$NETPLAN_ROOT/etc/netplan/50-laboratorio.yaml"
sudo netplan generate --root-dir "$NETPLAN_ROOT"
printf 'Estado de validación: %s\n' "$?"
```

`generate` analiza YAML y genera archivos bajo la raíz alternativa. Estado `0`
significa sintaxis aceptada; **no demuestra** que una interfaz real tenga ese
nombre. No ejecutes `netplan apply`, porque eso operaría sobre la red activa.

Para ver qué se generó:

```bash
find "$NETPLAN_ROOT" -type f -printf '%P\n' | sort
```

## SSH: acceso remoto con claves

Esta sección se ejecuta **en tu equipo local**, no dentro de EC2. Necesitas tres
valores creados al preparar AWS:

| Variable | Ejemplo documental | Valor real |
|---|---|---|
| `CLAVE` | `~/.ssh/consultor-linux.pem` | ruta del archivo `.pem` descargado |
| `USUARIO_REMOTO` | `ubuntu` | usuario predeterminado de la AMI Ubuntu |
| `IP_PUBLICA` | `203.0.113.10` | Public IPv4 actual mostrada por EC2 |

`203.0.113.10` está reservada para documentación: **debes sustituirla**.

Sintaxis parametrizada:

```text
ssh -i <ruta_clave> <usuario>@<ip_o_nombre>
scp -i <ruta_clave> <origen> <usuario>@<ip_o_nombre>:<destino>
```

Ejemplo preparado para copiar después de editar sólo `IP_PUBLICA`:

```bash
CLAVE="$HOME/.ssh/consultor-linux.pem"
USUARIO_REMOTO="ubuntu"
IP_PUBLICA="203.0.113.10"  # Sustituye por la IPv4 pública actual

test -r "$CLAVE" || { printf 'No puedo leer %s\n' "$CLAVE" >&2; exit 1; }
chmod 400 "$CLAVE"
ssh -o IdentitiesOnly=yes -i "$CLAVE" \
  "${USUARIO_REMOTO}@${IP_PUBLICA}"
```

- `-i`: identidad privada; nunca la subas al servidor ni al repositorio;
- `IdentitiesOnly=yes`: evita probar muchas claves del agente;
- la primera conexión muestra una huella: compárala con una fuente confiable;
- si la huella cambia posteriormente, investiga; no desactives la verificación.

La regla de entrada TCP/22 del Security Group debe permitir sólo la IP pública
actual de tu equipo con prefijo `/32`, nunca `0.0.0.0/0`.

### SCP en ambos sentidos

Mantén las variables anteriores en la terminal local. Primero crea una
evidencia local y una carpeta remota:

```bash
printf 'evidencia de red\n' > /tmp/red-evidencia.txt
ssh -i "$CLAVE" "${USUARIO_REMOTO}@${IP_PUBLICA}" \
  'mkdir -p "$HOME/consultor-linux-lab/modulo-06/transferencias"'

scp -i "$CLAVE" /tmp/red-evidencia.txt \
  "${USUARIO_REMOTO}@${IP_PUBLICA}:consultor-linux-lab/modulo-06/transferencias/"

scp -i "$CLAVE" \
  "${USUARIO_REMOTO}@${IP_PUBLICA}:consultor-linux-lab/modulo-06/transferencias/red-evidencia.txt" \
  /tmp/red-evidencia-recuperada.txt

sha256sum /tmp/red-evidencia.txt /tmp/red-evidencia-recuperada.txt
```

Los dos hashes deben coincidir. En `scp`, `-P` mayúscula cambia el puerto; `-p`
minúscula preserva tiempos y modos.

FTP y Telnet transmiten información sin la protección que esperamos hoy; se
conservan como contexto histórico. Para administrar y transferir se emplean
SSH, SCP o SFTP.

## Verificación y reversión

En EC2, comprueba que el laboratorio no modificó la red activa:

```bash
ip route get 1.1.1.1
test ! -e /etc/netplan/50-laboratorio.yaml \
  && printf 'OK: no se instaló Netplan de laboratorio\n'
```

Elimina sólo la configuración aislada si ya guardaste la evidencia:

```bash
if [[ "$LAB" == "$HOME/consultor-linux-lab/modulo-06" ]]; then
  sudo rm -rf -- "$LAB/netplan-root"
else
  printf 'Ruta inesperada; no se elimina: %s\n' "$LAB" >&2
fi
```

En tu equipo local puedes borrar las copias temporales:

```bash
rm -f -- /tmp/red-evidencia.txt /tmp/red-evidencia-recuperada.txt
```

No borres la clave privada: se necesitará en las siguientes sesiones.

## Práctica guiada resuelta: reporte por capas

Ejecuta en EC2. Cada bloque tiene etiqueta para que el reporte sea legible:

```bash
cd "$LAB"
{
  printf '=== IDENTIDAD ===\n'
  hostnamectl --static
  printf '\n=== INTERFACES ===\n'
  ip -brief address
  printf '\n=== RUTA ===\n'
  ip route
  ip route get 1.1.1.1
  printf '\n=== DNS ===\n'
  getent ahostsv4 example.com | head -n 2
  printf '\n=== ESCUCHAS TCP ===\n'
  ss -lnt
  printf '\n=== SSH ===\n'
  systemctl is-active ssh
} > reporte-red.txt 2> reporte-red.err

test -s reporte-red.txt && printf 'OK: reporte generado\n'
wc -l reporte-red.txt reporte-red.err
```

`reporte-red.txt` debe contener las seis secciones. `reporte-red.err` puede
tener cero líneas; se conserva para distinguir “no hubo errores” de “se
descartaron los errores”. Descárgalo desde tu equipo local:

```bash
scp -i "$CLAVE" \
  "${USUARIO_REMOTO}@${IP_PUBLICA}:consultor-linux-lab/modulo-06/reporte-red.txt" \
  "$HOME/Downloads/reporte-red.txt"
```

## Fallo controlado: puerto sin servicio

En EC2, el puerto TCP 9 local no debería tener un servicio. Provocaremos un
fallo rápido y lo explicaremos con `ss`:

```bash
if curl --fail --silent --show-error --connect-timeout 2 \
    http://127.0.0.1:9/ > "$LAB/puerto-9.out" 2> "$LAB/puerto-9.err"; then
  printf 'Había un servicio inesperado en el puerto 9\n'
else
  estado=$?
  printf 'Fallo esperado de curl; estado=%s\n' "$estado"
  cat "$LAB/puerto-9.err"
  ss -lnt 'sport = :9'
fi
```

“Connection refused” indica que llegamos al host, pero ningún proceso escucha
en ese puerto. Un timeout sugeriría filtrado o falta de ruta y requiere otra
investigación.

## Reto 6: diagnóstico y entrega remota

Genera en EC2 `$LAB/reto-06/diagnostico.txt` con interfaz, ruta elegida hacia
`1.1.1.1`, resolvedor, dos respuestas IPv4 de `example.com`, sockets TCP en
escucha y estado de SSH. Conserva `stderr` por separado. En tu equipo local,
descarga ambos archivos con SCP y demuestra su integridad comparando un hash
calculado en EC2 con uno local.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-6)

### Criterios de éxito

- el reporte sigue el orden interfaz → ruta → DNS → puerto → servicio;
- las IP variables se obtienen con comandos, no se escriben manualmente;
- el Security Group conserva SSH limitado a una IP `/32`;
- ambos hashes son iguales y la clave privada nunca se copia ni imprime;
- no se ejecutaron `netplan apply`, un servidor DHCP, FTP ni Telnet.

## Checklist

- [ ] Identifico en qué terminal debe ejecutarse cada comando.
- [ ] Diagnostico interfaz, ruta, DNS, puerto y aplicación en ese orden.
- [ ] Distingo escucha local de acceso permitido por AWS.
- [ ] Uso herramientas actuales (`ip`, `ss`) y reconozco las heredadas.
- [ ] Validé Netplan dentro de una raíz aislada.
- [ ] Uso SSH/SCP con clave y verificación de host.
