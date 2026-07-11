#!/usr/bin/env bash
set -o nounset

printf 'Primer argumento: %s\n' "${1:-no definido}"
printf 'Segundo argumento: %s\n' "${2:-no definido}"
printf 'Cantidad: %d\n' "$#"
printf 'Todos:'
printf ' [%s]' "$@"
printf '\n'
