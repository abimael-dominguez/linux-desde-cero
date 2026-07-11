#!/usr/bin/env bash
set -o nounset

equipo=${1:-}
archivo=${2:-}
if [[ -z "$equipo" || -z "$archivo" || ! -r "$archivo" ]]; then
  printf 'Uso: %s <equipo> <basketball_scores.csv>\n' "$0" >&2
  exit 64
fi
total=$(tail -n +2 "$archivo" | cut -d',' -f2 | grep -Fxc -- "$equipo" || true)
printf '%s: %d\n' "$equipo" "$total"
