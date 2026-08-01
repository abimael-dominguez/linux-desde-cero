#!/usr/bin/env bash

# local.sh — Administra DynamoDB Local y la aplicación Eventos Cero.
#
# Uso:
#   ./scripts/local.sh <up|migrate|test|backend|status|stop|reset>
#   ./scripts/local.sh --help
#
# Variables opcionales (también pueden guardarse en proyecto/.env):
#   LOCAL_DYNAMODB_PORT Puerto local de DynamoDB (8001).
#   DYNAMODB_TABLE      Nombre de la tabla local (events-cero-local).
#
# Compose inicia únicamente la imagen oficial de DynamoDB Local. La API se
# ejecuta en el host y guarda portadas en .local/. Las credenciales "local"
# son valores ficticios requeridos por el SDK; nunca se envían a AWS.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

DYNAMODB_PORT="${LOCAL_DYNAMODB_PORT:-8001}"
DYNAMODB_TABLE="${DYNAMODB_TABLE:-events-cero-local}"
DYNAMODB_ENDPOINT_URL="http://127.0.0.1:${DYNAMODB_PORT}"
PYTHON="${PROJECT_ROOT}/backend/.venv/bin/python"
PIP="${PROJECT_ROOT}/backend/.venv/bin/pip"

usage() {
  printf '%s\n' \
    'Uso: ./scripts/local.sh <comando>' \
    '' \
    '  up       Inicia únicamente DynamoDB Local y espera su health check' \
    '  migrate  Crea la tabla local si todavía no existe' \
    '  test     Ejecuta backend, integración DynamoDB y frontend' \
    '  backend  Inicia la API local en http://127.0.0.1:8000' \
    '  status   Muestra el estado de Compose' \
    '  stop     Detiene DynamoDB Local conservando sus datos' \
    '  reset    Borra los datos y las portadas locales (pide confirmación)' \
    '' \
    'Variables opcionales:' \
    '  LOCAL_DYNAMODB_PORT (inicial: 8001)' \
    '  DYNAMODB_TABLE (inicial: events-cero-local)' \
    '' \
    'Ejemplos:' \
    '  LOCAL_DYNAMODB_PORT=8010 ./scripts/local.sh test' \
    '  ./scripts/local.sh backend'
}

require_command() {
  # Falla temprano si una herramienta externa no está instalada.
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Falta el comando: %s\n' "$1" >&2
    exit 1
  }
}

compose() {
  # Conserva un nombre Compose estable aunque se invoque desde otra carpeta.
  docker compose --project-directory "${PROJECT_ROOT}" "$@"
}

local_aws() {
  # DynamoDB Local exige firma, pero acepta estas credenciales deliberadamente
  # ficticias. --endpoint-url impide que el comando alcance una cuenta AWS.
  AWS_ACCESS_KEY_ID=local \
  AWS_SECRET_ACCESS_KEY=local \
  AWS_DEFAULT_REGION=us-east-1 \
    aws --no-cli-pager --endpoint-url "${DYNAMODB_ENDPOINT_URL}" "$@"
}

ensure_python() {
  # Crea el entorno virtual si falta e instala dependencias reproducibles.
  require_command python3
  if [[ ! -x "${PYTHON}" ]]; then
    python3 -m venv "${PROJECT_ROOT}/backend/.venv"
  fi
  "${PIP}" install --disable-pip-version-check -q \
    -r backend/requirements.txt -r backend/requirements-dev.txt
}

up() {
  # Inicia exclusivamente DynamoDB Local y espera a que responda.
  require_command docker
  compose up -d --wait --remove-orphans dynamodb
}

migrate() {
  # DynamoDB no usa SQL: crea idempotentemente una tabla con id como única llave.
  require_command aws
  up
  if local_aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" \
    >/dev/null 2>&1; then
    printf 'La tabla %s ya existe.\n' "${DYNAMODB_TABLE}"
    return
  fi
  local_aws dynamodb create-table \
    --table-name "${DYNAMODB_TABLE}" \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    >/dev/null
  local_aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}"
  printf 'Tabla %s creada.\n' "${DYNAMODB_TABLE}"
}

with_local_dynamodb() {
  # Ejecuta un comando con el endpoint local y sin consultar credenciales reales.
  AWS_ACCESS_KEY_ID=local \
  AWS_SECRET_ACCESS_KEY=local \
  AWS_DEFAULT_REGION=us-east-1 \
  DYNAMODB_TABLE="${DYNAMODB_TABLE}" \
  DYNAMODB_ENDPOINT_URL="${DYNAMODB_ENDPOINT_URL}" \
    "$@"
}

test_all() {
  # Ejecuta pruebas Python, integración DynamoDB, pruebas React y build final.
  require_command npm
  migrate
  ensure_python
  (
    cd backend
    export RUN_DYNAMODB_INTEGRATION=1
    with_local_dynamodb "${PYTHON}" -m pytest
  )
  npm --prefix frontend ci --no-audit --no-fund
  npm --prefix frontend test
  npm --prefix frontend run build
}

backend() {
  # Inicia FastAPI con DynamoDB Local y portadas en el sistema de archivos.
  migrate
  ensure_python
  mkdir -p "${PROJECT_ROOT}/.local/media"
  cd backend
  export FILE_STORAGE_BACKEND=local
  export LOCAL_MEDIA_ROOT="${PROJECT_ROOT}/.local"
  with_local_dynamodb "${PYTHON}" -m uvicorn src.main:app \
    --host 127.0.0.1 --port 8000 --reload
}

reset() {
  # Destruye únicamente el volumen Compose y .local/ después de confirmar.
  require_command docker
  printf 'Esto borrará DynamoDB Local y las portadas de .local/. Escribe RESET: '
  local answer
  read -r answer
  [[ "${answer}" == RESET ]] || { printf 'Cancelado.\n'; exit 1; }
  compose down --volumes --remove-orphans
  if [[ -d "${PROJECT_ROOT}/.local" ]]; then
    find "${PROJECT_ROOT}/.local" -mindepth 1 -delete
  fi
  printf 'Entorno local eliminado.\n'
}

case "${1:-}" in
  up) up ;;
  migrate) migrate ;;
  test) test_all ;;
  backend) backend ;;
  status) require_command docker; compose ps ;;
  stop) require_command docker; compose stop dynamodb ;;
  reset) reset ;;
  -h|--help|help|'') usage ;;
  *) usage >&2; exit 2 ;;
esac
