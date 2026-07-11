#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
lab_dir="$repo_dir/laboratorio"
expected_lab=$(realpath --canonicalize-missing "$repo_dir/laboratorio")
actual_lab=$(realpath --canonicalize-missing "$lab_dir")

if [[ $repo_dir == / || ! -f $repo_dir/README.md || $actual_lab != "$expected_lab" ]]; then
  printf 'Se abortó: no se pudo verificar la raíz del repositorio.\n' >&2
  exit 1
fi

rm -rf --one-file-system -- "$lab_dir"
mkdir -p "$lab_dir"/{salida,backups,configuracion,almacenamiento}
cp -a -- "$repo_dir/data" "$lab_dir/data"

printf 'Laboratorio preparado en:\n  %s\n' "$lab_dir"
printf 'Los fixtures originales bajo data/ no serán modificados.\n'
