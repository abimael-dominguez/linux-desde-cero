#!/usr/bin/env bash
set -o nounset

origen=${1:-}
arboles=${2:-}
descartados=${3:-}
if [[ -z "$origen" || -z "$arboles" || -z "$descartados" || ! -d "$origen" ]]; then
  printf 'Uso: %s <model_out> <tree_models> <descartados>\n' "$0" >&2
  exit 64
fi

mkdir -p "$arboles" "$descartados"
shopt -s nullglob
for archivo in "$origen"/*; do
  contenido=$(< "$archivo")
  case $contenido in
    *'Random Forest'*|*GBM*|*XGBoost*) mv -- "$archivo" "$arboles/" ;;
    *KNN*|*Logistic*) mv -- "$archivo" "$descartados/" ;;
    *) printf 'Modelo desconocido: %s\n' "$archivo" ;;
  esac
done
