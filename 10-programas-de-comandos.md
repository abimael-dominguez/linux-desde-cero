# 10. Programas de comandos con Bash

## Objetivos

- Crear y ejecutar un script Bash.
- Usar comentarios, variables, argumentos y códigos de salida.
- Validar entradas antes de procesarlas.
- Generar un reporte útil para operación.

## Antes de empezar

Sitúate en la raíz del curso y prepara el laboratorio:

```bash
cd ~/linux-desde-cero
bash ejercicios-bash-scripting/preparar-lab.sh
mkdir -p laboratorio/scripts
```

## 10.1 Comentarios y shebang

```bash
#!/usr/bin/env bash
# Resume niveles de un archivo de log.
```

- El shebang elige el intérprete cuando el archivo se ejecuta directamente.
- Un comentario explica intención o una decisión; no debe repetir cada línea.

Las dos líneas anteriores son el contenido inicial de un script, no comandos independientes. Para crear un ejemplo completo listo para ejecutar:

```bash
printf '%s\n' \
  '#!/usr/bin/env bash' \
  '# Primer script del curso' \
  'echo "Hola desde Bash"' \
  > laboratorio/scripts/hola.sh
chmod +x laboratorio/scripts/hola.sh
laboratorio/scripts/hola.sh
```

Salida esperada: `Hola desde Bash`.

## 10.2 Variables y comillas

```bash
nombre="reporte diario"
fecha=$(date +%F)
printf 'Nombre: %s | Fecha: %s\n' "$nombre" "$fecha"
```

- `variable=valor`: no admite espacios alrededor de `=`.
- `$(...)`: sustitución de comando.
- `"$variable"`: evita separación por espacios y expansión de globs.
- Las mayúsculas suelen reservarse para variables de entorno.

## 10.3 `echo` y `printf`

`echo` es cómodo para mensajes simples. `printf` es más predecible para formatos:

```bash
printf 'usuario=%s errores=%d\n' "$USER" 2
```

`%s` recibe texto y `%d` un entero. Los argumentos se sustituyen en orden.

## 10.4 Parámetros y estado

| Expresión | Significado |
|---|---|
| `$0` | nombre usado para ejecutar |
| `$1`… | argumentos posicionales |
| `$#` | cantidad de argumentos |
| `"$@"` | todos, conservando límites |
| `$?` | estado del último comando |

Convención: 0 significa éxito; otro valor indica que no se completó lo solicitado.

### Script resuelto: `resumen-log.sh`

El bloque siguiente es el contenido completo del script. En el repositorio ya existe una versión equivalente en `ejercicios-bash-scripting/filtra_logs.sh`; no necesitas volver a teclearla para ejecutar la práctica.

```bash
#!/usr/bin/env bash
set -o nounset
set -o pipefail

if [[ $# -ne 1 ]]; then
  printf 'Uso: %s <archivo-log>\n' "$0" >&2
  exit 64
fi

log=$1
if [[ ! -r "$log" ]]; then
  printf 'Error: no puedo leer %s\n' "$log" >&2
  exit 66
fi

printf 'Archivo: %s\n' "$log"
for nivel in INFO WARN ERROR; do
  total=$(grep -c "$nivel" "$log" || true)
  printf '%-5s %d\n' "$nivel" "$total"
done
```

- `[[ ... ]]`: prueba de Bash.
- `-r`: archivo legible.
- `>&2`: mensaje hacia `stderr`.
- `exit`: termina con un estado explícito.
- `grep -c` puede devolver 1 cuando no encuentra coincidencias; `|| true` permite reportar cero.

Cuando se ejecuta así:

```bash
./resumen-log.sh data/dummy_logs.txt
```

los valores son:

- `$0` → `./resumen-log.sh`;
- `$1` → `data/dummy_logs.txt`;
- `$#` → `1`.

Por eso `log=$1` guarda la ruta del archivo en la variable `log`.

## Práctica guiada resuelta

Primero copiamos el script existente al laboratorio y lo renombramos `resumen-log.sh`. Después hacemos dos pruebas: una válida con `data/dummy_logs.txt` y otra inválida con `archivo-inexistente`.

```bash
mkdir -p laboratorio/scripts
cp ejercicios-bash-scripting/filtra_logs.sh laboratorio/scripts/resumen-log.sh
chmod +x laboratorio/scripts/resumen-log.sh

laboratorio/scripts/resumen-log.sh data/dummy_logs.txt \
  > laboratorio/scripts/reporte.txt
estado_ok=$?

laboratorio/scripts/resumen-log.sh archivo-inexistente \
  2> laboratorio/scripts/error.txt || estado_error=$?

printf 'Éxito=%s Error=%s\n' "$estado_ok" "${estado_error:-0}"
cat laboratorio/scripts/reporte.txt
cat laboratorio/scripts/error.txt
```

La prueba cubre camino exitoso y fallo esperado, preservando ambas salidas.

`estado_ok` debe ser `0`. `estado_error` debe ser distinto de cero —en este script es `66`— y `error.txt` debe explicar que el archivo no puede leerse.

## Errores frecuentes

- Ejecutar datos como código con `eval`.
- Usar `$*` cuando se necesitan argumentos separados.
- Omitir comillas en rutas.
- Mostrar un error pero finalizar con código 0.
- Activar opciones estrictas sin comprender comandos que legítimamente devuelven estado distinto de cero.

## Reto 10 — Resumen parametrizado

[Ver respuesta](instructor/soluciones.md#respuesta-reto-10)

Escribe `laboratorio/scripts/reto10.sh`. Debe recibir dos argumentos: `<archivo_log>` y `<archivo_reporte>`. Debe validar ambos, generar conteos por nivel, listar usuarios únicos y no crear el reporte si la entrada es inválida.

### Criterios de comprobación

- Funciona con rutas que contienen espacios.
- Mensajes de error van a `stderr`.
- Devuelve 0 al completar y otro código al fallar.
- No contiene una ruta fija a `data/dummy_logs.txt`.

## Checklist

- [ ] Escribo shebang y comentarios útiles.
- [ ] Cito variables y uso `"$@"` correctamente.
- [ ] Valido argumentos y archivos.
- [ ] Produzco estados de salida verificables.
