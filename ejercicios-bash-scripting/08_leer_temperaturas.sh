#!/usr/bin/env bash
set -o nounset

directorio=${1:-}
if [[ -z "$directorio" || ! -d "$directorio" ]]; then
  printf 'Uso: %s <directorio-temps>\n' "$0" >&2
  exit 66
fi

for region in region_A region_B region_C; do
  archivo="$directorio/$region"
  if [[ ! -r "$archivo" ]]; then
    printf 'No puedo leer %s\n' "$archivo" >&2
    exit 66
  fi
  printf '%s=%s F\n' "$region" "$(< "$archivo")"
done
