#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
project_dir="$repo_dir/proyecto-compose"
compose_file="$project_dir/compose.yaml"
backup_dir="$repo_dir/backups"

# El archivo incluye el dump y el contenido del sitio; sólo debe leerlo su dueño.
umask 077

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

if docker info >/dev/null 2>&1; then
  docker_cmd=(docker)
elif command -v sudo >/dev/null 2>&1 && sudo -v && sudo docker info >/dev/null 2>&1; then
  docker_cmd=(sudo docker)
else
  die 'No se pudo acceder a Docker.'
fi
compose=("${docker_cmd[@]}" compose --project-directory "$project_dir" --file "$compose_file")

for service in db wordpress proxy; do
  [[ -n $("${compose[@]}" ps --quiet "$service") ]] || die "El servicio $service no está creado."
done

install -d -m 0700 -- "$backup_dir"
temporary_dir=$(mktemp --directory "$backup_dir/.tmp.XXXXXX")
trap 'rm -rf -- "$temporary_dir"' EXIT

timestamp=${FECHA_RESPALDO:-$(date --utc +%Y%m%dT%H%M%SZ)}
archive="$backup_dir/consultor-linux-${timestamp}.tar.gz"
[[ ! -e $archive && ! -e $archive.sha256 ]] \
  || die "Ya existe un respaldo con la marca $timestamp."

printf 'Creando dump consistente de MariaDB...\n'
# El bloque entre comillas simples se expande dentro del contenedor, no en el host.
# shellcheck disable=SC2016
"${compose[@]}" exec --no-TTY db sh -eu -c '
  client_file=/tmp/consultor-backup.cnf
  trap "rm -f -- $client_file" EXIT
  umask 077
  printf "[client]\nuser=root\npassword=%s\n" "$(cat /run/secrets/db_root_password)" > "$client_file"
  mariadb-dump --defaults-extra-file="$client_file" \
    --single-transaction --add-drop-database --databases wordpress
' > "$temporary_dir/database.sql"

printf 'Empaquetando archivos persistentes de WordPress...\n'
"${compose[@]}" exec --no-TTY wordpress \
  tar --create --gzip --file - --directory /var/www/html . \
  > "$temporary_dir/wordpress-files.tar.gz"

{
  printf 'fecha_utc=%s\n' "$timestamp"
  for service in db wordpress proxy; do
    container=$("${compose[@]}" ps --quiet "$service")
    image=$("${docker_cmd[@]}" inspect --format '{{.Config.Image}}' "$container")
    image_id=$("${docker_cmd[@]}" inspect --format '{{.Image}}' "$container")
    printf '%s_image=%s\n%s_id=%s\n' "$service" "$image" "$service" "$image_id"
  done
} > "$temporary_dir/manifest.txt"

tar --create --gzip --file "$archive" --directory "$temporary_dir" \
  database.sql wordpress-files.tar.gz manifest.txt
(
  cd -- "$backup_dir"
  sha256sum "$(basename -- "$archive")" > "$(basename -- "$archive").sha256"
)
chmod 0600 "$archive" "$archive.sha256"

printf 'Respaldo creado:\n  %s\n' "$archive"
printf 'Checksum:\n  %s.sha256\n' "$archive"
printf 'Descárgalo a tu computadora con SCP antes de terminar EC2.\n'
