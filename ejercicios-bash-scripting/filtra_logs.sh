#!/usr/bin/env bash
set -o nounset
set -o pipefail

log=${1:-}
if [[ -z "$log" || ! -r "$log" ]]; then
  printf 'Uso: %s <archivo-log>\n' "$0" >&2
  exit 66
fi

printf 'Archivo: %s\n' "$log"
for nivel in INFO WARN ERROR; do
  total=$(grep -c "$nivel" "$log" || true)
  printf '%-5s %d\n' "$nivel" "$total"
done
printf 'Usuarios:\n'
grep -oE 'User [[:alnum:]_-]+' "$log" \
  | cut -d' ' -f2 \
  | sort -u
