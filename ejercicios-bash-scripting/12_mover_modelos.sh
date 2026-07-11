#!/usr/bin/env bash
set -o nounset

archivo=${1:-}
buenos=${2:-}
malos=${3:-}
if [[ -z "$archivo" || -z "$buenos" || -z "$malos" || ! -r "$archivo" ]]; then
  printf 'Uso: %s <resultado> <directorio-buenos> <directorio-malos>\n' "$0" >&2
  exit 64
fi

accuracy=$(awk '/Accuracy/ {print $NF; exit}' "$archivo")
if [[ ! "$accuracy" =~ ^[0-9]+$ ]]; then
  printf 'Accuracy inválida en %s\n' "$archivo" >&2
  exit 65
fi
mkdir -p "$buenos" "$malos"
if (( accuracy >= 90 )); then
  mv -- "$archivo" "$buenos/"
else
  mv -- "$archivo" "$malos/"
fi
