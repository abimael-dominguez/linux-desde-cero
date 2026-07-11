# 9. Ejecución de programas, procesos y servicios

## Objetivos

- Identificar procesos y relaciones padre/hijo.
- Controlar trabajos en foreground y background.
- Enviar señales y ajustar prioridad.
- inspeccionar servicios y logs con systemd.

## Antes de empezar

Abre una terminal nueva, sitúate en la raíz del curso y crea la carpeta de salida:

```bash
cd ~/linux-desde-cero
mkdir -p laboratorio
```

Trabajaremos únicamente con procesos que tú mismo inicies (`script_largo.sh` y `sleep`). No copies un PID de `top` para terminar procesos del sistema.

## Inspección con `ps`, `pgrep` y `top`

```bash
ps -o pid,ppid,user,stat,%cpu,%mem,comm -p "$$"
ps aux --sort=-%cpu | head
pgrep -a bash
top
```

- `PID`/`PPID`: proceso y padre.
- `STAT`: estado; `R` ejecutando, `S` esperando, `T` detenido, `Z` zombie.
- `pgrep -a`: PID y línea de comando.
- En `top`, presiona `P` para CPU, `M` para memoria y `q` para salir.

## 9.1 Background, señales, prioridad y `nohup`

### Trabajos del shell

`script_largo.sh` imprime una línea por segundo durante aproximadamente un minuto. `&` lo inicia sin bloquear la terminal.

```bash
bash script_largo.sh > laboratorio/proceso.log 2>&1 &
jobs -l
fg %1
```

`%1` significa “job número 1 de esta terminal”, no PID 1. Confirma el número real en la primera columna de `jobs -l`; si aparece `[2]`, usa `fg %2`.

Durante `fg`, presiona `Ctrl+Z` para suspender y luego:

```bash
bg %1
jobs -l
```

- `&`: inicia en background.
- `jobs`: trabajos del shell actual, no todos los procesos.
- `fg`/`bg`: reanuda en foreground/background.
- `Ctrl+Z`: suspende; no termina.

### Señales y `kill`

En este bloque, `sleep 300 &` crea el proceso y `$!` entrega exactamente su PID. La variable `pid` no existe antes de la segunda línea; nosotros la definimos con `pid=$!`.

```bash
sleep 300 &
pid=$!
kill -TERM "$pid"
wait "$pid" 2>/dev/null || true
```

- `$!`: PID del último proceso en background.
- `TERM` solicita cierre ordenado y es la primera opción.
- `KILL` no puede manejarse ni limpiar recursos; úsala sólo si `TERM` no funciona.
- `wait`: espera y recoge el estado del proceso hijo.

### Prioridad

Volvemos a crear un `sleep` independiente. La variable `pid` se reemplaza con el PID nuevo, por eso `renice` y `kill` sólo afectan este proceso de práctica.

```bash
nice -n 10 sleep 60 &
pid=$!
ps -o pid,ni,comm -p "$pid"
renice 15 -p "$pid"
kill "$pid"
```

Un valor nice mayor concede menos prioridad de CPU. Aumentar prioridad suele requerir privilegios.

### Persistencia con `nohup`

```bash
nohup bash script_largo.sh > laboratorio/nohup.log 2>&1 &
echo "$!" > laboratorio/nohup.pid
```

`nohup` ignora SIGHUP, pero no convierte el proceso en servicio. Para cargas operativas se prefiere un supervisor o unidad systemd.

El comando guarda el PID en `laboratorio/nohup.pid`. Al terminar la demostración, limpia el proceso de forma controlada:

```bash
pid=$(cat laboratorio/nohup.pid)
if kill -0 "$pid" 2>/dev/null; then
  kill -TERM "$pid"
else
  echo "El proceso ya había terminado"
fi
wait "$pid" 2>/dev/null || true
```

`kill -0` no termina el proceso: sólo comprueba si existe y si tienes permiso para señalarlo. `wait` sólo funciona si sigue siendo hijo del shell actual; el `|| true` tolera que ya haya terminado.

## 9.2 Medición con `time`

```bash
time grep -c 'ERROR' data/dummy_logs.txt
```

- `real`: tiempo de pared.
- `user`: CPU en espacio de usuario.
- `sys`: CPU dentro del kernel.

## 9.3 `top` y recursos

```bash
free -h
uptime
df -h /
```

La carga no es un porcentaje. Debe interpretarse con cantidad de CPU, procesos bloqueados y contexto del sistema.

## Servicios y logs con systemd

En Ubuntu 24.04:

```bash
systemctl status ssh --no-pager
systemctl is-enabled ssh
journalctl -u ssh --since '30 minutes ago' --no-pager
```

- `status`: estado y mensajes recientes.
- `is-enabled`: si inicia automáticamente; no indica necesariamente que esté activo.
- `journalctl -u`: filtra una unidad.
- `--since`: limita el periodo.
- `--no-pager`: salida no interactiva, útil en scripts y clases.

Si aparece `Unit ssh.service could not be found`, el servidor OpenSSH no está instalado en ese equipo. En la EC2 del curso debe existir porque es el servicio que permite la conexión inicial.

No reinicies servicios compartidos sin autorización.

## Práctica guiada resuelta — Ciclo de un proceso

No debes sustituir `$pid` manualmente. La línea `pid=$!` captura el PID del `sleep` que acaba de arrancar y todas las señales posteriores usan ese mismo valor.

```bash
mkdir -p laboratorio
sleep 120 &
pid=$!
printf 'PID=%s\n' "$pid" | tee laboratorio/proceso.pid
ps -o pid,ppid,stat,ni,etime,comm -p "$pid"
kill -STOP "$pid"
ps -o pid,stat,comm -p "$pid"
kill -CONT "$pid"
kill -TERM "$pid"
wait "$pid" 2>/dev/null || true
ps -p "$pid" || printf 'Proceso finalizado\n'
```

`STOP` suspende, `CONT` reanuda y `TERM` solicita terminar. La práctica usa un proceso creado por el propio alumno.

La columna `STAT` debe contener `T` después de `STOP`. Al final se imprime `Proceso finalizado`.

## Errores frecuentes

- Ejecutar `kill -9` como primera respuesta.
- Confundir PID con número de job `%1`.
- Cerrar la terminal creyendo que `&` garantiza persistencia.
- Reiniciar un servicio sin revisar logs.

## Reto 9 — Operación observable

[Ver respuesta](instructor/soluciones.md#respuesta-reto-9)

Trabaja dentro de `laboratorio/reto9`. Ejecuta `script_largo.sh` en background, guarda salida/errores en `proceso.log` y el PID en `proceso.pid`. Demuestra que está activo, mide otra ejecución corta y termina el proceso limpiamente. Guarda el estado del servicio SSH en `ssh-status.txt`.

### Criterios de comprobación

- PID y log se conservan en archivos.
- Se usa `TERM` antes de cualquier señal forzada.
- El reporte distingue proceso, job y servicio.
- Al final el PID ya no existe.

## Checklist

- [ ] Identifico PID, PPID, estado y prioridad.
- [ ] Controlo jobs con `jobs`, `fg` y `bg`.
- [ ] Uso señales de manera gradual.
- [ ] Consulto servicios y journal sin modificarlos.
