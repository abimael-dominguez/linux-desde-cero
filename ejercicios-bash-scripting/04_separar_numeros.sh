#!/usr/bin/env bash
set -o nounset

salida=${1:-salida}
mkdir -p "$salida"

printf '%s\n' {1..100} > "$salida/todos.txt"
grep -E '[13579]$' "$salida/todos.txt" > "$salida/impares.txt"
grep -E '[02468]$' "$salida/todos.txt" > "$salida/pares.txt"

{
  printf 'Error de demostración: archivo inexistente\n' >&2
  ls /archivo-inexistente >&2
} 2> "$salida/errores.log" || true

printf '%s INFO: separación completada\n' \
  "$(date --iso-8601=seconds)" > "$salida/proceso.log"
