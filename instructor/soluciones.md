# Soluciones de los retos

Este documento es para el instructor. Las soluciones son referencias; se aceptan alternativas que cumplan los criterios y no debiliten seguridad.

Salvo que se indique lo contrario, ejecuta las soluciones desde la raíz del curso. Los nombres dentro de `< >` son marcadores y deben sustituirse antes de entregar un comando al alumno.

<a id="respuesta-reto-1"></a>
## Reto 1 — Inventario reproducible

```bash
mkdir -p ~/curso-linux/evidencias
{
  printf 'Hostname: %s\n' "$(hostname)"
  printf 'Distribución: '
  . /etc/os-release && printf '%s\n' "$PRETTY_NAME"
  printf 'Kernel: %s\n' "$(uname -r)"
  printf 'Usuario: %s\n' "$(whoami)"
  printf 'Grupos: %s\n' "$(id -nG)"
  printf 'Bash: %s\n' "$(command -v bash)"
} > ~/curso-linux/evidencias/inventario.txt
cat ~/curso-linux/evidencias/inventario.txt
```

<a id="respuesta-reto-2"></a>
## Reto 2 — Flujo de componentes

```bash
mkdir -p laboratorio/reto2
printf '%s\n' api worker api scheduler worker api cache cache \
  > laboratorio/reto2/servicios.txt
sort laboratorio/reto2/servicios.txt | uniq -c \
  > laboratorio/reto2/resumen.txt
test "$(wc -l < laboratorio/reto2/servicios.txt)" -eq \
     "$(awk '{s += $1} END {print s}' laboratorio/reto2/resumen.txt)"
```

<a id="respuesta-reto-3"></a>
## Reto 3 — Directorio compartido

```bash
mkdir -p laboratorio/compartido
chmod 770 laboratorio/compartido
printf 'PORT=8080\n' > laboratorio/compartido/app.env
printf '#!/usr/bin/env bash\necho ok\n' > laboratorio/compartido/check.sh
chmod 660 laboratorio/compartido/app.env
chmod 770 laboratorio/compartido/check.sh
ln -s check.sh laboratorio/compartido/check-actual
ls -ld laboratorio/compartido laboratorio/compartido/*
readlink laboratorio/compartido/check-actual
```

<a id="respuesta-reto-4"></a>
## Reto 4 — Mapa de la sesión gráfica

```bash
{
  printf 'Protocolo: %s\n' "${XDG_SESSION_TYPE:-sin sesión gráfica}"
  printf 'Escritorio: %s\n' "${XDG_CURRENT_DESKTOP:-no definido}"
  printf 'X11: %s\n' "${DISPLAY:-no definido}"
  printf 'Wayland: %s\n' "${WAYLAND_DISPLAY:-no definido}"
  ps -e | grep -E 'gnome-shell|kwin_wayland|Xorg' || true
} > laboratorio/sesion-grafica.txt
```

<a id="respuesta-reto-5"></a>
## Reto 5 — GUI y CLI equivalentes

Solución posible después de crear el archivo original desde Files:

```bash
mkdir -p ~/curso-gui/reto5
printf 'evidencia=gnome\n' > ~/curso-gui/reto5/origen.txt
cp ~/curso-gui/reto5/origen.txt ~/curso-gui/reto5/copia.txt
mv ~/curso-gui/reto5/copia.txt ~/curso-gui/reto5/final.txt
chmod 640 ~/curso-gui/reto5/final.txt
sha256sum ~/curso-gui/reto5/origen.txt ~/curso-gui/reto5/final.txt \
  | tee ~/curso-gui/reto5/evidencia.txt
stat -c '%A %a %U:%G %n' ~/curso-gui/reto5/final.txt \
  >> ~/curso-gui/reto5/evidencia.txt
```

<a id="respuesta-reto-6"></a>
## Reto 6 — Diagnóstico desde Dolphin

```bash
mkdir -p ~/curso-gui/kde-demo
printf '#!/usr/bin/env bash\necho ok\n' > ~/curso-gui/kde-demo/check.sh
chmod 640 ~/curso-gui/kde-demo/check.sh
file ~/curso-gui/kde-demo/check.sh
namei -l ~/curso-gui/kde-demo/check.sh
stat -c '%A %a %U:%G %n' ~/curso-gui/kde-demo/check.sh
chmod u+x ~/curso-gui/kde-demo/check.sh
stat -c '%A %a %U:%G %n' ~/curso-gui/kde-demo/check.sh
```

<a id="respuesta-reto-7"></a>
## Reto 7 — Snapshot de evidencias

```bash
mkdir -p laboratorio/reto7/{paquete,restaurado}
find data -type f \( -name '*.txt' -o -name '*.csv' \) -size +0c \
  -printf '%s %p\n' | sort -n > laboratorio/reto7/paquete/inventario.txt
cp data/dummy_logs.txt laboratorio/reto7/paquete/
tar -czf laboratorio/reto7/snapshot.tar.gz -C laboratorio/reto7 paquete
tar -tzf laboratorio/reto7/snapshot.tar.gz
tar -xzf laboratorio/reto7/snapshot.tar.gz -C laboratorio/reto7/restaurado
cmp laboratorio/reto7/paquete/inventario.txt \
    laboratorio/reto7/restaurado/paquete/inventario.txt
```

<a id="respuesta-reto-8"></a>
## Reto 8 — Pipeline auditable

```bash
mkdir -p laboratorio/reto8
grep -oE 'User [[:alnum:]_-]+' data/dummy_logs.txt \
  2> laboratorio/reto8/errores.log \
  | cut -d' ' -f2 \
  | sort -u \
  | tee laboratorio/reto8/usuarios.txt \
  | wc -l
wc -l laboratorio/reto8/usuarios.txt
```

<a id="respuesta-reto-9"></a>
## Reto 9 — Operación observable

```bash
mkdir -p laboratorio/reto9
nohup bash script_largo.sh > laboratorio/reto9/proceso.log 2>&1 &
pid=$!
printf '%s\n' "$pid" > laboratorio/reto9/proceso.pid
ps -p "$pid" -o pid,ppid,stat,etime,comm
time true
systemctl status ssh --no-pager > laboratorio/reto9/ssh-status.txt
kill -TERM "$pid"
wait "$pid" 2>/dev/null || true
! ps -p "$pid"
```

<a id="respuesta-reto-10"></a>
## Reto 10 — Resumen parametrizado

```bash
#!/usr/bin/env bash
set -o nounset
set -o pipefail

if [[ $# -ne 2 ]]; then
  printf 'Uso: %s <log> <reporte>\n' "$0" >&2
  exit 64
fi
log=$1
reporte=$2
if [[ ! -r "$log" ]]; then
  printf 'Entrada no legible: %s\n' "$log" >&2
  exit 66
fi
{
  for nivel in INFO WARN ERROR; do
    printf '%-5s %s\n' "$nivel" "$(grep -c "$nivel" "$log" || true)"
  done
  printf 'Usuarios:\n'
  grep -oE 'User [[:alnum:]_-]+' "$log" | cut -d' ' -f2 | sort -u
} > "$reporte"
```

<a id="respuesta-reto-11"></a>
## Reto 11 — Entrega DevOps

Antes de ejecutar la solución, define los datos reales del alumno:

```bash
CLAVE="$HOME/.ssh/curso-linux.pem"
USUARIO_REMOTO="ubuntu"
IP_PUBLICA="203.0.113.10"  # Sustituir por la IP real
```

```bash
mkdir -p laboratorio/reto11
grep -En 'WARN|ERROR' data/dummy_logs.txt > laboratorio/reto11/incidentes.txt
{
  ip -brief address
  ip route
  getent hosts example.com
} > laboratorio/reto11/red.txt
tar -czf laboratorio/reto11.tar.gz -C laboratorio reto11
tar -tzf laboratorio/reto11.tar.gz
(cd laboratorio && sha256sum reto11.tar.gz > reto11.tar.gz.sha256)
scp -i "$CLAVE" laboratorio/reto11.tar.gz* \
  "${USUARIO_REMOTO}@${IP_PUBLICA}:/home/ubuntu/"
ssh -i "$CLAVE" "${USUARIO_REMOTO}@${IP_PUBLICA}" \
  'sha256sum -c reto11.tar.gz.sha256 && tar -xzf reto11.tar.gz'
scp -i "$CLAVE" \
  "${USUARIO_REMOTO}@${IP_PUBLICA}:/home/ubuntu/reto11/incidentes.txt" \
  laboratorio/incidentes-recuperado.txt
```
