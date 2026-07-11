#!/usr/bin/env bash
set -o nounset

upload_to_cloud() {
  local directorio=$1
  local archivo
  shopt -s nullglob
  for archivo in "$directorio"/*results.txt; do
    printf 'Simulación: subir %s\n' "$archivo"
  done
}

directorio=${1:-}
if [[ -z "$directorio" || ! -d "$directorio" ]]; then
  printf 'Uso: %s <directorio-resultados>\n' "$0" >&2
  exit 64
fi
upload_to_cloud "$directorio"
