# 7. Shell y automatización básica

## Objetivos

Al terminar este capítulo podrás:

- explicar qué hace un shell y distinguirlo de la terminal;
- combinar comandos con redirecciones, tuberías y operadores condicionales;
- separar datos (`stdout`) de diagnósticos (`stderr`);
- citar variables y rutas para evitar divisiones o expansiones accidentales;
- convertir una secuencia probada en un script Bash sencillo.

## Contexto y directorio inicial

Ejecuta todo **dentro de EC2** como `ubuntu`. Este módulo crea su propio log;
no depende de archivos de otros capítulos ni modifica `/var/log`.

```bash
LAB="$HOME/consultor-linux-lab/modulo-07"
mkdir -p "$LAB"
cd "$LAB"

tee servicio.log > /dev/null <<'LOG'
2026-07-11T09:00:00Z INFO api inicio correcto
2026-07-11T09:01:10Z WARN disco uso=82
2026-07-11T09:02:20Z ERROR db conexion_rechazada
2026-07-11T09:02:25Z INFO api reintento
2026-07-11T09:03:00Z ERROR api timeout
LOG

wc -l servicio.log
```

Salida esperada:

```text
5 servicio.log
```

`LAB` es una variable de esta terminal. Si cierras la sesión, vuelve a ejecutar
las primeras tres líneas antes de continuar.

## Modelo mental: terminal, shell y comandos

```text
persona
  |
  v
terminal (ventana o conexión SSH: presenta entrada y salida)
  |
  v
shell (Bash: interpreta sintaxis, variables, pipes y redirecciones)
  |
  +-- builtin: cd, read, type
  `-- ejecutable: /usr/bin/grep, /usr/bin/sort
```

La terminal transporta caracteres; el shell entiende el lenguaje de comandos.
Cerrar la aplicación de terminal no es lo mismo que ejecutar `exit` en el shell,
aunque ambas acciones suelen terminar la sesión.

Comprueba tu entorno:

```bash
printf 'Shell configurado: %s\n' "$SHELL"
printf 'Proceso actual: '
ps -p "$$" -o comm=
type cd
type grep
getent passwd "$USER" | cut -d: -f1,7
```

Salida representativa:

```text
Shell configurado: /bin/bash
Proceso actual: bash
cd is a shell builtin
grep is /usr/bin/grep
ubuntu:/bin/bash
```

`$SHELL` indica el shell configurado al iniciar sesión; `ps ... "$$"` muestra
el proceso actual. Pueden diferir si abriste manualmente `sh`, `zsh` u otro
shell. Los scripts del curso declaran Bash porque usan construcciones de Bash.

### Bash frente a otras shells

Una shell interactiva y el intérprete de un script no tienen por qué ser el
mismo programa:

| Shell | Uso habitual | Compatibilidad relevante |
|---|---|---|
| Bash | predeterminada del curso y frecuente en servidores Linux | admite `[[ ]]`, arrays y `set -o pipefail` |
| `dash`/`sh` | scripts POSIX pequeños; en Ubuntu `/bin/sh` suele apuntar a Dash | no admite todas las construcciones de Bash |
| Zsh | shell interactiva con ayudas y expansión propias | se parece a Bash, pero no es idéntica |
| Fish | experiencia interactiva amigable | su sintaxis deliberadamente no es POSIX/Bash |

Compruébalo sin cambiar tu shell:

```bash
readlink -f /bin/sh
bash --version | head -n 1
command -v dash zsh fish 2>/dev/null || true
head -n 1 "$LAB/resumen-basico.sh" 2>/dev/null || \
  printf 'El script se creará más adelante y declarará Bash\n'
```

Una salida normal en Ubuntu comienza con `/usr/bin/dash` y `GNU bash, versión
5...`; Zsh o Fish sólo aparecen si están instaladas. El *shebang*
`#!/usr/bin/env bash` del script decide su intérprete al ejecutarlo directamente.
No uses `sh script.sh` con un script Bash: ese comando ignora el shebang y puede
fallar aunque el archivo sea correcto.

## Sintaxis, expansiones y comillas

### Sintaxis parametrizada

```text
<comando> [opciones] <argumento>
<comando> "$<variable>"
```

Ejemplo general de búsqueda:

```text
grep -En '<expresion>' <archivo>
```

No copies los marcadores. Valores concretos del laboratorio:

```bash
PATRON='WARN|ERROR'
ARCHIVO="$LAB/servicio.log"
grep -En "$PATRON" "$ARCHIVO"
```

Salida esperada:

```text
2:2026-07-11T09:01:10Z WARN disco uso=82
3:2026-07-11T09:02:20Z ERROR db conexion_rechazada
5:2026-07-11T09:03:00Z ERROR api timeout
```

- `-E`: expresiones regulares extendidas; `|` significa alternancia;
- `-n`: agrega el número de línea;
- `"$PATRON"`: entrega el contenido como un solo argumento;
- `"$ARCHIVO"`: protege rutas con espacios y evita expansión de comodines.

Comillas y expansiones importantes:

| Escritura | Comportamiento |
|---|---|
| `'texto $USER'` | texto literal; no expande variables |
| `"texto $USER"` | expande variables, pero conserva un argumento |
| `$(comando)` | sustituye por `stdout` del comando |
| `*.log` sin comillas | el shell expande nombres coincidentes |

```bash
fecha=$(date --iso-8601=seconds)
printf 'usuario=%s fecha=%s\n' "$USER" "$fecha"
```

`printf` es preferible para formatos reproducibles; `%s` recibe los argumentos
en el orden indicado.

## Entrada, salida y errores

Al comenzar, todo proceso recibe tres descriptores:

| Descriptor | Nombre | Destino normal |
|---:|---|---|
| `0` | `stdin` | teclado o salida anterior |
| `1` | `stdout` | terminal o siguiente comando |
| `2` | `stderr` | terminal, separado de los datos |

Operadores:

| Operador | Acción |
|---|---|
| `>` | crea o sobrescribe `stdout` |
| `>>` | agrega `stdout` al final |
| `<` | usa un archivo como `stdin` |
| `2>` | redirige `stderr` |
| `2>&1` | conecta `stderr` al destino actual de `stdout` |
| `|` | conecta `stdout` izquierdo con `stdin` derecho |

Ejemplo copiable:

```bash
printf '%s\n' alfa beta gamma > "$LAB/entrada.txt"
wc -l < "$LAB/entrada.txt" > "$LAB/conteo.txt"

ls /etc/hosts /ruta-que-no-existe \
  > "$LAB/encontrados.txt" \
  2> "$LAB/errores.txt" || true

cat "$LAB/conteo.txt"
cat "$LAB/encontrados.txt"
cat "$LAB/errores.txt"
```

`conteo.txt` contiene sólo `3` porque, al recibir entrada con `<`, `wc` no
recibe un nombre para imprimir. `/etc/hosts` queda en `encontrados.txt` y el
diagnóstico de la ruta falsa en `errores.txt`. `|| true` se usa porque el fallo
es intencional; no debe ocultar errores reales indiscriminadamente.

El orden importa:

```bash
ls /etc/hosts /ruta-que-no-existe > "$LAB/salida-completa.log" 2>&1 || true
```

Primero `stdout` se conecta al archivo; después `2>&1` conecta `stderr` al mismo
destino.

## Tuberías y `tee`

### Sintaxis parametrizada

```text
<productor> | <filtro> | tee <archivo> | <agregador>
```

Ejemplo resuelto:

```bash
grep -E 'WARN|ERROR' "$LAB/servicio.log" \
  | sort \
  | tee "$LAB/incidentes.txt" \
  | wc -l
```

Salida esperada: `3`. `tee` duplica su entrada: guarda las tres líneas y
además las entrega a `wc`. `tee -a` agrega; sin `-a`, sobrescribe.

Prueba cada etapa antes de construir un pipeline largo. Por defecto, el estado
del pipeline es el del último comando. En automatización se habilita
`pipefail` para detectar fallos en etapas anteriores:

```bash
set -o pipefail
grep -E 'WARN|ERROR' "$LAB/servicio.log" | wc -l
```

## Encadenamiento condicional

| Operador | Ejecuta el comando derecho... |
|---|---|
| `;` | siempre |
| `&&` | sólo si el izquierdo termina con estado 0 |
| `||` | sólo si el izquierdo termina con estado distinto de 0 |

```bash
test -s "$LAB/servicio.log" \
  && cp "$LAB/servicio.log" "$LAB/servicio.copia.log" \
  && printf 'Copia creada\n' \
  || printf 'No se pudo crear la copia\n' >&2
```

`test -s` comprueba que el archivo existe y no está vacío. La copia se intenta
sólo después de una validación exitosa.

## Primera automatización

El script recibe un log; no contiene una ruta fija. Copia el bloque completo:

```bash
tee "$LAB/resumen-basico.sh" > /dev/null <<'BASH'
#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
  printf 'Uso: %s <archivo-log>\n' "$0" >&2
  exit 64
fi

log=$1
if [[ ! -r "$log" ]]; then
  printf 'Error: no puedo leer %s\n' "$log" >&2
  exit 66
fi

printf 'Host: %s\n' "$(hostname)"
printf 'Archivo: %s\n' "$log"
printf 'WARN: %s\n' "$(grep -c ' WARN ' "$log" || true)"
printf 'ERROR: %s\n' "$(grep -c ' ERROR ' "$log" || true)"
BASH

chmod 750 "$LAB/resumen-basico.sh"
"$LAB/resumen-basico.sh" "$LAB/servicio.log"
```

Salida principal:

```text
Host: [nombre variable]
Archivo: /home/[usuario]/consultor-linux-lab/modulo-07/servicio.log
WARN: 1
ERROR: 2
```

- `#!/usr/bin/env bash`: selecciona Bash al ejecutar directamente;
- `$#`: cantidad de argumentos; `$0`: nombre del script; `$1`: primer argumento;
- `[[ -r ... ]]`: comprueba lectura;
- `>&2`: envía el mensaje de error a `stderr`;
- `exit 64/66`: diferencia uso incorrecto de entrada ilegible.

El `|| true` está limitado a `grep -c`: `grep` devuelve 1 cuando encuentra
cero coincidencias, una situación válida para este reporte.

## Verificación y reversión

Comprueba sintaxis, permisos y resultados:

```bash
bash -n "$LAB/resumen-basico.sh"
test -x "$LAB/resumen-basico.sh" && printf 'Script ejecutable\n'
test "$(wc -l < "$LAB/incidentes.txt")" -eq 3 \
  && printf 'Conteo correcto\n'
```

`bash -n` analiza sin ejecutar. Para rehacer el módulo conserva
`servicio.log` y elimina sólo resultados conocidos:

```bash
rm -f -- "$LAB"/{conteo.txt,encontrados.txt,errores.txt,salida-completa.log}
rm -f -- "$LAB"/{incidentes.txt,servicio.copia.log,resumen-basico.sh}
```

## Práctica guiada resuelta: reporte auditable

El reporte conserva datos, errores y resumen por separado:

```bash
cd "$LAB"
(
  set -o pipefail
  grep -En 'WARN|ERROR' servicio.log 2> reporte.err \
    | tee reporte-incidentes.txt \
    | awk '{conteo++} END {printf "Total de incidentes: %d\n", conteo}' \
    > resumen.txt
)
estado=$?

printf 'Estado del pipeline: %s\n' "$estado"
cat resumen.txt
wc -l reporte-incidentes.txt reporte.err
```

Salida esperada:

```text
Estado del pipeline: 0
Total de incidentes: 3
  3 reporte-incidentes.txt
  0 reporte.err
  3 total
```

Los espacios de `wc` pueden variar. El subshell `( ... )` limita `pipefail` a
la práctica. Si `grep` no puede leer el archivo, el estado deja de ser cero
aunque `awk` se ejecute.

## Fallo controlado: un pipeline que oculta el error

```bash
set +o pipefail
grep ERROR "$LAB/no-existe.log" 2> "$LAB/sin-pipefail.err" | wc -l \
  > "$LAB/sin-pipefail.txt"
estado_sin=$?

set -o pipefail
estado_con=0
grep ERROR "$LAB/no-existe.log" 2> "$LAB/con-pipefail.err" | wc -l \
  > "$LAB/con-pipefail.txt" || estado_con=$?
set +o pipefail

printf 'Sin pipefail=%s | Con pipefail=%s\n' "$estado_sin" "$estado_con"
```

La salida debe mostrar `Sin pipefail=0` y `Con pipefail=2`. En el primer caso,
`wc` contó cero líneas correctamente y ocultó que `grep` no pudo abrir la
entrada. `pipefail` preserva ese diagnóstico para la automatización.

## Reto 7: pipeline de incidentes reutilizable

Trabaja en `$LAB/reto-07`. A partir de `servicio.log`, crea `incidentes.txt`
con las líneas `WARN` o `ERROR`, `componentes.txt` con la tercera columna
ordenada y sin duplicados, `resumen.txt` con los conteos por nivel y
`errores.log` para `stderr`. La solución debe usar al menos una variable, una
tubería, `tee`, `&&` y `pipefail`; no edites manualmente los resultados.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-7)

### Criterios de éxito

- `incidentes.txt` tiene 3 líneas y `componentes.txt` contiene `api`, `db` y
  `disco` una sola vez;
- `resumen.txt` informa `WARN=1` y `ERROR=2`;
- una entrada inexistente produce estado distinto de cero y un error legible;
- el fixture `servicio.log` permanece sin cambios.

## Checklist

- [ ] Distingo terminal, shell, builtin y ejecutable.
- [ ] Cito variables y entiendo cuándo el shell expande texto.
- [ ] Separo `stdout` y `stderr`.
- [ ] Uso `|`, `tee`, `&&`, `||` y `pipefail` intencionalmente.
- [ ] Valido antes de copiar o procesar.
- [ ] Convierto una secuencia probada en un script sencillo.
