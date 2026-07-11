#!/usr/bin/env bash
set -o nounset

segundos=${1:-120}
if [[ ! "$segundos" =~ ^[0-9]+$ ]]; then
  printf 'Uso: %s [segundos]\n' "$0" >&2
  exit 64
fi
printf 'Proceso %s en ejecución durante %s segundos...\n' "$$" "$segundos"
sleep "$segundos"
