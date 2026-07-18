#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
html="$here/Linux-desde-cero-Clase-1.html"
pdf="$here/Linux-desde-cero-Clase-1.pdf"

node "$here/generate.mjs"
google-chrome \
  --headless \
  --disable-gpu \
  --no-sandbox \
  --allow-file-access-from-files \
  --no-pdf-header-footer \
  --print-to-pdf="$pdf" \
  "file://$html"

pdfinfo "$pdf" | grep -E '^(Pages|Page size|File size):'
