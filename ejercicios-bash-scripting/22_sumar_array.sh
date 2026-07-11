#!/usr/bin/env bash
set -o nounset

sum_array() {
  local suma=0
  local numero
  for numero in "$@"; do
    suma=$(bc -l <<< "$suma + $numero")
  done
  printf '%s\n' "$suma"
}

if (( $# == 0 )); then
  printf 'Uso: %s <número>...\n' "$0" >&2
  exit 64
fi
if ! command -v bc >/dev/null; then
  printf 'Falta bc: sudo apt install bc\n' >&2
  exit 69
fi
for numero in "$@"; do
  [[ "$numero" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || {
    printf 'Número inválido: %s\n' "$numero" >&2
    exit 65
  }
done
total=$(sum_array "$@")
printf 'Suma total: %.2f\n' "$total"
