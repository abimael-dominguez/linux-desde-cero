# 8. Bash y automatización con cron

## Objetivos

Al terminar este capítulo podrás:

- escribir scripts Bash con argumentos, comillas, funciones y estados de salida;
- elegir entre `if`, `for` y `case` según el problema;
- validar rutas antes de leer, crear o reemplazar archivos;
- producir y restaurar un respaldo comprimido con verificación SHA-256;
- preparar, probar, instalar y revertir una tarea cron sin perder entradas previas.

## Contexto y directorio inicial

Ejecuta este módulo **en EC2** como `ubuntu`. El respaldo opera sólo sobre
datos de laboratorio en tu `HOME`; no lee `/etc`, no usa S3 y no crea snapshots
de AWS.

```bash
LAB="$HOME/consultor-linux-lab/modulo-08"
mkdir -p "$LAB"/{origen/{config,datos},respaldos,restauracion,logs}
cd "$LAB"

printf 'APP_ENV=production\nPORT=8080\n' > origen/config/app.env
printf 'pedido,total\n1001,250.00\n1002,175.50\n' > origen/datos/pedidos.csv
chmod 600 origen/config/app.env
find origen -type f -printf '%M %p\n'
```

El último comando debe listar dos archivos. Todas las rutas usadas por el
script se recibirán como argumentos; `origen` y `respaldos` son los valores
concretos de esta práctica.

## Modelo mental: una automatización operable

```text
entrada explícita
      |
      v
validar argumentos, tipo, permisos y relación entre rutas
      |
      v
trabajar en temporal --(verificar)--> publicar resultado final
      |                                  |
      `-- fallo: limpiar temporal         `-- estado 0 + evidencia
```

Un script profesional no es sólo una lista de comandos. También define:

- contrato de entrada y mensaje de uso;
- qué considera éxito o fallo;
- salidas de datos y diagnóstico;
- idempotencia o nombres que evitan sobrescrituras;
- verificación y forma de revertir.

## Anatomía y ejecución

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

- el **shebang** selecciona Bash al ejecutar el archivo directamente;
- `-E`: hereda el trap `ERR` en funciones, cuando se use;
- `-e`: detiene errores no tratados; no reemplaza validaciones;
- `-u`: una variable no definida es error;
- `pipefail`: un pipeline falla si falla cualquiera de sus etapas.

Sintaxis de ejecución:

```text
bash <script> <argumento_1> <argumento_2>
chmod <modo> <script>
<ruta_script> <argumento_1> <argumento_2>
```

Ejemplo concreto que se completará enseguida:

```bash
bash "$LAB/respaldo.sh" "$LAB/origen" "$LAB/respaldos"
```

| Expresión | Significado |
|---|---|
| `$0` | nombre usado para invocar el script |
| `$1`, `$2` | primer y segundo argumento |
| `$#` | cantidad de argumentos |
| `"$@"` | todos los argumentos conservando sus límites |
| `$?` | estado del comando anterior |
| `$$` | PID del shell actual |

Estado `0` significa que se cumplió el contrato; otro valor identifica un
fallo. Este capítulo usa `64` para uso incorrecto, `66` para entrada ausente y
`73` cuando no puede crear una salida.

## Estructuras de control

### `if`: decidir a partir de un estado

Sintaxis parametrizada:

```text
if <comando_o_prueba>; then
  <camino_exitoso>
else
  <camino_alternativo>
fi
```

Ejemplo copiable:

```bash
if [[ -r "$LAB/origen/config/app.env" ]]; then
  printf 'Configuración legible\n'
else
  printf 'Configuración ausente\n' >&2
fi
```

`[[ -r ... ]]` comprueba lectura. Para directorios que se recorrerán conviene
comprobar además `-d` y `-x`.

### `for`: repetir sobre una lista delimitada

```bash
for archivo in "$LAB"/origen/config/* "$LAB"/origen/datos/*; do
  [[ -f "$archivo" ]] || continue
  printf '%s | %s bytes\n' "$(basename "$archivo")" "$(stat -c %s "$archivo")"
done
```

Las comillas protegen cada ruta después de la expansión. No uses
`for archivo in $(find ...)`: la sustitución divide nombres con espacios.

### `while`: repetir con un límite explícito

`while` repite mientras un comando o condición termine en estado `0`. En
operación, todo sondeo debe tener máximo de intentos y una pausa para evitar un
bucle infinito que consuma CPU:

```bash
intento=1
max_intentos=3

while (( intento <= max_intentos )); do
  if [[ -s "$LAB/origen/config/app.env" ]]; then
    printf 'Configuración disponible en el intento %d\n' "$intento"
    break
  fi

  printf 'Intento %d sin resultado; se reintentará\n' "$intento" >&2
  intento=$((intento + 1))
  sleep 1
done

(( intento <= max_intentos )) || {
  printf 'La configuración no apareció a tiempo\n' >&2
  exit 1
}
```

En este laboratorio el archivo ya existe, por lo que termina en el primer
intento. La misma forma se reutiliza para esperar un servicio o health check.

### `case`: seleccionar variantes conocidas

```bash
ACCION=verificar
case "$ACCION" in
  crear)     printf 'Se crearía el respaldo\n' ;;
  verificar) printf 'Se verificaría el hash\n' ;;
  restaurar) printf 'Se restauraría en otra carpeta\n' ;;
  *)         printf 'Acción no válida: %s\n' "$ACCION" >&2; exit 64 ;;
esac
```

`;;` termina cada alternativa. `*` es el caso por defecto.

## Script resuelto: respaldo robusto

Copia el bloque completo. El script:

1. valida dos argumentos;
2. rechaza un destino ubicado dentro del origen para evitar recursión;
3. crea primero un archivo temporal;
4. valida gzip antes de publicar;
5. genera un hash junto al archivo final;
6. limpia el temporal aun si se interrumpe.

```bash
tee "$LAB/respaldo.sh" > /dev/null <<'BASH'
#!/usr/bin/env bash
set -Eeuo pipefail

readonly EX_USAGE=64
readonly EX_NOINPUT=66
readonly EX_CANTCREAT=73

mostrar_uso() {
  printf 'Uso: %s <directorio-origen> <directorio-destino>\n' "$0" >&2
}

if [[ $# -ne 2 ]]; then
  mostrar_uso
  exit "$EX_USAGE"
fi

origen=$1
destino=$2

if [[ ! -d "$origen" || ! -r "$origen" || ! -x "$origen" ]]; then
  printf 'Error: el origen no es un directorio accesible: %s\n' "$origen" >&2
  exit "$EX_NOINPUT"
fi

origen_abs=$(realpath -- "$origen")
destino_abs=$(realpath -m -- "$destino")

case "$destino_abs/" in
  "$origen_abs/"*)
    printf 'Error: el destino no puede estar dentro del origen\n' >&2
    exit "$EX_CANTCREAT"
    ;;
esac

if ! mkdir -p -- "$destino_abs"; then
  printf 'Error: no pude crear el destino: %s\n' "$destino_abs" >&2
  exit "$EX_CANTCREAT"
fi

marca=$(date -u +%Y%m%dT%H%M%SZ)
nombre_origen=$(basename -- "$origen_abs")
nombre="respaldo-${nombre_origen}-${marca}-$$.tar.gz"
temporal=''

limpiar() {
  if [[ -n "$temporal" && -e "$temporal" ]]; then
    rm -f -- "$temporal"
  fi
}
trap limpiar EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

temporal=$(mktemp --tmpdir="$destino_abs" ".${nombre}.XXXXXX")
tar -czf "$temporal" \
  --directory="$(dirname -- "$origen_abs")" \
  -- "$nombre_origen"
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

chmod 750 "$LAB/respaldo.sh"
bash -n "$LAB/respaldo.sh"
```

Flags y palabras clave:

- `readonly`: evita reasignar constantes por accidente;
- `realpath -m`: normaliza rutas aunque el destino todavía no exista;
- `mktemp --tmpdir`: crea un nombre exclusivo dentro del destino;
- `trap ... EXIT INT TERM`: ejecuta limpieza al salir o ser interrumpido;
- `tar -c -z -f`: crea, comprime con gzip y recibe nombre de archivo;
- `--directory`: cambia la base almacenada sin cambiar el shell;
- `--`: termina opciones; protege nombres que comiencen con `-`;
- `gzip -t`: valida la estructura comprimida;
- el subshell `( ... )` limita el `cd` al cálculo del hash.

## Práctica guiada resuelta: crear, verificar y restaurar

```bash
cd "$LAB"
ARCHIVO=$("$LAB/respaldo.sh" "$LAB/origen" "$LAB/respaldos")
printf 'Respaldo: %s\n' "$ARCHIVO"

test -s "$ARCHIVO" && test -s "$ARCHIVO.sha256" \
  && printf 'Archivos creados\n'

(
  cd "$(dirname -- "$ARCHIVO")"
  sha256sum -c "$(basename -- "$ARCHIVO").sha256"
)

tar -tzf "$ARCHIVO"
rm -rf -- "$LAB/restauracion/origen"
tar -xzf "$ARCHIVO" -C "$LAB/restauracion"
diff -ru "$LAB/origen" "$LAB/restauracion/origen"
printf 'Estado de comparación: %s\n' "$?"
```

Salida principal esperada:

```text
Archivos creados
respaldo-origen-[marca]-[PID].tar.gz: OK
origen/
origen/config/
...
Estado de comparación: 0
```

El nombre exacto cambia. Un hash correcto detecta corrupción accidental; no
demuestra por sí solo quién creó el respaldo. `diff` sin salida y estado 0
demuestra que la restauración coincide con el origen.

## Utilidades reutilizables del repositorio

Después de comprender y construir `respaldo.sh`, compara tu solución con las
utilidades mantenidas por el curso. Trabajan con dos argumentos, rechazan un
destino dentro del origen, usan permisos privados y exigen un destino vacío al
restaurar:

```bash
cd "$HOME/linux-desde-cero"
bash scripts/preparar-lab.sh

ORIGEN="$PWD/laboratorio/data/proyecto"
RESPALDOS="$PWD/laboratorio/backups/reutilizable"
RESTAURADO="$PWD/laboratorio/restaurado-reutilizable"

bash scripts/respaldar-directorio.sh "$ORIGEN" "$RESPALDOS"
ARCHIVO=$(find "$RESPALDOS" -maxdepth 1 -type f \
  -name 'respaldo-*.tar.gz' -print -quit)

bash scripts/restaurar-directorio.sh "$ARCHIVO" "$RESTAURADO"
diff -ru "$ORIGEN" "$RESTAURADO/proyecto"
stat -c '%a %n' "$RESPALDOS" "$ARCHIVO" "$ARCHIVO.sha256"
```

Se espera `700` en el directorio de respaldos, `600` en archivo y checksum, y
ninguna salida de `diff`. `restaurar-directorio.sh` calcula la ruta del checksum
agregando `.sha256`; por eso ambos archivos deben viajar juntos. Para repetir,
ejecuta otra vez `preparar-lab.sh`, sabiendo que regenera todo `laboratorio/`.

## Cron: programar después de probar

Cron usa cinco campos y después el comando:

```text
minuto hora día-del-mes mes día-de-semana comando
   0     3       *        *        *         tarea diaria a las 03:00
```

| Símbolo | Ejemplo | Significado |
|---|---|---|
| `*` | `* * * * *` | cualquier valor |
| `,` | `0,30 * * * *` | lista |
| `-` | `0 9 * * 1-5` | rango |
| `/` | `*/15 * * * *` | cada 15 unidades |

Cron tiene un entorno reducido: usa rutas absolutas, declara `PATH`, redirige
salida y evita ejecuciones concurrentes. `flock -n` salta una ejecución si la
anterior conserva el candado.

### Crear un candidato sin perder el crontab actual

```bash
if crontab -l > "$LAB/crontab.before" 2> "$LAB/crontab-l.err"; then
  printf 'si\n' > "$LAB/tenia-crontab"
else
  : > "$LAB/crontab.before"
  printf 'no\n' > "$LAB/tenia-crontab"
fi

{
  cat "$LAB/crontab.before"
  printf '\n# BEGIN consultor-linux modulo-08\n'
  printf 'SHELL=/bin/bash\n'
  printf 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n'
  printf '0 3 * * * /usr/bin/flock -n "%s/respaldo.lock" /usr/bin/bash "%s/respaldo.sh" "%s/origen" "%s/respaldos" >> "%s/logs/respaldo-cron.log" 2>&1\n' \
    "$LAB" "$LAB" "$LAB" "$LAB" "$LAB"
  printf '# END consultor-linux modulo-08\n'
} > "$LAB/crontab.candidate"

crontab -n "$LAB/crontab.candidate"
tail -n 6 "$LAB/crontab.candidate"
```

`crontab -n` valida sin instalar. Antes de programar, ejecuta manualmente el
mismo comando que usará cron:

```bash
/usr/bin/flock -n "$LAB/respaldo.lock" \
  /usr/bin/bash "$LAB/respaldo.sh" "$LAB/origen" "$LAB/respaldos" \
  >> "$LAB/logs/respaldo-cron.log" 2>&1

tail -n 3 "$LAB/logs/respaldo-cron.log"
```

Si la prueba fue exitosa, instala el candidato y comprueba los marcadores:

```bash
crontab "$LAB/crontab.candidate"
crontab -l | sed -n '/BEGIN consultor-linux/,/END consultor-linux/p'
```

No necesitas esperar hasta las 03:00 durante la clase: ya probaste el comando
exacto. La entrada queda instalada para estudiar su reversión en el siguiente
apartado.

## Verificación y reversión

Comprueba script, respaldos y tarea:

```bash
bash -n "$LAB/respaldo.sh"
find "$LAB/respaldos" -maxdepth 1 -type f -printf '%f\n' | sort
crontab -l | grep -F 'consultor-linux modulo-08'
```

Restaura exactamente el estado anterior de cron:

```bash
if [[ "$(<"$LAB/tenia-crontab")" == si ]]; then
  crontab "$LAB/crontab.before"
else
  crontab -r
fi

if crontab -l 2>/dev/null | grep -qF 'consultor-linux modulo-08'; then
  printf 'ERROR: la tarea sigue instalada\n' >&2
else
  printf 'OK: tarea de laboratorio retirada\n'
fi
```

`crontab -r` sólo se usa cuando el registro demuestra que no existía un
crontab previo. Los archivos de respaldo se conservan como evidencia. Para
repetir sólo la restauración:

```bash
rm -rf -- "$LAB/restauracion/origen"
mkdir -p "$LAB/restauracion"
```

## Fallo controlado: origen inexistente

```bash
antes=$(find "$LAB/respaldos" -maxdepth 1 -type f -name '*.tar.gz' | wc -l)
estado=0
"$LAB/respaldo.sh" "$LAB/no-existe" "$LAB/respaldos" \
  > "$LAB/fallo.out" 2> "$LAB/fallo.err" || estado=$?
despues=$(find "$LAB/respaldos" -maxdepth 1 -type f -name '*.tar.gz' | wc -l)

printf 'Estado=%s Antes=%s Después=%s\n' "$estado" "$antes" "$despues"
cat "$LAB/fallo.err"
```

Debe mostrar estado `66`, el mismo conteo antes/después y un error legible. El
script valida antes de crear el archivo temporal: un fallo de entrada no deja
un respaldo parcial.

Prueba adicional: el destino dentro del origen debe rechazarse con estado 73:

```bash
estado=0
"$LAB/respaldo.sh" "$LAB/origen" "$LAB/origen/backups" \
  > /dev/null 2> "$LAB/destino-invalido.err" || estado=$?
printf 'Estado de destino inválido: %s\n' "$estado"
test ! -e "$LAB/origen/backups" \
  && printf 'OK: no se creó el destino inválido\n'
```

## Reto 8: respaldo programable y recuperable

Crea `$LAB/reto-08/respaldo-reto.sh`. Debe recibir origen y destino, validar
rutas, evitar destino dentro del origen, impedir concurrencia con `flock`,
crear `tar.gz` mediante temporal, generar SHA-256 y conservar errores en
`stderr`. Prepara —sin instalar— `crontab.reto` para ejecutarlo diariamente a
las 02:30. Demuestra una restauración y una prueba fallida con origen ausente.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-8)

### Criterios de éxito

- `bash -n` y, si está disponible, `shellcheck` no encuentran errores;
- dos ejecuciones no sobrescriben archivos y cada respaldo tiene hash válido;
- la restauración es idéntica según `diff -ru`;
- la entrada cron usa rutas absolutas, log y candado, y `crontab -n` la acepta;
- el fallo esperado no crea archivos parciales ni modifica el crontab real.

## Checklist

- [ ] Defino contrato, argumentos y estados de salida.
- [ ] Cito rutas y rechazo relaciones peligrosas entre ellas.
- [ ] Sé cuándo usar `if`, `for`, `case`, función y subshell.
- [ ] Creo en temporal y publico sólo después de verificar.
- [ ] Puedo crear, validar y restaurar un respaldo.
- [ ] Pruebo el comando antes de programarlo con cron.
- [ ] Preservo y restauro el crontab anterior.
