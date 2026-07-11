#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  printf 'Uso: %s <consultor-linux-fecha.tar.gz> --confirmar\n' "$0"
}

if (( $# != 2 )) || [[ $2 != --confirmar ]]; then
  usage >&2
  exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
project_dir="$repo_dir/proyecto-compose"
compose_file="$project_dir/compose.yaml"
archive=$(realpath -- "$1")
checksum="$archive.sha256"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ -f $archive && -f $checksum ]] || die 'Falta el respaldo o su archivo .sha256.'

if docker info >/dev/null 2>&1; then
  docker_cmd=(docker)
elif command -v sudo >/dev/null 2>&1 && sudo -v && sudo docker info >/dev/null 2>&1; then
  docker_cmd=(sudo docker)
else
  die 'No se pudo acceder a Docker.'
fi
compose=("${docker_cmd[@]}" compose --project-directory "$project_dir" --file "$compose_file")

aplicacion_http_disponible() {
  local code
  code=$(curl --silent --show-error --output /dev/null \
    --write-out '%{http_code}' --location --max-redirs 3 --max-time 5 \
    http://127.0.0.1:8080/ 2>/dev/null || true)
  case $code in
    200|301|302) return 0 ;;
    *) return 1 ;;
  esac
}

(
  cd -- "$(dirname -- "$archive")"
  sha256sum --check "$(basename -- "$checksum")"
)

temporary_dir=$(mktemp --directory)
trap 'rm -rf -- "$temporary_dir"' EXIT
tar --extract --gzip --file "$archive" --directory "$temporary_dir"

for required_file in database.sql wordpress-files.tar.gz manifest.txt; do
  [[ -s $temporary_dir/$required_file ]] || die "El respaldo no contiene $required_file."
done

printf 'ADVERTENCIA: se reemplazarán datos únicamente en los volúmenes de consultor-linux.\n'
"${compose[@]}" down --volumes --remove-orphans

printf 'Creando volúmenes nuevos y arrancando MariaDB...\n'
"${compose[@]}" up --detach db
db_container=$("${compose[@]}" ps --quiet db)
for _ in {1..60}; do
  db_health=$("${docker_cmd[@]}" inspect --format '{{.State.Health.Status}}' "$db_container" 2>/dev/null || true)
  [[ $db_health == healthy ]] && break
  sleep 2
done
[[ ${db_health:-} == healthy ]] || die 'MariaDB no alcanzó el estado healthy durante la restauración.'

printf 'Restaurando la base de datos...\n'
# El bloque entre comillas simples se expande dentro del contenedor, no en el host.
# shellcheck disable=SC2016
"${compose[@]}" exec --no-TTY db sh -eu -c '
  client_file=/tmp/consultor-restore.cnf
  trap "rm -f -- $client_file" EXIT
  umask 077
  printf "[client]\nuser=root\npassword=%s\n" "$(cat /run/secrets/db_root_password)" > "$client_file"
  mariadb --defaults-extra-file="$client_file"
' < "$temporary_dir/database.sql"

printf 'Restaurando los archivos de WordPress...\n'
"${compose[@]}" up --detach wordpress
wordpress_container=$("${compose[@]}" ps --quiet wordpress)
for _ in {1..60}; do
  wordpress_health=$("${docker_cmd[@]}" inspect --format '{{.State.Health.Status}}' "$wordpress_container" 2>/dev/null || true)
  [[ $wordpress_health == healthy ]] && break
  sleep 2
done
[[ ${wordpress_health:-} == healthy ]] || die 'WordPress no alcanzó el estado healthy durante la restauración.'

"${compose[@]}" exec --no-TTY wordpress sh -eu -c \
  'find /var/www/html -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +'
gzip --decompress --stdout "$temporary_dir/wordpress-files.tar.gz" \
  | "${compose[@]}" exec --no-TTY wordpress tar --extract --file - --directory /var/www/html
"${compose[@]}" exec --no-TTY wordpress chown --recursive www-data:www-data /var/www/html

"${compose[@]}" restart wordpress
wordpress_container=$("${compose[@]}" ps --quiet wordpress)
for _ in {1..60}; do
  wordpress_health=$("${docker_cmd[@]}" inspect --format '{{.State.Health.Status}}' \
    "$wordpress_container" 2>/dev/null || true)
  [[ $wordpress_health == healthy ]] && break
  sleep 2
done
[[ ${wordpress_health:-} == healthy ]] \
  || die 'WordPress no volvió a healthy después de restaurar sus archivos.'
"${compose[@]}" up --detach proxy

for _ in {1..30}; do
  if aplicacion_http_disponible; then
    break
  fi
  sleep 2
done
aplicacion_http_disponible \
  || die 'La aplicación restaurada no entrega HTTP 200, 301 o 302 mediante Nginx.'
curl --silent --show-error --fail http://127.0.0.1:8080/healthz
printf 'Restauración terminada y proxy verificado.\n'
