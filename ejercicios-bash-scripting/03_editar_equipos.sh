#!/usr/bin/env bash
set -o nounset

entrada=${1:-}
salida=${2:-}
if [[ -z "$entrada" || -z "$salida" || ! -r "$entrada" ]]; then
  printf 'Uso: %s <entrada.csv> <salida.csv>\n' "$0" >&2
  exit 66
fi

mkdir -p "$(dirname "$salida")"
sed -e 's/Lakers/LA Lakers/g' \
    -e 's/Celtics/Boston Celtics/g' \
    "$entrada" > "$salida"
