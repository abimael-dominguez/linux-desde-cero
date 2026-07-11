#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

for comando in gcc make; do
  if ! command -v "$comando" >/dev/null; then
    printf 'Falta %s. Ejecuta: make -C %s install\n' "$comando" "$script_dir" >&2
    exit 69
  fi
done

printf 'Compilando Pac-Man con make...\n'
make -C "$script_dir" clean all
printf 'Ejecutable: %s/pacman_game\n' "$script_dir"
printf 'Usa las flechas para moverte y q para salir.\n'
"$script_dir/pacman_game"
