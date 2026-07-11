#!/usr/bin/env bash
set -o nounset

return_percentage() {
  local parte=$1
  local total=$2
  bc -l <<< "scale=2; 100 * $parte / $total"
}

parte=${1:-}
total=${2:-}
if [[ ! "$parte" =~ ^-?[0-9]+([.][0-9]+)?$ ||
      ! "$total" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
  printf 'Uso: %s <parte> <total-no-cero>\n' "$0" >&2
  exit 64
fi
if ! command -v bc >/dev/null; then
  printf 'Falta bc: sudo apt install bc\n' >&2
  exit 69
fi
if [[ $(bc -l <<< "$total == 0") -eq 1 ]]; then
  printf 'El total no puede ser cero\n' >&2
  exit 65
fi
porcentaje=$(return_percentage "$parte" "$total")
printf '%s de %s = %.2f%%\n' "$parte" "$total" "$porcentaje"
