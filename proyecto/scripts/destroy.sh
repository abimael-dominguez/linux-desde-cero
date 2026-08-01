#!/usr/bin/env bash

# destroy.sh — Elimina permanentemente el laboratorio Eventos Cero de AWS.
#
# Uso:
#   AWS_PROFILE=perfil-alumno ./scripts/destroy.sh
#   AWS_PROFILE=perfil-alumno STAGE=a01 ./scripts/destroy.sh
#   ./scripts/destroy.sh --help
#
# Variables de entrada:
#   AWS_PROFILE   Perfil nombrado usado al desplegar (obligatorio).
#   AWS_REGION    Región usada al desplegar (inicial: us-east-1).
#   PROJECT_NAME  Prefijo usado al desplegar (tecgurus-linux-events).
#   STAGE         Ambiente que se eliminará (inicial: lab).
#
# Efectos: vacía los dos buckets, elimina el stack de aplicación, la tabla
# DynamoDB, logs, el stack ECR y sus imágenes. Después audita todas las
# categorías del proyecto. Solicita una frase con cuenta, región y ambiente.
# Los datos no se pueden recuperar. Una segunda ejecución también debe terminar
# correctamente y confirmar que no quedaron recursos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  printf '%s\n' \
    'Uso: AWS_PROFILE=<perfil> [STAGE=lab] [AWS_REGION=us-east-1] ./scripts/destroy.sh' \
    '' \
    'Elimina permanentemente los recursos y datos de Eventos Cero.' \
    'Solicita una confirmación formada con cuenta, región y ambiente.' \
    '' \
    'STAGE selecciona qué ambiente eliminar (inicial: lab).' \
    'Debe coincidir con deploy.sh; admite 1-5 minúsculas, números o guiones.' \
    'AWS_REGION y PROJECT_NAME también deben coincidir con deploy.sh.' \
    'AWS_PROFILE debe apuntar a la misma cuenta AWS.' \
    '' \
    'Uso normal: AWS_PROFILE=perfil-alumno ./scripts/destroy.sh' \
    'Ejemplo alterno: AWS_PROFILE=perfil-alumno STAGE=a01 ./scripts/destroy.sh'
}

case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  '') ;;
  *) die "Opción no reconocida: $1. Usa --help." ;;
esac

require_aws_profile
validate_stage
for command_name in aws jq grep; do
  require_command "${command_name}"
done
ACCOUNT_ID="$(aws_cli sts get-caller-identity --query Account --output text)"
[[ "${ACCOUNT_ID}" =~ ^[0-9]{12}$ ]] || die "No fue posible identificar la cuenta AWS."

DEPLOYMENT_ID=""
if [[ -f "${DEPLOYMENT_ID_FILE}" ]]; then
  DEPLOYMENT_ID="$(tr -d '[:space:]' < "${DEPLOYMENT_ID_FILE}")"
elif stack_exists "${APP_STACK}"; then
  DEPLOYMENT_ID="$(stack_output "${APP_STACK}" DeploymentId)"
  [[ "${DEPLOYMENT_ID}" == None ]] && DEPLOYMENT_ID=""
fi
if [[ -n "${DEPLOYMENT_ID}" && ! "${DEPLOYMENT_ID}" =~ ^[a-f0-9]{6}$ ]]; then
  die "El identificador local no es válido; no se destruirá nada: ${DEPLOYMENT_ID}"
fi

WEB_BUCKET=""
MEDIA_BUCKET=""
EVENTS_TABLE=""
if stack_exists "${APP_STACK}"; then
  WEB_BUCKET="$(stack_output "${APP_STACK}" WebBucketName)"
  MEDIA_BUCKET="$(stack_output "${APP_STACK}" MediaBucketName)"
  EVENTS_TABLE="$(stack_output "${APP_STACK}" EventsTableName)"
  [[ "${WEB_BUCKET}" == None ]] && WEB_BUCKET=""
  [[ "${MEDIA_BUCKET}" == None ]] && MEDIA_BUCKET=""
  [[ "${EVENTS_TABLE}" == None ]] && EVENTS_TABLE=""
fi
if [[ -n "${DEPLOYMENT_ID}" ]]; then
  WEB_BUCKET="${WEB_BUCKET:-tecgurus-linux-events-${ACCOUNT_ID}-${AWS_REGION}-${STAGE}-${DEPLOYMENT_ID}-web}"
  MEDIA_BUCKET="${MEDIA_BUCKET:-tecgurus-linux-events-${ACCOUNT_ID}-${AWS_REGION}-${STAGE}-${DEPLOYMENT_ID}-media}"
  EVENTS_TABLE="${EVENTS_TABLE:-${PROJECT_NAME}-${STAGE}-${DEPLOYMENT_ID}-events}"
fi

EXPECTED_CONFIRMATION="DESTRUIR ${ACCOUNT_ID} ${AWS_REGION} ${STAGE}"
printf '%s\n' \
  '' \
  'Se eliminarán permanentemente estos recursos del laboratorio:' \
  "  Cuenta:       ${ACCOUNT_ID}" \
  "  Región:       ${AWS_REGION}" \
  "  Ambiente:     ${STAGE}" \
  "  Stack app:    ${APP_STACK}" \
  "  Stack ECR:    ${BOOTSTRAP_STACK}" \
  "  Tabla:        ${EVENTS_TABLE:-no encontrada}" \
  "  Bucket web:   ${WEB_BUCKET:-no encontrado}" \
  "  Bucket media: ${MEDIA_BUCKET:-no encontrado}" \
  '' \
  'La tabla y las portadas se borrarán definitivamente.'
printf 'Escribe exactamente "%s": ' "${EXPECTED_CONFIRMATION}"
read -r confirmation
[[ "${confirmation}" == "${EXPECTED_CONFIRMATION}" ]] || \
  die "Confirmación incorrecta; no se eliminó nada."

assert_project_bucket() {
  # Impide que un nombre obtenido por error apunte fuera de este proyecto.
  local bucket_name="$1"
  local expected_prefix="tecgurus-linux-events-${ACCOUNT_ID}-${AWS_REGION}-${STAGE}-"
  [[ "${bucket_name}" == "${expected_prefix}"* ]] || \
    die "Se rechazó un bucket fuera del proyecto: ${bucket_name}"
  [[ "${bucket_name}" == *-web || "${bucket_name}" == *-media ]] || \
    die "El sufijo del bucket no coincide con el proyecto: ${bucket_name}"
}

empty_bucket() {
  # Borra objetos actuales, versiones anteriores y marcadores de eliminación.
  local bucket_name="$1"
  [[ -n "${bucket_name}" ]] || return 0
  assert_project_bucket "${bucket_name}"
  if ! aws_cli s3api head-bucket --bucket "${bucket_name}" >/dev/null 2>&1; then
    return 0
  fi

  info "Vaciando s3://${bucket_name}"
  aws_cli s3 rm "s3://${bucket_name}" --recursive
  while true; do
    local versions delete_payload object_count
    versions="$(aws_cli s3api list-object-versions --bucket "${bucket_name}" --output json)"
    delete_payload="$(jq -c '{Objects: ([.Versions[]?, .DeleteMarkers[]?] | map(select(.VersionId != "null") | {Key, VersionId})), Quiet: true}' <<< "${versions}")"
    object_count="$(jq '.Objects | length' <<< "${delete_payload}")"
    [[ "${object_count}" -eq 0 ]] && break
    aws_cli s3api delete-objects \
      --bucket "${bucket_name}" --delete "${delete_payload}" >/dev/null
  done
}

empty_bucket "${WEB_BUCKET}"
empty_bucket "${MEDIA_BUCKET}"

CLEANUP_FAILED=0
if stack_exists "${APP_STACK}"; then
  info "Eliminando ${APP_STACK} (CloudFront puede tardar varios minutos)"
  aws_cli cloudformation delete-stack --stack-name "${APP_STACK}"
  if ! aws_cli cloudformation wait stack-delete-complete --stack-name "${APP_STACK}"; then
    printf 'CloudFormation no pudo eliminar completamente %s.\n' "${APP_STACK}" >&2
    CLEANUP_FAILED=1
  fi
fi

if [[ -n "${EVENTS_TABLE}" ]]; then
  EXPECTED_TABLE_PREFIX="${PROJECT_NAME}-${STAGE}-"
  [[ "${EVENTS_TABLE}" == "${EXPECTED_TABLE_PREFIX}"*-events ]] || \
    die "Se rechazó una tabla fuera del proyecto: ${EVENTS_TABLE}"
  if aws_cli dynamodb describe-table --table-name "${EVENTS_TABLE}" >/dev/null 2>&1; then
    info "Eliminando tabla DynamoDB residual exacta ${EVENTS_TABLE}"
    aws_cli dynamodb delete-table --table-name "${EVENTS_TABLE}" >/dev/null || CLEANUP_FAILED=1
    aws_cli dynamodb wait table-not-exists \
      --table-name "${EVENTS_TABLE}" || CLEANUP_FAILED=1
  fi
fi

if [[ -n "${DEPLOYMENT_ID}" ]]; then
  LOG_GROUP="/aws/lambda/${PROJECT_NAME}-${STAGE}-${DEPLOYMENT_ID}-api"
  if aws_cli logs describe-log-groups --log-group-name-prefix "${LOG_GROUP}" \
    --query "logGroups[?logGroupName=='${LOG_GROUP}'].logGroupName | [0]" \
    --output text | grep -Fqx "${LOG_GROUP}"; then
    info "Eliminando log group residual exacto ${LOG_GROUP}"
    aws_cli logs delete-log-group --log-group-name "${LOG_GROUP}" || CLEANUP_FAILED=1
  fi
fi

if stack_exists "${BOOTSTRAP_STACK}"; then
  info "Eliminando ${BOOTSTRAP_STACK} y todas sus imágenes"
  aws_cli cloudformation delete-stack --stack-name "${BOOTSTRAP_STACK}"
  if ! aws_cli cloudformation wait stack-delete-complete --stack-name "${BOOTSTRAP_STACK}"; then
    CLEANUP_FAILED=1
  fi
else
  REPOSITORY_NAME="tecgurus/linux-events-${STAGE}-api"
  if aws_cli ecr describe-repositories \
    --repository-names "${REPOSITORY_NAME}" >/dev/null 2>&1; then
    info "Eliminando el repositorio ECR residual exacto"
    aws_cli ecr delete-repository \
      --repository-name "${REPOSITORY_NAME}" --force >/dev/null || CLEANUP_FAILED=1
  fi
fi

info "Ejecutando auditoría final"
if ! "${SCRIPT_DIR}/audit.sh"; then
  CLEANUP_FAILED=1
fi

if [[ ${CLEANUP_FAILED} -ne 0 ]]; then
  die "Quedaron recursos o no pudieron auditarse; revisa la lista anterior y vuelve a ejecutar destroy.sh."
fi
if [[ -f "${DEPLOYMENT_ID_FILE}" ]]; then
  rm -- "${DEPLOYMENT_ID_FILE}"
fi
printf 'Destrucción completa. La próxima instalación generará un identificador nuevo.\n'
