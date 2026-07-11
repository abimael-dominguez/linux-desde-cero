#!/usr/bin/env bash
set -o nounset
set -o pipefail

archivo=${1:-}
if [[ -z "$archivo" || ! -r "$archivo" ]]; then
  printf 'Uso: %s <basketball_scores.csv>\n' "$0" >&2
  exit 66
fi

tail -n +2 "$archivo" | cut -d',' -f2 | sort | uniq -c | sort -k2
