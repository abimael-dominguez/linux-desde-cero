# Soluciones de los retos

Documento exclusivo para el instructor. Son soluciones de referencia: una
alternativa también es válida si satisface los criterios, conserva las guardias
de seguridad y produce evidencia verificable.

Los bloques indican expresamente si se ejecutan en EC2 o en el equipo local.
No se incluyen contraseñas, secretos, IP reales ni claves privadas.

<a id="respuesta-reto-1"></a>
## Respuesta reto 1 — Ficha reproducible de la instancia

Ejecutar en EC2 como `ubuntu`:

```bash
EVIDENCIA=/srv/consultor-linux/evidencias/01/ficha-instancia.txt
sudo install -d -o ubuntu -g ubuntu -m 0750 "$(dirname "$EVIDENCIA")"

{
  printf 'usuario=%s\n' "$(whoami)"
  . /etc/os-release
  printf 'distribucion=%s\n' "$PRETTY_NAME"
  printf 'kernel=%s\n' "$(uname -r)"
  printf 'memoria_total=%s\n' "$(free -h | awk '/^Mem:/ {print $2}')"
  printf 'espacio_disponible_raiz=%s\n' \
    "$(df -h --output=avail / | awk 'NR == 2 {print $1}')"
  printf 'shell_actual=%s\n' "$(ps -p "$$" -o comm= | xargs)"
} | tee "$EVIDENCIA"
```

Verificación:

```bash
test -s "$EVIDENCIA"
test "$(grep -Ec \
  '^(usuario|distribucion|kernel|memoria_total|espacio_disponible_raiz|shell_actual)=' \
  "$EVIDENCIA")" -eq 6
stat -c 'modo=%a dueño=%U grupo=%G ruta=%n' "$EVIDENCIA"
```

Limpieza opcional, sólo para repetir el reto:

```bash
rm -i -- /srv/consultor-linux/evidencias/01/ficha-instancia.txt
```

<a id="respuesta-reto-2"></a>
## Respuesta reto 2 — Auditoría inicial de una EC2

Precondiciones: deben existir `deploy`, `ops` y el directorio de evidencias del
módulo 2. Ejecutar en EC2 como `ubuntu`:

```bash
EVIDENCIA=/srv/consultor-linux/evidencias/02/auditoria-inicial.txt
sudo install -d -o ubuntu -g ops -m 0750 "$(dirname "$EVIDENCIA")"

{
  . /etc/os-release
  printf 'distribucion=%s\n' "$PRETTY_NAME"
  printf 'virtualizacion=%s\n' "$(systemd-detect-virt 2>/dev/null || printf no-detectada)"
  printf '%s\n' '--- cloud-init ---'
  cloud-init status --long
  printf '%s\n' '--- sistema de archivos raiz ---'
  findmnt -no SOURCE,FSTYPE,OPTIONS,TARGET /
  printf '%s\n' '--- uso de disco ---'
  df -hT /
  printf '%s\n' '--- memoria ---'
  free -h
  printf '%s\n' '--- usuario deploy ---'
  getent passwd deploy
  id deploy

  if [[ $ID == ubuntu && $VERSION_ID == 24.04 ]] \
    && id -nG deploy | tr ' ' '\n' | grep -qxF ops; then
    printf 'resultado=APROBADA\n'
  else
    printf 'resultado=REVISAR\n'
  fi
} > "$EVIDENCIA"

sudo chown ubuntu:ops "$EVIDENCIA"
sudo chmod 0640 "$EVIDENCIA"
```

Verificación:

```bash
grep -E 'Ubuntu 24\.04|deploy|ops|resultado=APROBADA' "$EVIDENCIA"
sudo -u deploy test -r "$EVIDENCIA"
sudo -u deploy test ! -w "$EVIDENCIA"
stat -c '%a %U:%G %n' "$EVIDENCIA"
```

El resultado correcto termina en `640 ubuntu:ops`. Limpieza opcional:

```bash
rm -i -- /srv/consultor-linux/evidencias/02/auditoria-inicial.txt
```

No se eliminan `deploy`, `ops` ni `/srv/consultor-linux`, porque los siguientes
módulos dependen de ellos.

<a id="respuesta-reto-3"></a>
## Respuesta reto 3 — Inventario de configuraciones

Ejecutar en EC2:

```bash
LAB=/srv/consultor-linux/laboratorios/03-archivos
RETO="$LAB/reto"
mkdir -p "$RETO"

printf 'NAME=api\nENABLED=true\nPORT=8080\n' > "$RETO/api.conf"
printf 'NAME=worker\nENABLED=false\nQUEUE=jobs\n' > "$RETO/worker.conf"
printf 'NAME=proxy\nENABLED=true\nUPSTREAM=api\n' > "$RETO/proxy.conf"

find "$RETO" -maxdepth 1 -type f -name '*.conf' -size +0c \
  -printf '%p\t%s bytes\n' \
  | sort > "$RETO/inventario.txt"

grep -nF 'ENABLED=true' "$RETO"/*.conf \
  > "$RETO/habilitadas.txt"

ln -sfn api.conf "$RETO/config-activa"
```

Verificación:

```bash
cat "$RETO/inventario.txt"
cat "$RETO/habilitadas.txt"
test "$(find "$RETO" -maxdepth 1 -type f -name '*.conf' -size +0c | wc -l)" -eq 3
test "$(grep -lF 'ENABLED=true' "$RETO"/*.conf | wc -l)" -eq 2
DESTINO=$(readlink -f "$RETO/config-activa")
test -f "$DESTINO" && printf 'Enlace resuelto: %s\n' "$DESTINO"
```

Limpieza de resultados, conservando los tres `.conf` originales:

```bash
rm -f -- \
  "$RETO/inventario.txt" \
  "$RETO/habilitadas.txt" \
  "$RETO/config-activa"
```

<a id="respuesta-reto-4"></a>
## Respuesta reto 4 — Área de operación con mínimo privilegio

Ejecutar como `ubuntu`:

```bash
BASE=/srv/consultor-linux/laboratorios/04-permisos
RETO="$BASE/reto"

sudo install -d -o ubuntu -g ops -m 0750 "$RETO"
sudo install -d -o ubuntu -g ops -m 0750 "$RETO/config"
sudo install -d -o ubuntu -g ops -m 2770 "$RETO/entregas"
sudo install -d -o ubuntu -g ubuntu -m 0700 "$RETO/secretos"

printf 'APP_ENV=production\nPORT=8080\n' \
  | sudo tee "$RETO/config/app.env" > /dev/null
sudo chown ubuntu:ops "$RETO/config/app.env"
sudo chmod 0640 "$RETO/config/app.env"

printf 'credencial=ficticia-para-laboratorio\n' \
  | sudo tee "$RETO/secretos/credencial.txt" > /dev/null
sudo chown ubuntu:ubuntu "$RETO/secretos/credencial.txt"
sudo chmod 0600 "$RETO/secretos/credencial.txt"

sudo -u deploy bash -c \
  'umask 0007; printf "entrega=OK\n" > \
  /srv/consultor-linux/laboratorios/04-permisos/reto/entregas/deploy.txt'
```

Verificación:

```bash
stat -c '%A %a %U:%G %n' \
  "$RETO/config" "$RETO/config/app.env" \
  "$RETO/entregas" "$RETO/entregas/deploy.txt" \
  "$RETO/secretos" "$RETO/secretos/credencial.txt"

sudo -u deploy test -r "$RETO/config/app.env"
sudo -u deploy test ! -w "$RETO/config/app.env"
test "$(stat -c %G "$RETO/entregas/deploy.txt")" = ops

estado=0
sudo -u deploy cat "$RETO/secretos/credencial.txt" \
  > /dev/null 2> "$RETO/acceso-secreto.err" || estado=$?
test "$estado" -ne 0
grep -F 'Permission denied' "$RETO/acceso-secreto.err"
```

Limpieza opcional después de evaluar, sin borrado recursivo:

```bash
sudo rm -f -- \
  "$RETO/acceso-secreto.err" \
  "$RETO/config/app.env" \
  "$RETO/entregas/deploy.txt" \
  "$RETO/secretos/credencial.txt"
sudo rmdir "$RETO/config" "$RETO/entregas" "$RETO/secretos" "$RETO"
```

<a id="respuesta-reto-5"></a>
## Respuesta reto 5 — Informe de operación observable

Ejecutar en EC2. El único proceso que recibirá señales es el `sleep` creado en
el mismo bloque:

```bash
LAB="$HOME/consultor-linux-lab/modulo-05"
RETO="$LAB/reto-05"
mkdir -p "$RETO"

sleep 240 &
pid=$!
printf '%s\n' "$pid" > "$RETO/proceso.pid"
ps -o pid,ppid,user,stat,ni,etime,comm -p "$pid" \
  > "$RETO/estado-inicial.txt"

kill -STOP "$pid"
ps -o pid,stat,comm -p "$pid" \
  > "$RETO/estado-detenido.txt"
printf 'STAT=%s\n' "$(ps -o stat= -p "$pid" | awk '{print substr($1, 1, 1)}')" \
  >> "$RETO/estado-detenido.txt"

kill -CONT "$pid"
kill -TERM "$pid"
wait "$pid" 2> "$RETO/wait.err" || true

if kill -0 "$pid" 2>/dev/null; then
  printf 'FALLO: PID %s sigue activo\n' "$pid" \
    | tee "$RETO/estado-final.txt"
else
  printf 'OK: PID %s finalizado\n' "$pid" \
    | tee "$RETO/estado-final.txt"
fi

{
  printf '%s\n' '--- CPU ---'
  nproc
  printf '%s\n' '--- memoria ---'
  free -h
  printf '%s\n' '--- carga ---'
  uptime
  printf '%s\n' '--- SSH ---'
  systemctl is-active ssh
} > "$RETO/sistema.txt" 2> "$RETO/sistema.err"
```

Verificación:

```bash
grep -Eq '^[0-9]+$' "$RETO/proceso.pid"
awk 'NR == 2 && $2 ~ /T/ { encontrado=1 } END { exit !encontrado }' \
  "$RETO/estado-detenido.txt"
grep -qxF 'STAT=T' "$RETO/estado-detenido.txt"
grep -F 'OK:' "$RETO/estado-final.txt"
grep -E '^--- (CPU|memoria|carga|SSH) ---$' "$RETO/sistema.txt"
! kill -0 "$(<"$RETO/proceso.pid")" 2>/dev/null
```

Limpieza opcional:

```bash
pid=$(<"$RETO/proceso.pid")
if [[ $pid =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
  test "$(ps -p "$pid" -o comm= | xargs)" = sleep && kill -TERM "$pid"
fi
find "$RETO" -mindepth 1 -delete
rmdir "$RETO"
```

<a id="respuesta-reto-6"></a>
## Respuesta reto 6 — Diagnóstico y entrega remota

### En EC2

```bash
LAB="$HOME/consultor-linux-lab/modulo-06"
RETO="$LAB/reto-06"
mkdir -p "$RETO"

{
  printf '%s\n' '--- interfaz ---'
  ip -brief address
  printf '%s\n' '--- ruta a 1.1.1.1 ---'
  ip route get 1.1.1.1
  printf '%s\n' '--- resolvedor ---'
  resolvectl status --no-pager | sed -n '1,35p'
  printf '%s\n' '--- dos respuestas IPv4 ---'
  getent ahostsv4 example.com \
    | awk '!vistas[$1]++ {print; total++; if (total == 2) exit}'
  printf '%s\n' '--- sockets TCP en escucha ---'
  ss -lnt
  printf '%s\n' '--- SSH ---'
  systemctl is-active ssh
} > "$RETO/diagnostico.txt" 2> "$RETO/errores.log"

(
  cd "$RETO"
  sha256sum diagnostico.txt errores.log > SHA256SUMS
)

test -s "$RETO/diagnostico.txt"
(cd "$RETO" && sha256sum -c SHA256SUMS)
```

### En el equipo local

Sustituir la ruta de la clave y escribir la IPv4 pública actual cuando se
solicite. La IP no se guarda en este documento:

```bash
CLAVE="$HOME/.ssh/consultor-linux.pem"
USUARIO_REMOTO=ubuntu
read -r -p 'IPv4 pública actual de EC2: ' IP_PUBLICA
LOCAL="$HOME/entrega-consultor-linux/reto-06"

test -r "$CLAVE" || { printf 'Clave no legible\n' >&2; exit 1; }
chmod 600 "$CLAVE"
mkdir -p "$LOCAL"

scp -i "$CLAVE" \
  "${USUARIO_REMOTO}@${IP_PUBLICA}:consultor-linux-lab/modulo-06/reto-06/diagnostico.txt" \
  "${USUARIO_REMOTO}@${IP_PUBLICA}:consultor-linux-lab/modulo-06/reto-06/errores.log" \
  "${USUARIO_REMOTO}@${IP_PUBLICA}:consultor-linux-lab/modulo-06/reto-06/SHA256SUMS" \
  "$LOCAL/"

(cd "$LOCAL" && sha256sum -c SHA256SUMS)
```

Ambos archivos deben mostrar `OK`; así se compara localmente el hash que se
calculó en EC2. Limpieza remota opcional después de conservar la descarga:

```bash
LAB="$HOME/consultor-linux-lab/modulo-06"
RETO="$LAB/reto-06"
rm -f -- \
  "$RETO/diagnostico.txt" "$RETO/errores.log" "$RETO/SHA256SUMS"
rmdir "$RETO"
```

<a id="respuesta-reto-7"></a>
## Respuesta reto 7 — Pipeline de incidentes reutilizable

Ejecutar en EC2:

```bash
LAB="$HOME/consultor-linux-lab/modulo-07"
RETO="$LAB/reto-07"
ENTRADA="$LAB/servicio.log"
mkdir -p "$RETO"

HASH_ANTES=$(sha256sum "$ENTRADA" | awk '{print $1}')

(
  set -o pipefail
  grep -E 'WARN|ERROR' "$ENTRADA" 2> "$RETO/errores.log" \
    | tee "$RETO/incidentes.txt" \
    | awk '{print $3}' \
    | sort -u \
    > "$RETO/componentes.txt"
) && {
  printf 'WARN=%s\n' "$(grep -c ' WARN ' "$RETO/incidentes.txt")"
  printf 'ERROR=%s\n' "$(grep -c ' ERROR ' "$RETO/incidentes.txt")"
} > "$RETO/resumen.txt"

HASH_DESPUES=$(sha256sum "$ENTRADA" | awk '{print $1}')
test "$HASH_ANTES" = "$HASH_DESPUES"
```

Prueba negativa para confirmar que `pipefail` conserva el error:

```bash
estado=0
(
  set -o pipefail
  grep -E 'WARN|ERROR' "$LAB/no-existe.log" \
    2>> "$RETO/errores.log" \
    | tee "$RETO/fallo.txt" > /dev/null
) || estado=$?
test "$estado" -ne 0
```

Verificación:

```bash
test "$(wc -l < "$RETO/incidentes.txt")" -eq 3
diff -u <(printf '%s\n' api db disco) "$RETO/componentes.txt"
grep -qxF 'WARN=1' "$RETO/resumen.txt"
grep -qxF 'ERROR=2' "$RETO/resumen.txt"
grep -F 'no-existe.log' "$RETO/errores.log"
test "$(sha256sum "$ENTRADA" | awk '{print $1}')" = "$HASH_ANTES"
```

Limpieza de resultados; `servicio.log` no se toca:

```bash
find "$RETO" -mindepth 1 -delete
rmdir "$RETO"
```

<a id="respuesta-reto-8"></a>
## Respuesta reto 8 — Respaldo programable y recuperable

Crear el script dentro del laboratorio:

```bash
LAB="$HOME/consultor-linux-lab/modulo-08"
RETO="$LAB/reto-08"
mkdir -p "$RETO"/{respaldos,restaurado,logs}

tee "$RETO/respaldo-reto.sh" > /dev/null <<'BASH'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
  printf 'Uso: %s <origen> <destino>\n' "$0" >&2
  exit 64
fi

origen=$1
destino=$2
[[ -d $origen && -r $origen && -x $origen ]] || {
  printf 'Origen no accesible: %s\n' "$origen" >&2
  exit 66
}

origen_abs=$(realpath -- "$origen")
destino_abs=$(realpath -m -- "$destino")
case "$destino_abs/" in
  "$origen_abs/"*)
    printf 'El destino no puede estar dentro del origen\n' >&2
    exit 73
    ;;
esac
mkdir -p -- "$destino_abs"

exec {lock_fd}> "$destino_abs/.respaldo.lock"
flock -n "$lock_fd" || {
  printf 'Otra ejecución conserva el candado\n' >&2
  exit 75
}

marca=$(date -u +%Y%m%dT%H%M%SZ)
nombre="respaldo-$(basename -- "$origen_abs")-${marca}-$$.tar.gz"
temporal=$(mktemp --tmpdir="$destino_abs" ".${nombre}.XXXXXX")
limpiar() { rm -f -- "${temporal:-}"; }
trap limpiar EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

tar -czf "$temporal" \
  --directory="$(dirname -- "$origen_abs")" \
  -- "$(basename -- "$origen_abs")"
gzip -t "$temporal"
chmod 600 "$temporal"
mv -- "$temporal" "$destino_abs/$nombre"
temporal=''
(
  cd "$destino_abs"
  sha256sum "$nombre" > "$nombre.sha256"
)
printf '%s\n' "$destino_abs/$nombre"
BASH

chmod 750 "$RETO/respaldo-reto.sh"
bash -n "$RETO/respaldo-reto.sh"
if command -v shellcheck > /dev/null; then
  shellcheck "$RETO/respaldo-reto.sh"
fi
```

Ejecutar dos veces, verificar ambos respaldos y restaurar el primero:

```bash
A=$("$RETO/respaldo-reto.sh" "$LAB/origen" "$RETO/respaldos")
B=$("$RETO/respaldo-reto.sh" "$LAB/origen" "$RETO/respaldos")
test "$A" != "$B"

for archivo in "$A" "$B"; do
  (
    cd "$(dirname -- "$archivo")"
    sha256sum -c "$(basename -- "$archivo").sha256"
  )
done

tar -xzf "$A" -C "$RETO/restaurado"
diff -ru "$LAB/origen" "$RETO/restaurado/origen"
```

Preparar y validar cron sin instalarlo:

```bash
printf '30 2 * * * /usr/bin/flock -n "%s/cron-invocacion.lock" /usr/bin/bash "%s/respaldo-reto.sh" "%s/origen" "%s/respaldos" >> "%s/logs/cron.log" 2>&1\n' \
  "$RETO" "$RETO" "$LAB" "$RETO" "$RETO" \
  > "$RETO/crontab.reto"
crontab -n "$RETO/crontab.reto"
```

Prueba negativa y verificación de que no apareció otro respaldo:

```bash
antes=$(find "$RETO/respaldos" -maxdepth 1 -type f -name '*.tar.gz' | wc -l)
estado=0
"$RETO/respaldo-reto.sh" "$RETO/no-existe" "$RETO/respaldos" \
  > "$RETO/fallo.out" 2> "$RETO/fallo.err" || estado=$?
despues=$(find "$RETO/respaldos" -maxdepth 1 -type f -name '*.tar.gz' | wc -l)
test "$estado" -eq 66
test "$antes" -eq "$despues"
grep -F 'Origen no accesible' "$RETO/fallo.err"
```

Limpieza de temporales, conservando script, respaldos y candidato cron como
evidencia:

```bash
rm -rf -- "$RETO/restaurado/origen"
rm -f -- "$RETO/fallo.out" "$RETO/fallo.err" \
  "$RETO/cron-invocacion.lock"
```

<a id="respuesta-reto-9"></a>
## Respuesta reto 9 — Volumen desechable con recuperación

> Ejecutar sólo en la EC2 o VM desechable. Si una guardia falla, detenerse: no
> sustituir variables por un disco real ni continuar manualmente.

Preparación y guardias iniciales:

```bash
sudo apt update
sudo apt install -y lvm2 parted e2fsprogs

LAB="$HOME/consultor-linux-lab/modulo-09"
RETO="$LAB/reto-09"
IMG="$RETO/reto-storage.img"
MNT="$RETO/mnt"
EXPORTADO="$RETO/exportado"
RESTAURADO="$RETO/restaurado"
STATE="$RETO/loop-device"
VG="vg_reto_${UID}"
LV=lv_datos

ESPERADO=$(realpath -m -- "$HOME/consultor-linux-lab/modulo-09/reto-09/reto-storage.img")
[[ "$(realpath -m -- "$IMG")" == "$ESPERADO" ]] || {
  printf 'ABORTADO: ruta de imagen inesperada\n' >&2
  exit 1
}
[[ ! -e $IMG && ! -e $STATE ]] || {
  printf 'ABORTADO: existe un laboratorio anterior\n' >&2
  exit 1
}
if sudo vgs "$VG" > /dev/null 2>&1; then
  printf 'ABORTADO: ya existe %s\n' "$VG" >&2
  exit 1
fi

mkdir -p "$RETO" "$MNT" "$EXPORTADO" "$RESTAURADO"
truncate -s 384M "$IMG"
LOOP=$(sudo losetup --find --show --partscan --nooverlap "$IMG")
printf '%s\n' "$LOOP" > "$STATE"
```

La primera guardia valida **tipo loop** y **backing file**:

```bash
validar_loop_backing() {
  local loop=$1
  local imagen=$2
  local tipo backing

  [[ "$loop" =~ ^/dev/loop[0-9]+$ ]] || {
    printf 'No es /dev/loopN: %s\n' "$loop" >&2
    return 1
  }
  [[ -b $loop ]] || {
    printf 'No existe el bloque: %s\n' "$loop" >&2
    return 1
  }
  tipo=$(lsblk -dn -o TYPE "$loop" | xargs)
  [[ $tipo == loop ]] || {
    printf 'Tipo inesperado: %s\n' "$tipo" >&2
    return 1
  }
  backing=$(sudo losetup --list --noheadings --raw \
    --output BACK-FILE "$loop")
  [[ "$(readlink -f -- "$backing")" == "$(readlink -f -- "$imagen")" ]] || {
    printf 'El backing file no coincide\n' >&2
    return 1
  }
}

validar_loop_backing "$LOOP" "$IMG" || exit 1
printf 'OK loop=%s backing=%s\n' "$LOOP" "$IMG"
```

Particionar el loop y validar su **parent** antes de LVM:

```bash
validar_loop_backing "$LOOP" "$IMG" || exit 1
sudo parted --script "$LOOP" \
  mklabel gpt \
  mkpart primary 1MiB 100% \
  set 1 lvm on
sudo partprobe "$LOOP"
sudo udevadm settle

PART="${LOOP}p1"
for _ in {1..30}; do
  [[ -b $PART ]] && break
  sleep 0.1
done

validar_particion_parent() {
  local part=$1
  local loop=$2
  local parent

  [[ "$part" == "${loop}p1" && -b $part ]] || {
    printf 'Partición inesperada: %s\n' "$part" >&2
    return 1
  }
  parent=$(lsblk --noheadings --nodeps --output PKNAME "$part" | xargs)
  [[ $parent == "$(basename -- "$loop")" ]] || {
    printf 'Parent %s no coincide con %s\n' "$parent" "$loop" >&2
    return 1
  }
}

validar_loop_backing "$LOOP" "$IMG" || exit 1
validar_particion_parent "$PART" "$LOOP" || exit 1
lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINTS "$LOOP"
```

Crear LVM y ext4 sólo después de las tres comprobaciones:

```bash
validar_loop_backing "$LOOP" "$IMG" || exit 1
validar_particion_parent "$PART" "$LOOP" || exit 1

sudo pvcreate "$PART"
sudo vgcreate "$VG" "$PART"
sudo lvcreate --size 256M --name "$LV" "$VG"
LV_PATH="/dev/$VG/$LV"
sudo mkfs.ext4 -q -L RETO09 "$LV_PATH"
sudo mount "$LV_PATH" "$MNT"
sudo chown "$USER":"$(id -gn)" "$MNT"

printf 'uno\n' > "$MNT/uno.txt"
printf 'dos\n' > "$MNT/dos.txt"
printf 'tres\n' > "$MNT/tres.txt"
sync
```

Crear evidencia de todas las capas y un `fstab` alternativo:

```bash
{
  printf '%s\n' '--- bloques ---'
  lsblk -o NAME,TYPE,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$LOOP"
  printf '%s\n' '--- PV ---'
  sudo pvs --units m "$PART"
  printf '%s\n' '--- VG ---'
  sudo vgs --units m "$VG"
  printf '%s\n' '--- LV ---'
  sudo lvs --units m "$VG/$LV"
  printf '%s\n' '--- montaje ---'
  findmnt --mountpoint "$MNT"
  printf '%s\n' '--- capacidad ---'
  df -hT "$MNT"
  sudo du -sh "$MNT"
} | tee "$RETO/inventario.txt"

UUID_LAB=$(sudo blkid -s UUID -o value "$LV_PATH")
printf 'UUID=%s %s ext4 defaults,nofail 0 2\n' \
  "$UUID_LAB" "$MNT" > "$RETO/fstab.reto"
findmnt --verify --tab-file "$RETO/fstab.reto"
```

Respaldar fuera de la imagen y demostrar restauración:

```bash
ARCHIVO="$EXPORTADO/reto09-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
tar --exclude='./lost+found' -czf "$ARCHIVO" -C "$MNT" .
(
  cd "$EXPORTADO"
  sha256sum "$(basename -- "$ARCHIVO")" \
    > "$(basename -- "$ARCHIVO").sha256"
  sha256sum -c "$(basename -- "$ARCHIVO").sha256"
)

mkdir -p "$RESTAURADO/contenido"
tar -xzf "$ARCHIVO" -C "$RESTAURADO/contenido"
diff -ru --exclude=lost+found "$MNT" "$RESTAURADO/contenido"
```

### Limpieza obligatoria con las guardias repetidas

Redefinir variables permite ejecutar la limpieza en una terminal nueva:

```bash
LAB="$HOME/consultor-linux-lab/modulo-09"
RETO="$LAB/reto-09"
IMG="$RETO/reto-storage.img"
MNT="$RETO/mnt"
STATE="$RETO/loop-device"
VG="vg_reto_${UID}"
LV=lv_datos
LV_PATH="/dev/$VG/$LV"
LOOP=$(<"$STATE")
PART="${LOOP}p1"
```

Volver a declarar y ejecutar las guardias; no confiar sólo en el estado
guardado:

```bash
validar_loop_backing() {
  local loop=$1 imagen=$2 tipo backing
  [[ "$loop" =~ ^/dev/loop[0-9]+$ && -b $loop ]] || return 1
  tipo=$(lsblk -dn -o TYPE "$loop" | xargs)
  [[ $tipo == loop ]] || return 1
  backing=$(sudo losetup --list --noheadings --raw \
    --output BACK-FILE "$loop")
  [[ "$(readlink -f -- "$backing")" == "$(readlink -f -- "$imagen")" ]]
}

validar_particion_parent() {
  local part=$1 loop=$2 parent
  [[ "$part" == "${loop}p1" && -b $part ]] || return 1
  parent=$(lsblk --noheadings --nodeps --output PKNAME "$part" | xargs)
  [[ $parent == "$(basename -- "$loop")" ]]
}

validar_loop_backing "$LOOP" "$IMG" || {
  printf 'ABORTADO: loop/backing no coinciden\n' >&2
  exit 1
}
validar_particion_parent "$PART" "$LOOP" || {
  printf 'ABORTADO: parent de partición inesperado\n' >&2
  exit 1
}

PV_REAL=$(sudo pvs --noheadings -o pv_name,vg_name 2>/dev/null \
  | awk -v vg="$VG" '$2 == vg {print $1}')
[[ -n $PV_REAL \
   && "$(readlink -f -- "$PV_REAL")" == "$(readlink -f -- "$PART")" ]] || {
  printf 'ABORTADO: el PV de %s no es %s\n' "$VG" "$PART" >&2
  exit 1
}
sudo lvs "$VG/$LV" > /dev/null || {
  printf 'ABORTADO: no existe el LV esperado\n' >&2
  exit 1
}
```

Desmontar y retirar de adentro hacia afuera:

```bash
if findmnt -rn --mountpoint "$MNT" > /dev/null; then
  FUENTE=$(findmnt -rn -o SOURCE --mountpoint "$MNT")
  [[ "$(readlink -f -- "$FUENTE")" == "$(readlink -f -- "$LV_PATH")" ]] || {
    printf 'ABORTADO: el montaje contiene otro dispositivo\n' >&2
    exit 1
  }
  sudo umount "$MNT"
fi

validar_loop_backing "$LOOP" "$IMG" || exit 1
validar_particion_parent "$PART" "$LOOP" || exit 1
sudo lvremove -y "$VG/$LV"
sudo vgremove -y "$VG"
sudo pvremove -y "$PART"

validar_loop_backing "$LOOP" "$IMG" || exit 1
validar_particion_parent "$PART" "$LOOP" || exit 1
sudo losetup --detach "$LOOP"

if sudo losetup --associated "$IMG" --noheadings --output NAME | grep -q .; then
  printf 'ABORTADO: la imagen aún está asociada\n' >&2
  exit 1
fi

ESPERADO=$(realpath -m -- "$HOME/consultor-linux-lab/modulo-09/reto-09/reto-storage.img")
[[ "$(realpath -m -- "$IMG")" == "$ESPERADO" ]] || exit 1
rm -f -- "$IMG" "$STATE"
rmdir "$MNT" 2>/dev/null || true
```

Verificación final; el respaldo debe permanecer:

```bash
sudo vgs "$VG" > /dev/null 2>&1 && exit 1 || printf 'VG eliminado\n'
test ! -e "$IMG" && printf 'Imagen eliminada\n'
test -z "$(sudo losetup --associated "$IMG" --noheadings --output NAME)"
(
  cd "$RETO/exportado"
  sha256sum -c ./*.sha256
)
find "$RETO/exportado" -maxdepth 1 -type f -printf '%f\n' | sort
```

<a id="respuesta-reto-10"></a>
## Respuesta reto 10 — Expediente operativo de Nginx

Ejecutar en EC2 desde cualquier directorio. Nginx debe estar instalado como en
el módulo 10:

```bash
EVIDENCIA=/srv/consultor-linux/evidencias/servicio-nginx.txt
ERRORES=/srv/consultor-linux/evidencias/servicio-nginx.err
sudo install -d -o ubuntu -g ops -m 0750 "$(dirname "$EVIDENCIA")"

dpkg-query -W nginx > /dev/null 2>&1 || {
  sudo apt update
  sudo apt install -y nginx
}
sudo nginx -t
sudo systemctl start nginx
systemctl is-active --quiet nginx

MAINPID=$(systemctl show nginx --property MainPID --value)
{
  printf '%s\n' '--- paquete ---'
  dpkg-query -W -f='nombre=${Package} version=${Version} estado=${db:Status-Abbrev}\n' nginx
  printf '%s\n' '--- unidad ---'
  systemctl show nginx --property ActiveState,SubState --no-pager
  printf '%s\n' '--- proceso principal ---'
  ps -p "$MAINPID" -o pid=,ppid=,user=,comm=,args=
  printf '%s\n' '--- socket TCP ---'
  sudo ss -lntp '( sport = :80 )'
  printf '%s\n' '--- HTTP loopback ---'
  curl --silent --show-error --output /dev/null \
    --write-out 'HTTP %{http_code}\n' http://127.0.0.1/
  printf '%s\n' '--- ultimas cinco lineas de acceso ---'
  sudo tail -n 5 /var/log/nginx/access.log
} 2> "$ERRORES" | tee "$EVIDENCIA"

sudo systemctl disable --now nginx
```

Verificación:

```bash
test -s "$EVIDENCIA"
test "$(grep -c '^--- ' "$EVIDENCIA")" -eq 6
grep -E '^HTTP (200|204|301|302)$' "$EVIDENCIA"
if systemctl is-active --quiet nginx; then
  printf 'FALLO: Nginx continúa activo\n' >&2
  exit 1
else
  printf 'OK: Nginx quedó inactivo\n'
fi
sudo ss -lntp '( sport = :80 )'
```

La última consulta no debe mostrar una escucha de Nginx. Limpieza opcional de
la evidencia, no del paquete:

```bash
rm -i -- /srv/consultor-linux/evidencias/servicio-nginx.txt
rm -i -- /srv/consultor-linux/evidencias/servicio-nginx.err
```

<a id="respuesta-reto-11"></a>
## Respuesta reto 11 — Aislamiento y persistencia de contenedores

Ejecutar en EC2 desde la raíz del repositorio:

```bash
cd "$HOME/linux-desde-cero"
bash scripts/preparar-proyecto.sh

EVIDENCIA=/srv/consultor-linux/evidencias/aislamiento-contenedores.txt
ERRORES=/srv/consultor-linux/evidencias/aislamiento-contenedores.err
COMPOSE=(sudo docker compose \
  --project-directory "$PWD/proyecto-compose" \
  --file "$PWD/proyecto-compose/compose.yaml")

SERVICIOS=$("${COMPOSE[@]}" config --services | sort)
test "$SERVICIOS" = $'db\nproxy\nwordpress'

"${COMPOSE[@]}" exec -T wordpress sh -eu -c \
  'printf "persistencia-reto-11\n" > /var/www/html/reto11-persistencia.txt'

"${COMPOSE[@]}" stop
"${COMPOSE[@]}" start
"${COMPOSE[@]}" up --detach --wait
```

Crear la evidencia sin inspeccionar variables de entorno ni secretos:

```bash
{
  printf '%s\n' '--- servicios declarados ---'
  printf '%s\n' "$SERVICIOS"

  printf '%s\n' '--- unico puerto publicado ---'
  "${COMPOSE[@]}" port proxy 80

  PUERTO_DB=$("${COMPOSE[@]}" port db 3306 2>/dev/null || true)
  if [[ -z $PUERTO_DB || $PUERTO_DB == :0 ]]; then
    printf 'OK: db sin puerto publicado\n'
  else
    printf 'FALLO db=%s\n' "$PUERTO_DB"
  fi

  PUERTO_WP=$("${COMPOSE[@]}" port wordpress 80 2>/dev/null || true)
  if [[ -z $PUERTO_WP || $PUERTO_WP == :0 ]]; then
    printf 'OK: wordpress sin puerto publicado\n'
  else
    printf 'FALLO wordpress=%s\n' "$PUERTO_WP"
  fi

  printf '%s\n' '--- DNS interno desde wordpress ---'
  "${COMPOSE[@]}" exec -T wordpress getent hosts db

  printf '%s\n' '--- salud despues de stop/start ---'
  for servicio in db wordpress proxy; do
    id=$("${COMPOSE[@]}" ps -q "$servicio")
    salud=$(sudo docker inspect --format '{{.State.Health.Status}}' "$id")
    printf '%s=%s\n' "$servicio" "$salud"
  done

  printf '%s\n' '--- dato persistente ---'
  "${COMPOSE[@]}" exec -T wordpress \
    cat /var/www/html/reto11-persistencia.txt

  printf '%s\n' '--- respuesta HTTP ---'
  curl --silent --show-error --output /dev/null \
    --write-out 'HTTP %{http_code}\n' \
    http://127.0.0.1:8080/healthz
} 2> "$ERRORES" | tee "$EVIDENCIA"
```

Verificación:

```bash
test "$(printf '%s\n' "$SERVICIOS" | wc -l)" -eq 3
test "$("${COMPOSE[@]}" port proxy 80)" = '127.0.0.1:8080'
PUERTO_DB=$("${COMPOSE[@]}" port db 3306 2>/dev/null || true)
PUERTO_WP=$("${COMPOSE[@]}" port wordpress 80 2>/dev/null || true)
[[ -z $PUERTO_DB || $PUERTO_DB == :0 ]]
[[ -z $PUERTO_WP || $PUERTO_WP == :0 ]]
test "$(grep -c '=healthy$' "$EVIDENCIA")" -eq 3
grep -qxF 'persistencia-reto-11' "$EVIDENCIA"
grep -qxF 'HTTP 200' "$EVIDENCIA"
```

Algunas versiones de Compose representan un puerto declarado por la imagen,
pero no publicado, como `:0`; no es una escucha del host. La única asignación
aceptada con puerto real es `127.0.0.1:8080` para `proxy`.

Limpieza del marcador y parada no destructiva al terminar la jornada:

```bash
"${COMPOSE[@]}" exec -T wordpress \
  rm -f -- /var/www/html/reto11-persistencia.txt
"${COMPOSE[@]}" stop
```

Para continuar con el módulo 12, vuelve a iniciar sin borrar volúmenes:

```bash
"${COMPOSE[@]}" start
"${COMPOSE[@]}" up --detach --wait
```

<a id="respuesta-reto-12"></a>
## Respuesta reto 12 — Auditoría de seguridad

Precondiciones: el hardening del módulo 12 ya fue aplicado y probado desde una
segunda conexión; el stack está sano y existe al menos un respaldo. Esas
correcciones se hacen **antes** de auditar, no dentro del auditor:

```bash
cd "$HOME/linux-desde-cero"
bash scripts/preparar-proyecto.sh
find backups -maxdepth 1 -type f -name 'consultor-linux-*.tar.gz' -print -quit \
  | grep -q . || bash scripts/respaldo-proyecto.sh
```

Crear un auditor que sólo consulta y clasifica:

```bash
AUDITOR="$HOME/consultor-linux-lab/auditar-seguridad.sh"
mkdir -p "$(dirname "$AUDITOR")"

tee "$AUDITOR" > /dev/null <<'BASH'
#!/usr/bin/env bash
set -uo pipefail
export LC_ALL=C

REPO="$HOME/linux-desde-cero"
INFORME=/srv/consultor-linux/evidencias/auditoria-seguridad.txt
cd "$REPO" || exit 1
COMPOSE=(sudo docker compose \
  --project-directory "$REPO/proyecto-compose" \
  --file "$REPO/proyecto-compose/compose.yaml")

registrar() {
  local numero=$1 descripcion=$2 resultado=$3
  printf 'CONTROL %02d | %s | %s\n' "$numero" "$descripcion" "$resultado"
}

valor_sshd() {
  local clave=$1
  sudo sshd -T 2>/dev/null \
    | awk -v clave="$clave" '$1 == clave {print $2; exit}'
}

control_ufw() {
  local estado
  estado=$(sudo ufw status)
  grep -qxF 'Status: active' <<< "$estado" \
    && grep -Eq '^OpenSSH[[:space:]]+ALLOW' <<< "$estado"
}

control_secretos() {
  local archivo
  local -a secretos
  mapfile -t secretos < <(
    find proyecto-compose/secrets -maxdepth 1 -type f -name '*.txt' | sort
  )
  (( ${#secretos[@]} == 2 )) || return 1
  for archivo in "${secretos[@]}"; do
    [[ $(stat -c %a "$archivo") == 600 ]] || return 1
    git check-ignore -q -- "$archivo" || return 1
  done
}

control_oom() {
  local id valor
  local -a ids
  mapfile -t ids < <("${COMPOSE[@]}" ps -q)
  (( ${#ids[@]} == 3 )) || return 1
  for id in "${ids[@]}"; do
    valor=$(sudo docker inspect --format '{{.State.OOMKilled}}' "$id")
    [[ $valor == false ]] || return 1
  done
}

control_checksum() {
  local respaldo
  respaldo=$(find backups -maxdepth 1 -type f \
    -name 'consultor-linux-*.tar.gz' -printf '%T@ %p\n' \
    | sort -nr | head -n 1 | cut -d' ' -f2-)
  [[ -n $respaldo && -f $respaldo.sha256 ]] || return 1
  (
    cd "$(dirname -- "$respaldo")" || exit 1
    sha256sum --check "$(basename -- "$respaldo").sha256" > /dev/null
  )
}

{
  printf 'fecha=%s\n' "$(date --iso-8601=seconds)"
  printf 'host=%s\n' "$(hostname)"
  printf 'usuario=%s\n' "$(whoami)"

  if [[ $(valor_sshd passwordauthentication) == no ]]; then
    registrar 1 'SSH por contraseña desactivado' OK
  else
    registrar 1 'SSH por contraseña desactivado' FALLO
  fi

  if [[ $(valor_sshd permitrootlogin) == no ]]; then
    registrar 2 'SSH directo de root desactivado' OK
  else
    registrar 2 'SSH directo de root desactivado' FALLO
  fi

  if control_ufw; then
    registrar 3 'UFW activo y OpenSSH permitido' OK
  else
    registrar 3 'UFW activo y OpenSSH permitido' FALLO
  fi

  puerto_proxy=$("${COMPOSE[@]}" port proxy 80 2>/dev/null || true)
  if [[ $puerto_proxy == 127.0.0.1:8080 ]]; then
    registrar 4 'Proxy ligado a loopback 8080' OK
  else
    registrar 4 'Proxy ligado a loopback 8080' FALLO
  fi

  puerto_db=$("${COMPOSE[@]}" port db 3306 2>/dev/null || true)
  if [[ -z $puerto_db ]]; then
    registrar 5 'MariaDB sin puerto publicado' OK
  else
    registrar 5 'MariaDB sin puerto publicado' FALLO
  fi

  if control_secretos; then
    registrar 6 'Secretos 600 e ignorados por Git' OK
  else
    registrar 6 'Secretos 600 e ignorados por Git' FALLO
  fi

  if systemctl is-active --quiet apparmor; then
    registrar 7 'AppArmor activo' OK
  else
    registrar 7 'AppArmor activo' FALLO
  fi

  if control_oom; then
    registrar 8 'Contenedores sin OOMKilled' OK
  else
    registrar 8 'Contenedores sin OOMKilled' FALLO
  fi

  if control_checksum; then
    registrar 9 'Checksum del respaldo más reciente' OK
  else
    registrar 9 'Checksum del respaldo más reciente' FALLO
  fi
} | tee "$INFORME"
BASH

chmod 750 "$AUDITOR"
bash -n "$AUDITOR"
if command -v shellcheck > /dev/null; then
  shellcheck "$AUDITOR"
fi
"$AUDITOR"
```

Verificación de cardinalidad y resultado:

```bash
INFORME=/srv/consultor-linux/evidencias/auditoria-seguridad.txt
test "$(grep -Ec '^CONTROL [0-9]{2} \| .* \| (OK|FALLO)$' "$INFORME")" -eq 9
test "$(grep -cF '| FALLO' "$INFORME")" -eq 0
test "$(grep -cF '| OK' "$INFORME")" -eq 9

if grep -Ein 'BEGIN .*PRIVATE KEY|aws_secret|[[:xdigit:]]{48}' "$INFORME"; then
  printf 'Revisión manual: posible dato sensible\n' >&2
  exit 1
fi

curl --fail --silent http://127.0.0.1:8080/healthz
```

Si aparece `FALLO`, conserva ese primer informe, corrige fuera del auditor y
vuelve a ejecutarlo. Limpieza del ejecutable auxiliar; la auditoría se conserva:

```bash
rm -f -- "$HOME/consultor-linux-lab/auditar-seguridad.sh"
```

<a id="respuesta-reto-13"></a>
## Respuesta reto 13 — Entrega a otro consultor

Esta solución tiene puntos de control humanos: completar WordPress por el túnel
y terminar los recursos desde la consola AWS. No deben automatizarse mediante
credenciales escritas en el repositorio.

### 1. Preparar y desplegar en EC2

```bash
cd "$HOME/linux-desde-cero"
REPO=$PWD
COMPOSE=(sudo docker compose \
  --project-directory "$REPO/proyecto-compose" \
  --file "$REPO/proyecto-compose/compose.yaml")

bash scripts/programar-apagado.sh 360
bash scripts/verificar-entorno.sh
git status --short
if git status --porcelain --untracked-files=no | grep -q .; then
  printf 'FALLO: hay cambios rastreados sin confirmar\n' >&2
  exit 1
fi
git ls-files 'proyecto-compose/secrets/*' | grep -q . \
  && { printf 'FALLO: secretos rastreados\n' >&2; exit 1; } \
  || printf 'OK: secretos fuera de Git\n'

"${COMPOSE[@]}" config --quiet
bash -n proyecto-compose/wordpress/entrypoint.sh
bash scripts/preparar-proyecto.sh
```

Comprobar servicios, aislamiento, límites y recursos:

```bash
SERVICIOS=$("${COMPOSE[@]}" config --services | sort)
test "$SERVICIOS" = $'db\nproxy\nwordpress'
test "$("${COMPOSE[@]}" port proxy 80)" = '127.0.0.1:8080'
test -z "$("${COMPOSE[@]}" port db 3306 2>/dev/null || true)"

for servicio in db wordpress proxy; do
  id=$("${COMPOSE[@]}" ps -q "$servicio")
  test -n "$id"
  sudo docker inspect --format \
    "$servicio health={{.State.Health.Status}} oom={{.State.OOMKilled}} memory={{.HostConfig.Memory}} log={{json .HostConfig.LogConfig}}" \
    "$id"
done

"${COMPOSE[@]}" exec -T wordpress getent hosts db
curl --fail --silent http://127.0.0.1:8080/healthz
free -m
df -h /
sudo docker stats --no-stream
```

Los tres servicios deben estar `healthy`, `oom=false`, con memoria distinta de
cero y log limitado a `10m`/tres archivos.

### 2. Abrir el túnel desde la computadora

Ejecutar localmente; escribir la IPv4 actual cuando se solicite:

```bash
CLAVE="$HOME/.ssh/consultor-linux.pem"
read -r -p 'IPv4 pública actual de EC2: ' IP_PUBLICA
chmod 600 "$CLAVE"
ssh -o IdentitiesOnly=yes -i "$CLAVE" \
  -L 8080:127.0.0.1:8080 "ubuntu@$IP_PUBLICA"
```

Sin cerrar esa terminal, abrir `http://127.0.0.1:8080` y completar WordPress.
Crear la entrada `Evidencia antes del respaldo` con una frase única que no sea
una contraseña. No continuar hasta comprobarla en el navegador.

Comprobación adicional en EC2, válida con el tema predeterminado:

```bash
curl --fail --silent http://127.0.0.1:8080/ \
  | grep -F 'Evidencia antes del respaldo'
```

Si el tema no muestra el título en la portada, la verificación visual se guarda
en la rúbrica, pero no se introducen credenciales en un script para forzarla.

### 3. Respaldar y descargar antes de destruir

En EC2:

```bash
cd "$HOME/linux-desde-cero"
bash scripts/respaldo-proyecto.sh

RESPALDO=$(find backups -maxdepth 1 -type f \
  -name 'consultor-linux-*.tar.gz' -printf '%T@ %p\n' \
  | sort -nr | head -n 1 | cut -d' ' -f2-)
test -n "$RESPALDO"
(
  cd "$(dirname -- "$RESPALDO")"
  sha256sum --check "$(basename -- "$RESPALDO").sha256"
)
tar -tzf "$RESPALDO" | grep -E \
  '^(database\.sql|wordpress-files\.tar\.gz|manifest\.txt)$'
printf 'RESPALDO=%s\n' "$RESPALDO"
```

En la computadora, la consulta SSH obtiene el nombre más reciente sin fijar
una fecha en el documento:

```bash
CLAVE="$HOME/.ssh/consultor-linux.pem"
read -r -p 'IPv4 pública actual de EC2: ' IP_PUBLICA
DESTINO="$HOME/entrega-consultor-linux"
mkdir -p "$DESTINO"

ARCHIVO=$(ssh -o IdentitiesOnly=yes -i "$CLAVE" "ubuntu@$IP_PUBLICA" \
  "find ~/linux-desde-cero/backups -maxdepth 1 -type f -name 'consultor-linux-*.tar.gz' -printf '%T@ %f\\n' | sort -nr | head -n 1 | cut -d' ' -f2-")
test -n "$ARCHIVO"

scp -i "$CLAVE" \
  "ubuntu@$IP_PUBLICA:linux-desde-cero/backups/$ARCHIVO" \
  "ubuntu@$IP_PUBLICA:linux-desde-cero/backups/$ARCHIVO.sha256" \
  "$DESTINO/"
(
  cd "$DESTINO"
  sha256sum --check "$ARCHIVO.sha256"
)
```

No continuar hasta ver `OK` en la computadora.

### 4. Probar la barrera y restaurar con confirmación

De nuevo en EC2:

```bash
cd "$HOME/linux-desde-cero"
RESPALDO=$(find backups -maxdepth 1 -type f \
  -name 'consultor-linux-*.tar.gz' -printf '%T@ %p\n' \
  | sort -nr | head -n 1 | cut -d' ' -f2-)

estado=0
bash scripts/restaurar-proyecto.sh "$RESPALDO" \
  > /tmp/restauracion-sin-confirmar.out \
  2> /tmp/restauracion-sin-confirmar.err || estado=$?
test "$estado" -eq 2
grep -F -- '--confirmar' /tmp/restauracion-sin-confirmar.err

bash scripts/restaurar-proyecto.sh "$RESPALDO" --confirmar
```

La segunda invocación valida el hash, elimina sólo los volúmenes del proyecto,
crea volúmenes nuevos, restaura base y archivos, y espera el proxy.

Verificación posterior:

```bash
"${COMPOSE[@]}" ps
test "$("${COMPOSE[@]}" port proxy 80)" = '127.0.0.1:8080'
test -z "$("${COMPOSE[@]}" port db 3306 2>/dev/null || true)"
curl --fail --silent http://127.0.0.1:8080/healthz
curl --fail --silent http://127.0.0.1:8080/ \
  | grep -F 'Evidencia antes del respaldo'
```

Confirmar también desde el navegador, a través del mismo túnel, que reapareció
la frase única.

### 5. Generar evidencia final

En EC2:

```bash
INFORME=/srv/consultor-linux/evidencias/proyecto-final.txt
{
  printf '%s\n' '# Proyecto final Consultor Linux'
  printf 'fecha=%s\nhost=%s\nusuario=%s\n' \
    "$(date --iso-8601=seconds)" "$(hostname)" "$(whoami)"

  printf '%s\n' '--- sistema ---'
  grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release
  uname -r

  printf '%s\n' '--- identidades ---'
  getent passwd deploy
  getent group ops

  printf '%s\n' '--- servicios ---'
  "${COMPOSE[@]}" ps

  printf '%s\n' '--- imagenes y limites ---'
  for servicio in db wordpress proxy; do
    id=$("${COMPOSE[@]}" ps -q "$servicio")
    sudo docker inspect --format \
      "$servicio image={{.Config.Image}} health={{.State.Health.Status}} oom={{.State.OOMKilled}} memory={{.HostConfig.Memory}}" \
      "$id"
  done

  printf '%s\n' '--- red ---'
  "${COMPOSE[@]}" port proxy 80
  if [[ -z $("${COMPOSE[@]}" port db 3306 2>/dev/null || true) ]]; then
    printf 'db_sin_puerto=OK\n'
  else
    printf 'db_sin_puerto=FALLO\n'
  fi

  printf '%s\n' '--- HTTP ---'
  curl --silent --show-error --output /dev/null \
    --write-out 'HTTP %{http_code}\n' http://127.0.0.1:8080/

  printf '%s\n' '--- hardening ---'
  sudo ufw status verbose
  sudo sshd -T | grep -E \
    '^(passwordauthentication|permitrootlogin|allowtcpforwarding|maxauthtries) '
  printf 'apparmor=%s\n' "$(systemctl is-active apparmor)"

  printf '%s\n' '--- secretos: solo metadatos ---'
  find proyecto-compose/secrets -maxdepth 1 -type f \
    -printf '%m %u:%g %p\n'

  printf '%s\n' '--- restauracion y respaldo ---'
  printf 'restauracion_destruccion_volumenes=OK\n'
  (
    cd "$(dirname -- "$RESPALDO")"
    sha256sum --check "$(basename -- "$RESPALDO").sha256"
  )

  printf '%s\n' '--- recursos ---'
  free -h
  df -h /
  sudo docker stats --no-stream
} | tee "$INFORME"

test -s "$INFORME"
grep -F 'restauracion_destruccion_volumenes=OK' "$INFORME"
```

Revisión preventiva; cualquier coincidencia se inspecciona antes de entregar:

```bash
if grep -Ein 'BEGIN .*PRIVATE KEY|aws_secret|[[:xdigit:]]{48}' "$INFORME"; then
  printf 'FALLO: revisar posible dato sensible\n' >&2
  exit 1
fi
```

### 6. Crear el runbook

````bash
RUNBOOK="$HOME/linux-desde-cero/runbook.md"
tee "$RUNBOOK" > /dev/null <<'MARKDOWN'
# Runbook: Consultor Linux

## Propósito y arquitectura

WordPress de evaluación: Nginx `proxy` → WordPress/Apache → MariaDB `db`.
Sólo `127.0.0.1:8080` se publica; el navegador entra mediante túnel SSH.

## Iniciar y comprobar

```bash
cd ~/linux-desde-cero
bash scripts/preparar-proyecto.sh
sudo docker compose -f proyecto-compose/compose.yaml up -d --wait
curl --fail http://127.0.0.1:8080/healthz
```

Esperado: tres servicios saludables y respuesta `ok`.

## Parada no destructiva

```bash
sudo docker compose -f proyecto-compose/compose.yaml stop
```

No agregar `--volumes` para una parada ordinaria.

## Estado y recursos

```bash
sudo docker compose -f proyecto-compose/compose.yaml ps
sudo ss -lnt '( sport = :8080 )'
free -m
df -h /
sudo docker stats --no-stream
```

## Logs

```bash
sudo docker compose -f proyecto-compose/compose.yaml logs \
  --since 15m --tail 100 --timestamps proxy wordpress db
```

## Respaldo

```bash
bash scripts/respaldo-proyecto.sh
cd backups
sha256sum --check consultor-linux-TIMESTAMP.tar.gz.sha256
```

Sustituir `TIMESTAMP` por el nombre impreso. Descargar archivo y checksum antes
de una restauración destructiva.

## Restauración

Precondiciones: checksum local y remoto `OK`, contenido único identificado y
autorización del responsable.

```bash
bash scripts/restaurar-proyecto.sh \
  backups/consultor-linux-TIMESTAMP.tar.gz --confirmar
```

## Diagnóstico

Comprobar, en orden: sesión SSH, túnel local, escucha 8080, salud de `proxy`,
DNS interno hacia `wordpress` y `db`, logs, memoria y disco. Conservar evidencia
antes de recrear componentes.

## Acceso

```text
ssh -i <CLAVE.pem> -L 8080:127.0.0.1:8080 ubuntu@<IP_PUBLICA_ACTUAL>
```

La clave y la IP reales no se guardan en este archivo.

## Cierre AWS

1. Verificar localmente respaldo, checksum y evidencias.
2. Ejecutar `bash scripts/limpiar-proyecto.sh --eliminar-datos --confirmar`.
3. Terminar EC2 y comprobar eliminación del EBS raíz.
4. Confirmar que no quedan Elastic IP, snapshots ni volúmenes adicionales.
5. Eliminar Security Group y key pair del curso.
6. Revisar EC2 Global View y Billing al día siguiente.
MARKDOWN

test -s "$RUNBOOK"
grep -F -- '--confirmar' "$RUNBOOK"
````

### 7. Descargar la entrega completa

En la computadora, con `CLAVE` e `IP_PUBLICA` definidos:

```bash
DESTINO="$HOME/entrega-consultor-linux"
mkdir -p "$DESTINO"

scp -r -i "$CLAVE" \
  "ubuntu@$IP_PUBLICA:/srv/consultor-linux/evidencias" \
  "$DESTINO/"
scp -i "$CLAVE" \
  "ubuntu@$IP_PUBLICA:linux-desde-cero/runbook.md" \
  "$DESTINO/"

(
  cd "$DESTINO"
  sha256sum --check "$ARCHIVO.sha256"
)

if grep -ERin \
  'BEGIN .*PRIVATE KEY|aws_secret|[[:xdigit:]]{48}' \
  "$DESTINO/evidencias" "$DESTINO/runbook.md"; then
  printf 'Revisar posible dato sensible antes de entregar\n' >&2
  exit 1
fi
```

No copiar `proyecto-compose/secrets/` ni el archivo `.pem`.

### 8. Limpieza del proyecto y AWS

Sólo después de verificar la entrega local, en EC2:

```bash
cd "$HOME/linux-desde-cero"
bash scripts/limpiar-proyecto.sh --eliminar-datos --confirmar

test -z "$(sudo docker compose -f proyecto-compose/compose.yaml ps -q)"
test -z "$(sudo docker volume ls -q \
  --filter label=com.docker.compose.project=consultor-linux)"
test ! -d proyecto-compose/secrets
rm -f -- /tmp/restauracion-sin-confirmar.out \
  /tmp/restauracion-sin-confirmar.err
```

No ejecutar `docker system prune`. Finalmente, desde la consola AWS:

1. detener y **terminar** la EC2;
2. comprobar que desapareció el EBS raíz con `DeleteOnTermination=true`;
3. confirmar que no existen Elastic IP, snapshots o volúmenes adicionales;
4. eliminar el Security Group y el key pair del curso cuando ya no estén asociados;
5. revisar todas las regiones en EC2 Global View;
6. revisar Free Tier y Billing al día siguiente.

La solución se considera completa sólo cuando la copia local sigue dando
`OK` y la consola confirma que los recursos AWS fueron eliminados.
