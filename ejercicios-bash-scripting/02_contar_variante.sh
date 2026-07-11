#!/usr/bin/env bash
set -o nounset

archivo=${1:-}
if [[ -z "$archivo" || ! -r "$archivo" ]]; then
  printf 'Uso: %s <basketball_scores.csv>\n' "$0" >&2
  exit 66
fi

grep -Ec 'Lakers|Celtics' "$archivo"
