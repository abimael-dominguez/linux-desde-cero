#!/usr/bin/env bash

# lib.sh — Configuración y funciones compartidas por los scripts de AWS.
#
# No se ejecuta directamente. Los demás scripts lo importan así:
#   source "${SCRIPT_DIR}/lib.sh"
#
# Variables recibidas del ambiente y sus valores iniciales:
#   AWS_PROFILE=<sin valor; es obligatorio indicarlo al ejecutar>
#   AWS_REGION=us-east-1
#   PROJECT_NAME=tecgurus-linux-events
#   STAGE=lab (ambiente independiente; normalmente se omite)
#
# STAGE forma parte de los nombres y etiquetas de recursos, pero no cambia la
# plantilla ni la aplicación. Permite separar ambientes en una misma cuenta.
# Por el límite de nombres S3 admite 1-5 minúsculas, números o guiones, sin
# guión al inicio o al final. Debe repetirse en deploy.sh, audit.sh y destroy.sh.
# Ejemplo de ambiente adicional para una sola ejecución:
#   AWS_PROFILE=perfil-alumno STAGE=a01 ./scripts/deploy.sh
#
# Variables calculadas: PROJECT_ROOT, BOOTSTRAP_STACK, APP_STACK y
# DEPLOYMENT_ID_FILE. Funciones disponibles: aws_cli, stack_exists,
# stack_output, recover_rollback_complete_stack, resolve_deployment_id,
# assert_bucket_name, validate_stage, info y die.
# Las credenciales siempre se leen de los archivos estándar de AWS CLI.
# shellcheck disable=SC2034
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="${PROJECT_NAME:-tecgurus-linux-events}"
STAGE="${STAGE:-lab}"
AWS_PROFILE="${AWS_PROFILE:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
BOOTSTRAP_STACK="${PROJECT_NAME}-${STAGE}-bootstrap"
APP_STACK="${PROJECT_NAME}-${STAGE}-app"
DEPLOYMENT_ID_FILE="${PROJECT_ROOT}/.aws/deployment-id"

export AWS_PROFILE AWS_REGION
export AWS_DEFAULT_REGION="${AWS_REGION}"
export AWS_PAGER=""

die() {
  # Muestra un error uniforme y detiene el script.
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

info() {
  # Separa visualmente cada fase importante.
  printf '\n==> %s\n' "$*"
}

require_command() {
  # Falla temprano si una herramienta externa no está instalada.
  command -v "$1" >/dev/null 2>&1 || die "Falta el comando requerido: $1"
}

require_aws_profile() {
  # Evita usar por accidente el perfil default o la cuenta de otro laboratorio.
  [[ -n "${AWS_PROFILE}" ]] || \
    die "AWS_PROFILE es obligatorio. Ejemplo: AWS_PROFILE=mi-perfil $0"
}

validate_stage() {
  # Falla antes de crear recursos si STAGE no puede formar nombres AWS seguros.
  [[ ${#STAGE} -ge 1 && ${#STAGE} -le 5 ]] || \
    die "STAGE debe tener entre 1 y 5 caracteres; valor actual: ${STAGE}"
  [[ "${STAGE}" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || \
    die "STAGE solo admite minúsculas, números y guiones, sin guión al inicio o final: ${STAGE}"
}

aws_cli() {
  # Ejecuta AWS CLI usando siempre el perfil y la región seleccionados.
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" --no-cli-pager "$@"
}

stack_exists() {
  # Devuelve éxito solamente si CloudFormation encuentra el stack.
  aws_cli cloudformation describe-stacks --stack-name "$1" >/dev/null 2>&1
}

stack_output() {
  # Imprime un OutputValue del stack para poder capturarlo con $(...).
  local stack_name="$1"
  local output_key="$2"
  aws_cli cloudformation describe-stacks \
    --stack-name "${stack_name}" \
    --query "Stacks[0].Outputs[?OutputKey=='${output_key}'].OutputValue | [0]" \
    --output text
}

recover_rollback_complete_stack() {
  # Un stack ROLLBACK_COMPLETE no se puede actualizar; borra solo ese intento
  # fallido y espera su eliminación para permitir un despliegue idempotente.
  local stack_name="$1"
  local stack_status
  stack_exists "${stack_name}" || return 0
  stack_status="$(aws_cli cloudformation describe-stacks \
    --stack-name "${stack_name}" \
    --query 'Stacks[0].StackStatus' \
    --output text)"
  if [[ "${stack_status}" == ROLLBACK_COMPLETE ]]; then
    info "Eliminando intento fallido ${stack_name} (${stack_status})"
    aws_cli cloudformation delete-stack --stack-name "${stack_name}"
    aws_cli cloudformation wait stack-delete-complete --stack-name "${stack_name}"
  fi
}

resolve_deployment_id() {
  # Reutiliza el id del ciclo actual o crea uno aleatorio de seis caracteres.
  local deployment_id=""

  if [[ -f "${DEPLOYMENT_ID_FILE}" ]]; then
    deployment_id="$(tr -d '[:space:]' < "${DEPLOYMENT_ID_FILE}")"
  elif stack_exists "${APP_STACK}"; then
    deployment_id="$(stack_output "${APP_STACK}" DeploymentId)"
    umask 077
    printf '%s\n' "${deployment_id}" > "${DEPLOYMENT_ID_FILE}"
  else
    require_command openssl
    umask 077
    deployment_id="$(openssl rand -hex 3)"
    printf '%s\n' "${deployment_id}" > "${DEPLOYMENT_ID_FILE}"
  fi

  [[ "${deployment_id}" =~ ^[a-f0-9]{6}$ ]] || \
    die "El identificador de despliegue no es válido: ${deployment_id}"
  printf '%s\n' "${deployment_id}"
}

assert_bucket_name() {
  # Comprueba longitud y caracteres permitidos antes de operar sobre S3.
  local bucket_name="$1"
  [[ ${#bucket_name} -le 63 ]] || die "El bucket excede 63 caracteres: ${bucket_name}"
  [[ "${bucket_name}" =~ ^[a-z0-9][a-z0-9.-]+[a-z0-9]$ ]] || \
    die "Nombre de bucket no válido: ${bucket_name}"
}
