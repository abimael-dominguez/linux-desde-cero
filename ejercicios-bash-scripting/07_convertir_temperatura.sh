#!/usr/bin/env bash
set -o nounset

temp_f=${1:-}
if [[ ! "$temp_f" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
  printf 'Uso: %s <grados-Fahrenheit>\n' "$0" >&2
  exit 64
fi
if ! command -v bc >/dev/null; then
  printf 'Falta bc: sudo apt install bc\n' >&2
  exit 69
fi

temp_c=$(bc -l <<< "scale=4; ($temp_f - 32) * 5 / 9")
printf '%s F = %.2f C\n' "$temp_f" "$temp_c"
