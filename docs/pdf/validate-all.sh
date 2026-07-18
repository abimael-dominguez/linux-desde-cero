#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for class_number in 1 2 3 4; do
  pdf="$root/clase_$class_number/Linux-desde-cero-Clase-$class_number.pdf"
  test -s "$pdf"
  echo "Clase $class_number"
  pdfinfo "$pdf" | grep -E '^(Pages|Page size|File size|Tagged|Encrypted):'
  printf 'Destinos internos: '
  pdfinfo -dests "$pdf" | tail -n +2 | wc -l
done
