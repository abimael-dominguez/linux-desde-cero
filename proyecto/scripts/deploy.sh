#!/usr/bin/env bash

# deploy.sh — Construye y despliega Eventos Cero en AWS.
#
# Uso:
#   AWS_PROFILE=perfil-alumno ./scripts/deploy.sh
#   AWS_PROFILE=perfil-alumno AWS_REGION=us-east-1 ./scripts/deploy.sh
#   ./scripts/deploy.sh --help
#
# Variables de entrada:
#   AWS_PROFILE   Perfil nombrado existente en ~/.aws/ (obligatorio).
#   AWS_REGION    Región de despliegue; debe coincidir con el perfil (us-east-1).
#   PROJECT_NAME  Prefijo de stacks y etiquetas (tecgurus-linux-events).
#   STAGE         Ambiente independiente (inicial: lab). Normalmente se omite.
#                 Solo se cambia para separar recursos dentro de una cuenta.
#                 Admite 1-5 caracteres: minúsculas, números y guiones.
# Si cambias STAGE, usa exactamente el mismo valor en audit.sh y destroy.sh.
#
# Efectos: crea o actualiza ECR y el stack de aplicación, publica la imagen
# Lambda, crea DynamoDB, sincroniza el frontend en S3 y prueba CloudFront.
# Es idempotente, pero crea recursos AWS que pueden generar costos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  printf '%s\n' \
    'Uso: AWS_PROFILE=<perfil> [STAGE=lab] [AWS_REGION=us-east-1] ./scripts/deploy.sh' \
    '' \
    'Crea o actualiza toda la aplicación Eventos Cero en AWS.' \
    '' \
    'Variable obligatoria:' \
    '  AWS_PROFILE    Perfil de ~/.aws/ (obligatorio)' \
    '' \
    'Variables opcionales:' \
    '  AWS_REGION     Región AWS (inicial: us-east-1)' \
    '  PROJECT_NAME   Prefijo de recursos (inicial: tecgurus-linux-events)' \
    '  STAGE          Ambiente independiente (inicial: lab; normalmente se omite)' \
    '                 1-5 caracteres: minúsculas, números o guiones' \
    '' \
    'Uso normal:' \
    '  AWS_PROFILE=perfil-alumno ./scripts/deploy.sh' \
    '' \
    'Ambiente adicional en la misma cuenta:' \
    '  AWS_PROFILE=perfil-alumno STAGE=a01 ./scripts/deploy.sh' \
    '  Reutiliza STAGE=a01 al ejecutar audit.sh y destroy.sh.'
}

case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  '') ;;
  *) die "Opción no reconocida: $1. Usa --help." ;;
esac

require_aws_profile
validate_stage
for command_name in aws docker node npm curl grep openssl sha256sum; do
  require_command "${command_name}"
done

if ! aws configure list-profiles | grep -Fqx "${AWS_PROFILE}"; then
  die "No existe el perfil AWS '${AWS_PROFILE}'. Créalo con: aws configure --profile ${AWS_PROFILE}"
fi

info "Validando identidad, región y plantillas"
ACCOUNT_ID="$(aws_cli sts get-caller-identity --query Account --output text)"
CALLER_ARN="$(aws_cli sts get-caller-identity --query Arn --output text)"
CONFIGURED_REGION="$(aws configure get region --profile "${AWS_PROFILE}" || true)"
[[ "${ACCOUNT_ID}" =~ ^[0-9]{12}$ ]] || die "No fue posible obtener la cuenta AWS."
[[ "${CONFIGURED_REGION}" == "${AWS_REGION}" ]] || \
  die "El perfil debe declarar region=${AWS_REGION}; valor actual: ${CONFIGURED_REGION:-vacío}"
aws_cli cloudformation validate-template --template-body "file://${PROJECT_ROOT}/infra/ecr.yaml" >/dev/null
aws_cli cloudformation validate-template --template-body "file://${PROJECT_ROOT}/infra/app.yaml" >/dev/null
printf 'Cuenta: %s\nIdentidad: %s\nRegión: %s\n' "${ACCOUNT_ID}" "${CALLER_ARN}" "${AWS_REGION}"

recover_rollback_complete_stack "${BOOTSTRAP_STACK}"
info "Creando o actualizando el repositorio ECR"
aws_cli cloudformation deploy \
  --stack-name "${BOOTSTRAP_STACK}" \
  --template-file "${PROJECT_ROOT}/infra/ecr.yaml" \
  --parameter-overrides ProjectName="${PROJECT_NAME}" Stage="${STAGE}" \
  --tags Project="${PROJECT_NAME}" Stage="${STAGE}" ManagedBy=cloudformation \
  --no-fail-on-empty-changeset
REPOSITORY_NAME="$(stack_output "${BOOTSTRAP_STACK}" RepositoryName)"
REPOSITORY_URI="$(stack_output "${BOOTSTRAP_STACK}" RepositoryUri)"

IMAGE_HASH="$({
  find "${PROJECT_ROOT}/backend/src" -type f -name '*.py' -print
  printf '%s\n' "${PROJECT_ROOT}/backend/requirements.txt" "${PROJECT_ROOT}/Dockerfile"
} | sort | while IFS= read -r source_file; do sha256sum "${source_file}"; done | sha256sum | cut -c1-24)"
IMAGE_TAG="sha-${IMAGE_HASH}"
REMOTE_DIGEST="$(aws_cli ecr describe-images \
  --repository-name "${REPOSITORY_NAME}" \
  --image-ids imageTag="${IMAGE_TAG}" \
  --query 'imageDetails[0].imageDigest' --output text 2>/dev/null || true)"

if [[ -z "${REMOTE_DIGEST}" || "${REMOTE_DIGEST}" == None ]]; then
  info "Construyendo y publicando la API ${IMAGE_TAG}"
  aws_cli ecr get-login-password | \
    docker login --username AWS --password-stdin "${REPOSITORY_URI%%/*}"
  docker build --platform linux/amd64 \
    --tag "${REPOSITORY_URI}:${IMAGE_TAG}" "${PROJECT_ROOT}"
  docker push "${REPOSITORY_URI}:${IMAGE_TAG}"
  REMOTE_DIGEST="$(aws_cli ecr describe-images \
    --repository-name "${REPOSITORY_NAME}" \
    --image-ids imageTag="${IMAGE_TAG}" \
    --query 'imageDetails[0].imageDigest' --output text)"
else
  info "La imagen ${IMAGE_TAG} ya existe; se reutiliza sin volver a subirla"
fi
[[ "${REMOTE_DIGEST}" == sha256:* ]] || die "ECR no devolvió un digest válido."
BACKEND_IMAGE_URI="${REPOSITORY_URI}@${REMOTE_DIGEST}"

DEPLOYMENT_ID="$(resolve_deployment_id)"
WEB_BUCKET="tecgurus-linux-events-${ACCOUNT_ID}-${AWS_REGION}-${STAGE}-${DEPLOYMENT_ID}-web"
MEDIA_BUCKET="tecgurus-linux-events-${ACCOUNT_ID}-${AWS_REGION}-${STAGE}-${DEPLOYMENT_ID}-media"
assert_bucket_name "${WEB_BUCKET}"
assert_bucket_name "${MEDIA_BUCKET}"

recover_rollback_complete_stack "${APP_STACK}"
info "Creando o actualizando la aplicación"
aws_cli cloudformation deploy \
  --stack-name "${APP_STACK}" \
  --template-file "${PROJECT_ROOT}/infra/app.yaml" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    ProjectName="${PROJECT_NAME}" \
    Stage="${STAGE}" \
    DeploymentId="${DEPLOYMENT_ID}" \
    BackendImageUri="${BACKEND_IMAGE_URI}" \
    WebBucketName="${WEB_BUCKET}" \
    MediaBucketName="${MEDIA_BUCKET}" \
  --tags Project="${PROJECT_NAME}" Stage="${STAGE}" DeploymentId="${DEPLOYMENT_ID}" \
  --no-fail-on-empty-changeset

EVENTS_TABLE="$(stack_output "${APP_STACK}" EventsTableName)"

info "Construyendo y sincronizando el frontend"
npm --prefix "${PROJECT_ROOT}/frontend" ci --no-audit --no-fund
npm --prefix "${PROJECT_ROOT}/frontend" run build
aws_cli s3 sync "${PROJECT_ROOT}/frontend/dist" "s3://${WEB_BUCKET}" \
  --delete \
  --exclude index.html \
  --cache-control 'public,max-age=31536000,immutable'
aws_cli s3 cp "${PROJECT_ROOT}/frontend/dist/index.html" "s3://${WEB_BUCKET}/index.html" \
  --content-type 'text/html; charset=utf-8' \
  --cache-control 'no-store'

APPLICATION_URL="$(stack_output "${APP_STACK}" ApplicationUrl)"
info "Esperando que la aplicación responda"
SMOKE_OK=0
for attempt in $(seq 1 24); do
  if curl --fail --silent --show-error --max-time 30 \
    "${APPLICATION_URL}/api/events" >/dev/null; then
    SMOKE_OK=1
    break
  fi
  printf 'Intento %s/24; reintentando en 5 segundos...\n' "${attempt}"
  sleep 5
done
[[ ${SMOKE_OK} -eq 1 ]] || die "El smoke test no respondió correctamente: ${APPLICATION_URL}"

info "Despliegue listo"
printf '%-18s %s\n' \
  'URL:' "${APPLICATION_URL}" \
  'Cuenta:' "${ACCOUNT_ID}" \
  'Región:' "${AWS_REGION}" \
  'Ambiente:' "${STAGE}" \
  'Stack app:' "${APP_STACK}" \
  'Stack ECR:' "${BOOTSTRAP_STACK}" \
  'Bucket web:' "${WEB_BUCKET}" \
  'Bucket media:' "${MEDIA_BUCKET}" \
  'Tabla DynamoDB:' "${EVENTS_TABLE}" \
  'Imagen API:' "${BACKEND_IMAGE_URI}"
