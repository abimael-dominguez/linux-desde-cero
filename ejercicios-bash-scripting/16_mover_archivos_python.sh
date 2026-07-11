#!/usr/bin/env bash
set -o nounset

origen=${1:-}
destino=${2:-}
if [[ -z "$origen" || -z "$destino" || ! -d "$origen" ]]; then
  printf 'Uso: %s <directorio-python> <destino>\n' "$0" >&2
  exit 64
fi

mkdir -p "$destino"
shopt -s nullglob
for archivo in "$origen"/*.py; do
  if grep -q 'RandomForestClassifier' "$archivo"; then
    mv -- "$archivo" "$destino/"
  fi
done
