#!/usr/bin/env bash
set -o nounset

directorio=${1:-}
if [[ -z "$directorio" || ! -r "$directorio/region_B" || ! -r "$directorio/region_C" ]]; then
  printf 'Uso: %s <directorio-temps>\n' "$0" >&2
  exit 66
fi
if ! command -v bc >/dev/null; then
  printf 'Falta bc: sudo apt install bc\n' >&2
  exit 69
fi

temperaturas=("$(< "$directorio/region_B")" "$(< "$directorio/region_C")")
promedio=$(bc -l <<< "scale=2; (${temperaturas[0]} + ${temperaturas[1]}) / 2")
printf 'Temperaturas: %s %s\n' "${temperaturas[0]}" "${temperaturas[1]}"
printf 'Promedio: %.2f\n' "$promedio"
