#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
lab_dir="$repo_dir/laboratorio"

rm -rf -- "$lab_dir"
mkdir -p "$lab_dir/salida"
cp -a "$repo_dir/data" "$lab_dir/data"
mkdir -p \
  "$lab_dir/data/good_models" \
  "$lab_dir/data/bad_models" \
  "$lab_dir/data/good_logs" \
  "$lab_dir/data/to_keep" \
  "$lab_dir/data/tree_models" \
  "$lab_dir/data/descartados" \
  "$lab_dir/data/output_dir"
printf 'Laboratorio preparado en %s\n' "$lab_dir"
