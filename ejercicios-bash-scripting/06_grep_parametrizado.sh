#!/usr/bin/env bash
set -o nounset
set -o pipefail

patron=${1:-}
directorio=${2:-}
salida=${3:-}
if [[ -z "$patron" || -z "$directorio" || -z "$salida" || ! -d "$directorio" ]]; then
  printf 'Uso: %s <patrón> <directorio-csv> <salida.csv>\n' "$0" >&2
  exit 64
fi

mkdir -p "$(dirname "$salida")"
shopt -s nullglob
archivos=("$directorio"/*.csv)
if (( ${#archivos[@]} == 0 )); then
  printf 'No hay archivos CSV en %s\n' "$directorio" >&2
  exit 66
fi
grep -h -- "$patron" "${archivos[@]}" > "$salida"
