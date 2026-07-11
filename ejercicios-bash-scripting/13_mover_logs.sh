#!/usr/bin/env bash
set -o nounset

archivo=${1:-}
destino=${2:-}
if [[ -z "$archivo" || -z "$destino" || ! -r "$archivo" ]]; then
  printf 'Uso: %s <log> <destino>\n' "$0" >&2
  exit 64
fi

if grep -q 'SRVM_' "$archivo" && grep -q 'vpt' "$archivo"; then
  mkdir -p "$destino"
  mv -- "$archivo" "$destino/"
else
  printf 'El archivo no cumple ambos patrones: %s\n' "$archivo"
fi
