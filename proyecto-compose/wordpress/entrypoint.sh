#!/usr/bin/env bash
set -Eeuo pipefail

secret_file=/run/secrets/db_password
if [[ ! -r $secret_file ]]; then
  printf 'No se puede leer el secreto de MariaDB: %s\n' "$secret_file" >&2
  exit 1
fi

# Compose monta el secreto para root. Se lee antes de que Apache cambie a
# www-data y se entrega al wp-config de la imagen oficial mediante entorno.
export WORDPRESS_DB_PASSWORD
WORDPRESS_DB_PASSWORD=$(< "$secret_file")
unset WORDPRESS_DB_PASSWORD_FILE

exec /usr/local/bin/docker-entrypoint.sh "$@"
