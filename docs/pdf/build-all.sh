#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for class_number in 1 2 3 4; do
  echo "Compilando clase $class_number..."
  bash "$root/clase_$class_number/build.sh"
done
