# Soluciones de los retos

Este documento es para el instructor. Las soluciones son referencias; se aceptan alternativas que cumplan los criterios y no debiliten seguridad.

Salvo que se indique lo contrario, ejecuta las soluciones desde la raíz del curso. Los nombres dentro de `< >` son marcadores y deben sustituirse antes de entregar un comando al alumno.

## Índice

- [Reto 1](#reto-1--inventario-reproducible)
- [Reto 2](#reto-2--flujo-de-componentes)
- [Reto 3](#reto-3--directorio-compartido)
- [Reto 7](#reto-7--snapshot-de-evidencias)
- [Reto 8](#reto-8--pipeline-auditable)
- [Reto 9](#reto-9--operación-observable)
- [Reto 10](#reto-10--resumen-parametrizado)
- [Reto 11](#reto-11--entrega-devops)

<a id="respuesta-reto-1"></a>
## Reto 1 — Inventario reproducible

En Clase 1, el alumno crea `~/curso-linux/evidencias/inventario.txt` desde Text Editor y copia las salidas observadas de `hostname`, `cat /etc/os-release`, `uname -r`, `whoami`, `id -nG` y `command -v bash`. La automatización con redirecciones y sustitución de comandos se resuelve después de estudiar Clase 3.

Como referencia para el instructor, la versión automatizada es:

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

En Clase 1, crear `app.env` y `check.sh` con `touch`; escribir el contenido de `check.sh` desde Text Editor antes de aplicar permisos. La versión siguiente conserva una solución automatizada para consulta posterior.

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

<a id="respuesta-reto-7"></a>
## Reto 7 — Snapshot de evidencias

```bash
mkdir -p laboratorio/reto7/restaurado
find data -type f -name '*.txt'
find data -type f -name '*.csv'
tar -czf laboratorio/reto7/snapshot.tar.gz data/dummy_logs.txt data/basketball_scores.csv
tar -tzf laboratorio/reto7/snapshot.tar.gz
tar -xzf laboratorio/reto7/snapshot.tar.gz -C laboratorio/reto7/restaurado
sha256sum data/dummy_logs.txt laboratorio/reto7/restaurado/data/dummy_logs.txt
sha256sum data/basketball_scores.csv laboratorio/reto7/restaurado/data/basketball_scores.csv
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
