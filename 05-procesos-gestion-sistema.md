# 5. Procesos y gestión del sistema

## Objetivos

Al terminar este capítulo podrás:

- distinguir programa, proceso, job y servicio;
- localizar procesos por PID, usuario o nombre sin depender de `top`;
- suspender, reanudar y terminar de forma gradual un proceso creado por ti;
- interpretar CPU, memoria, carga y prioridad sin confundir sus unidades;
- consultar el estado y los logs de un servicio administrado por systemd.

## Contexto y directorio inicial

Ejecuta este capítulo **dentro de la EC2 Ubuntu 24.04**, conectado como el
usuario administrativo `ubuntu`. No elijas PIDs al azar: todas las señales de
la práctica se enviarán a un `sleep` que tú mismo iniciarás.

```bash
LAB="$HOME/consultor-linux-lab/modulo-05"
mkdir -p "$LAB"
cd "$LAB"
printf 'Directorio de trabajo: %s\n' "$PWD"
```

En una instalación normal la última línea contiene algo similar a:

```text
Directorio de trabajo: /home/ubuntu/consultor-linux-lab/modulo-05
```

`$HOME` se resuelve para el usuario actual; no copies `/home/ubuntu` si tu
usuario tiene otro nombre.

## Modelo mental: programa, proceso, job y servicio

```text
archivo ejecutable o script
           |
           | se ejecuta
           v
proceso (PID, PPID, usuario, estado y recursos)
           |
           +-- job: proceso controlado por este shell (`jobs`, `fg`, `bg`)
           |
           `-- servicio: proceso supervisado por systemd (`systemctl`)
```

- Un **programa** es código almacenado, por ejemplo `/usr/bin/sleep`.
- Un **proceso** es una ejecución del programa y tiene un PID.
- Un **job** es la referencia que el shell actual asigna a una tarea. `%1` es
  un número de job; no es el PID 1.
- Un **servicio** tiene ciclo de vida, dependencias y logs gestionados por un
  supervisor. Ejecutar algo con `&` no lo convierte en servicio.

Cada proceso, excepto los primeros del arranque, tiene un padre. El shell que
estás usando también es un proceso:

```bash
ps -o pid,ppid,user,stat,ni,%cpu,%mem,etime,comm -p "$$"
```

Salida representativa:

```text
    PID    PPID USER     STAT  NI %CPU %MEM     ELAPSED COMMAND
   2418    2417 ubuntu   Ss     0  0.0  0.2       03:12 bash
```

Los números cambiarán. `$$` es el PID del Bash actual; `PPID` identifica a su
padre; `STAT=S` indica espera interrumpible y `NI=0` la prioridad normal.

## Inspeccionar procesos

### Sintaxis parametrizada

```text
ps -o <columnas> -p <PID>
pgrep -a -u <usuario> <patron_nombre>
```

| Parámetro | Ejemplo | Significado |
|---|---|---|
| `<columnas>` | `pid,ppid,stat,etime,comm` | campos que mostrará `ps` |
| `<PID>` | `2418` | identificador numérico de un proceso |
| `<usuario>` | `ubuntu` | propietario del proceso |
| `<patron_nombre>` | `bash` | nombre del ejecutable, no toda la línea |

Ejemplo copiable que se adapta a tu sesión:

```bash
ps -o pid,ppid,user,stat,ni,%cpu,%mem,etime,comm -p "$$"
pgrep -a -u "$USER" bash
ps -u "$USER" -o pid,ppid,stat,ni,%cpu,%mem,etime,comm --sort=-%cpu \
  | head -n 8
```

Flags y campos relevantes:

- `-o`: selecciona y ordena columnas;
- `-p`: filtra un PID; `-u`: filtra usuario;
- `pgrep -a`: imprime PID y argumentos; `-u`: restringe el propietario;
- `R`: ejecutándose; `S`: esperando; `T`: detenido; `Z`: zombie;
- `ETIME`: tiempo transcurrido; `%CPU` y `%MEM`: consumo observado.

`ps` es una fotografía. Para una vista que se actualiza, usa `top`; presiona
`P` para ordenar por CPU, `M` por memoria y `q` para salir. `htop` es opcional
y puede no venir instalado.

## Jobs: foreground y background

### Sintaxis parametrizada

```text
<comando> &
jobs -l
fg %<numero_job>
bg %<numero_job>
```

No copies los marcadores. Este ejemplo crea un proceso inofensivo:

```bash
sleep 300 &
PID_LAB=$!
printf '%s\n' "$PID_LAB" > "$LAB/sleep.pid"
jobs -l
```

Salida representativa:

```text
[1] 2864
[1]+  2864 Running                 sleep 300 &
```

- `&` devuelve el control al shell;
- `$!` contiene el PID del último proceso iniciado en background;
- `[1]` es el job de **esta terminal** y `2864` es el PID;
- `jobs -l` no lista procesos de otras terminales ni servicios.

Para practicar de forma interactiva, usa el número que realmente muestre
`jobs -l`:

```bash
fg %1
```

Mientras `sleep` esté en foreground, presiona `Ctrl+Z`. Esto envía `TSTP` y lo
suspende; no lo termina. Después ejecuta:

```bash
bg %1
jobs -l
```

Si tu shell muestra `[2]`, debes usar `%2`. El resto del capítulo utiliza el
PID guardado y no depende del número de job.

## Señales y terminación gradual

### Sintaxis parametrizada

```text
kill -<SENAL> <PID>
kill -0 <PID>
```

| Señal | Propósito | Uso recomendado |
|---|---|---|
| `TERM` (15) | solicitar cierre ordenado | primera opción |
| `INT` (2) | interrupción, como `Ctrl+C` | programas interactivos |
| `STOP` (19) | suspender; no puede ignorarse | diagnóstico breve |
| `CONT` (18) | reanudar un proceso detenido | después de `STOP` |
| `KILL` (9) | terminar sin limpieza | último recurso |

`kill -0` **no termina nada**: comprueba que el proceso existe y que tienes
permiso para enviarle señales.

Ejemplo copiable, independiente del ejercicio de jobs:

```bash
sleep 300 &
pid=$!
kill -0 "$pid" && printf 'Activo: PID %s\n' "$pid"
kill -TERM "$pid"
wait "$pid" 2>/dev/null || true
kill -0 "$pid" 2>/dev/null || printf 'Proceso finalizado\n'
```

La salida debe confirmar primero el PID y terminar con `Proceso finalizado`.
`wait` recoge el estado del hijo; `|| true` tolera el estado distinto de cero
producido por la señal.

## Prioridad, recursos y tiempo

Un valor **nice mayor** concede menos prioridad de CPU. Un usuario normal puede
reducir la prioridad de su propio proceso, pero normalmente no aumentarla.

```bash
nice -n 10 sleep 120 &
pid=$!
ps -o pid,ni,stat,comm -p "$pid"
renice 15 -p "$pid"
ps -o pid,ni,stat,comm -p "$pid"
kill -TERM "$pid"
wait "$pid" 2>/dev/null || true
```

`nice -n 10` inicia con `NI=10`; `renice 15 -p` cambia un proceso existente. La
segunda consulta debe mostrar `NI=15`.

Observa el sistema sin modificarlo:

```bash
nproc
uptime
free -h
df -hT /
time grep -c '^processor' /proc/cpuinfo
```

- `nproc`: CPU lógicas disponibles;
- `uptime`: tiempo encendido y promedios de carga de 1, 5 y 15 minutos;
- `free -h`: memoria y swap; `available` es más útil que interpretar `free`
  aisladamente;
- `df -hT /`: capacidad del sistema de archivos raíz;
- `time`: tiempo real (`real`) y CPU en usuario/kernel (`user`, `sys`).

La carga no es un porcentaje. Interprétala junto con `nproc`, procesos
ejecutables o bloqueados y el contexto de la instancia.

## Servicios y logs con systemd

### Sintaxis parametrizada

```text
systemctl status <unidad> --no-pager
systemctl is-active <unidad>
journalctl -u <unidad> --since <periodo> --no-pager
```

En la EC2, `ssh.service` es la unidad que mantiene tu conexión. Aquí sólo la
consultaremos; **no la reinicies durante una conexión remota**.

```bash
SERVICIO=ssh
systemctl is-active "$SERVICIO"
systemctl status "$SERVICIO" --no-pager -l | sed -n '1,12p'
sudo journalctl -u "$SERVICIO" --since '30 minutes ago' \
  --no-pager -n 20
```

Salida principal esperada:

```text
active
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (...; enabled; ...)
     Active: active (running) ...
```

- `is-active` responde al estado actual;
- `is-enabled` indica si arranca automáticamente: no significa que esté activo;
- `-u` filtra la unidad; `--since` acota tiempo; `-n` limita líneas;
- `--no-pager` evita una interfaz interactiva en comandos reproducibles.

Si `ssh.service` no existe, comprueba `systemctl status sshd`; en Ubuntu el
nombre habitual es `ssh`, mientras otras distribuciones usan `sshd`.

## Verificación y reversión

Antes de terminar, limpia exclusivamente los PIDs registrados por el
laboratorio:

```bash
if [[ -r "$LAB/sleep.pid" ]]; then
  pid=$(<"$LAB/sleep.pid")
  if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
    kill -TERM "$pid"
    wait "$pid" 2>/dev/null || true
  fi
fi
jobs -l
```

`jobs -l` no debe mostrar ningún `sleep` de la práctica. Conserva el directorio
como evidencia; para vaciar sólo este módulo:

```bash
EXPECTED_LAB="$HOME/consultor-linux-lab/modulo-05"
if [[ $(realpath --canonicalize-missing "$LAB") == "$EXPECTED_LAB" ]]; then
  find "$LAB" -mindepth 1 -delete
else
  printf 'Limpieza cancelada: LAB no es %s\n' "$EXPECTED_LAB" >&2
fi
```

## Práctica guiada resuelta: ciclo de vida observable

El bloque crea un proceso, registra su identidad, demuestra tres estados y lo
termina limpiamente. No reemplaces `$pid`: Bash lo obtiene de `$!`.

```bash
cd "$LAB"
sleep 180 &
pid=$!
printf 'PID=%s\n' "$pid" | tee proceso.pid

ps -o pid,ppid,user,stat,ni,etime,comm -p "$pid" \
  | tee estado-inicial.txt

kill -STOP "$pid"
ps -o pid,stat,comm -p "$pid" | tee estado-detenido.txt

kill -CONT "$pid"
kill -TERM "$pid"
wait "$pid" 2>/dev/null || true

if kill -0 "$pid" 2>/dev/null; then
  printf 'ERROR: el proceso sigue activo\n' >&2
  exit 1
else
  printf 'OK: PID %s finalizado\n' "$pid" | tee estado-final.txt
fi
```

La columna `STAT` de `estado-detenido.txt` debe contener `T`. La última salida
debe comenzar con `OK`. Los tres archivos permiten reconstruir lo ocurrido sin
depender del historial de la terminal.

## Fallo controlado: una unidad inexistente

Ejecuta una consulta que fallará a propósito; no modifica systemd:

```bash
if systemctl is-active servicio-que-no-existe.service \
    > "$LAB/fallo-servicio.out" 2> "$LAB/fallo-servicio.err"; then
  printf 'Resultado inesperado\n'
else
  estado=$?
  printf 'Fallo esperado; estado=%s\n' "$estado"
  cat "$LAB/fallo-servicio.out" "$LAB/fallo-servicio.err"
fi
```

La respuesta habitual es `inactive` o `unknown`, con estado distinto de cero.
La lección es que una automatización debe evaluar el estado de salida, no buscar
sólo una palabra visualmente.

## Reto 5: informe de operación observable

Trabaja en `$LAB/reto-05`. Inicia un `sleep 240` en background, conserva PID y
estado inicial, suspéndelo con una señal, demuestra el estado `T`, reanúdalo y
termínalo con `TERM`. Genera además `sistema.txt` con CPU, memoria, carga y el
estado actual de SSH. No uses `kill -9` ni selecciones procesos ajenos.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-5)

### Criterios de éxito

- `proceso.pid` contiene sólo un PID numérico creado por el alumno;
- una evidencia muestra `STAT=T` y al final `kill -0` confirma que ya no existe;
- `sistema.txt` distingue CPU, memoria, carga y estado del servicio;
- los mensajes de error se conservan y ningún servicio fue reiniciado.

## Checklist

- [ ] Distingo programa, proceso, job y servicio.
- [ ] Puedo explicar PID, PPID, `STAT`, nice, CPU y memoria.
- [ ] Capturo `$!` en vez de copiar un PID de otra herramienta.
- [ ] Uso `TERM` antes de considerar `KILL`.
- [ ] Consulto una unidad y sus logs sin modificarla.
- [ ] Verifiqué que no quedaron procesos del laboratorio.
