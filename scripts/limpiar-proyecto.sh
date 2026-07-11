#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
project_dir="$repo_dir/proyecto-compose"
compose_file="$project_dir/compose.yaml"

if docker info >/dev/null 2>&1; then
  docker_cmd=(docker)
else
  docker_cmd=(sudo docker)
fi
compose=("${docker_cmd[@]}" compose --project-directory "$project_dir" --file "$compose_file")

case ${1:-} in
  '')
    "${compose[@]}" down --remove-orphans
    printf 'Contenedores y red eliminados; los volúmenes y secretos se conservaron.\n'
    ;;
  --eliminar-datos)
    if [[ ${2:-} != --confirmar ]]; then
      printf 'Esta opción borra exclusivamente los volúmenes y secretos de consultor-linux.\n' >&2
      printf 'Confirma con: sudo bash %s --eliminar-datos --confirmar\n' "$0" >&2
      exit 2
    fi
    "${compose[@]}" down --volumes --remove-orphans
    rm -rf -- "$project_dir/secrets"
    printf 'Contenedores, red, volúmenes y secretos del proyecto eliminados.\n'
    ;;
  *)
    printf 'Uso: %s [--eliminar-datos --confirmar]\n' "$0" >&2
    exit 2
    ;;
esac

printf 'No se ejecutó docker system prune ni se tocaron otros proyectos.\n'
