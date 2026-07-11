#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
project_dir="$repo_dir/proyecto-compose"
compose_file="$project_dir/compose.yaml"
secrets_dir="$project_dir/secrets"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

if docker info >/dev/null 2>&1; then
  docker_cmd=(docker)
elif command -v sudo >/dev/null 2>&1 && sudo -v && sudo docker info >/dev/null 2>&1; then
  docker_cmd=(sudo docker)
else
  die 'Docker no está disponible. Ejecuta primero: bash scripts/bootstrap-ubuntu.sh'
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

[[ -f $compose_file ]] || die "No existe $compose_file."
command -v openssl >/dev/null 2>&1 || die 'Falta openssl.'
command -v curl >/dev/null 2>&1 || die 'Falta curl.'

mkdir -p -- "$secrets_dir"
chmod 700 "$secrets_dir"
for secret_name in db_password db_root_password; do
  secret_file="$secrets_dir/${secret_name}.txt"
  if [[ ! -s $secret_file ]]; then
    umask 077
    openssl rand -hex 24 > "$secret_file"
  fi
  chmod 600 "$secret_file"
done

"${compose[@]}" config --quiet

printf 'Descargando imágenes versionadas; no se compilará nada en EC2.\n'
"${compose[@]}" pull db
"${compose[@]}" pull wordpress
"${compose[@]}" pull proxy

printf 'Iniciando MariaDB...\n'
"${compose[@]}" up --detach db

db_container=$("${compose[@]}" ps --quiet db)
for _ in {1..60}; do
  health=$("${docker_cmd[@]}" inspect --format '{{.State.Health.Status}}' "$db_container" 2>/dev/null || true)
  [[ $health == healthy ]] && break
  sleep 2
done
[[ ${health:-} == healthy ]] || die 'MariaDB no alcanzó el estado healthy. Revisa: sudo docker compose logs db'

printf 'Iniciando WordPress...\n'
"${compose[@]}" up --detach wordpress
wordpress_container=$("${compose[@]}" ps --quiet wordpress)
for _ in {1..60}; do
  health=$("${docker_cmd[@]}" inspect --format '{{.State.Health.Status}}' "$wordpress_container" 2>/dev/null || true)
  [[ $health == healthy ]] && break
  sleep 2
done
[[ ${health:-} == healthy ]] || die 'WordPress no alcanzó el estado healthy.'

printf 'Iniciando Nginx...\n'
"${compose[@]}" up --detach proxy
for _ in {1..30}; do
  if aplicacion_http_disponible; then
    break
  fi
  sleep 2
done
aplicacion_http_disponible \
  || die 'Nginx responde, pero WordPress no entrega HTTP 200, 301 o 302.'
curl --silent --show-error --fail http://127.0.0.1:8080/healthz

printf '\nStack preparado. Estado:\n'
"${compose[@]}" ps
printf '\nDesde tu computadora abre el túnel:\n'
printf '  ssh -i <CLAVE.pem> -L 8080:127.0.0.1:8080 ubuntu@<IP_PUBLICA>\n'
printf 'Después visita: http://127.0.0.1:8080\n'
