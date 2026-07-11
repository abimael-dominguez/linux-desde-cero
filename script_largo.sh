#!/usr/bin/env bash
set -o nounset

iteraciones=${1:-60}
espera=${2:-1}
if [[ ! "$iteraciones" =~ ^[1-9][0-9]*$ || ! "$espera" =~ ^[0-9]+$ ]]; then
  printf 'Uso: %s [iteraciones-positivas] [segundos-no-negativos]\n' "$0" >&2
  exit 64
fi

printf 'Iniciando proceso largo (PID=%s)\n' "$$"
for ((i = 1; i <= iteraciones; i++)); do
  printf 'Iteración %d/%d - %s\n' "$i" "$iteraciones" "$(date --iso-8601=seconds)"
  sleep "$espera"
done
printf 'Proceso completado\n'
