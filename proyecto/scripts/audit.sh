#!/usr/bin/env bash

# audit.sh — Comprueba que no queden recursos de Eventos Cero en AWS.
#
# Uso:
#   AWS_PROFILE=perfil-alumno ./scripts/audit.sh
#   ./scripts/audit.sh --help
#
# AWS_PROFILE es obligatorio y debe apuntar a la misma cuenta usada al desplegar.
# STAGE selecciona el ambiente que se revisará; su valor inicial es lab. Si se
# usó otro STAGE durante deploy.sh, debe repetirse exactamente aquí. AWS_REGION
# y PROJECT_NAME deben coincidir también.
#
# Este script es de solo lectura. Devuelve 0 cuando la auditoría está limpia y
# 1 si encuentra recursos o no tiene permisos para revisar alguna categoría.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  printf '%s\n' \
    'Uso: AWS_PROFILE=<perfil> [STAGE=lab] [AWS_REGION=us-east-1] ./scripts/audit.sh' \
    '' \
    'Busca residuos del proyecto sin crear, modificar ni borrar recursos.' \
    'Devuelve código 0 si no encuentra nada y código 1 en caso contrario.' \
    '' \
    'STAGE selecciona qué ambiente revisar (inicial: lab).' \
    'Debe coincidir con deploy.sh; admite 1-5 minúsculas, números o guiones.' \
    'AWS_REGION y PROJECT_NAME también deben coincidir con deploy.sh.' \
    'AWS_PROFILE debe apuntar a la misma cuenta AWS.' \
    '' \
    'Uso normal: AWS_PROFILE=perfil-alumno ./scripts/audit.sh' \
    'Ejemplo alterno: AWS_PROFILE=perfil-alumno STAGE=a01 ./scripts/audit.sh'
}

case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  '') ;;
  *) die "Opción no reconocida: $1. Usa --help." ;;
esac

require_aws_profile
validate_stage
require_command aws
ACCOUNT_ID="$(aws_cli sts get-caller-identity --query Account --output text)"
PREFIX="${PROJECT_NAME}-${STAGE}"
BUCKET_PREFIX="tecgurus-linux-events-${ACCOUNT_ID}-${AWS_REGION}-${STAGE}-"
RESIDUES=0

check() {
  # Ejecuta una consulta de solo lectura y cuenta como residuo su salida o error.
  local label="$1"
  shift
  local output
  if ! output="$("$@" 2>&1)"; then
    printf 'No se pudo auditar %-18s %s\n' "${label}:" "${output}" >&2
    RESIDUES=$((RESIDUES + 1))
    return
  fi
  output="$(printf '%s' "${output}" | sed '/^[[:space:]]*$/d; /^None$/d')"
  if [[ -n "${output}" ]]; then
    printf 'Residuo %-22s %s\n' "${label}:" "${output}"
    RESIDUES=$((RESIDUES + 1))
  fi
}

info "Auditando residuos de ${PROJECT_NAME} en ${ACCOUNT_ID}/${AWS_REGION}"
check CloudFormation aws_cli cloudformation list-stacks \
  --query "StackSummaries[?starts_with(StackName, '${PREFIX}') && StackStatus!='DELETE_COMPLETE'].StackName" \
  --output text
check S3 aws_cli s3api list-buckets \
  --query "Buckets[?starts_with(Name, '${BUCKET_PREFIX}')].Name" --output text
check ECR aws_cli ecr describe-repositories \
  --query "repositories[?repositoryName=='tecgurus/linux-events-${STAGE}-api'].repositoryName" \
  --output text
check Lambda aws_cli lambda list-functions \
  --query "Functions[?starts_with(FunctionName, '${PREFIX}')].FunctionName" --output text
check API-Gateway aws_cli apigatewayv2 get-apis \
  --query "Items[?starts_with(Name, '${PREFIX}')].Name" --output text
check DynamoDB aws_cli dynamodb list-tables \
  --query "TableNames[?starts_with(@, '${PREFIX}')]" --output text
check Logs aws_cli logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/${PREFIX}" \
  --query 'logGroups[].logGroupName' --output text
check IAM-roles aws_cli iam list-roles \
  --query "Roles[?starts_with(RoleName, '${PREFIX}')].RoleName" --output text
check CloudFront aws_cli cloudfront list-distributions \
  --query "DistributionList.Items[?starts_with(Comment, '${PREFIX}')].[Id,DomainName]" \
  --output text
check CloudFront-OAC aws_cli cloudfront list-origin-access-controls \
  --query "OriginAccessControlList.Items[?starts_with(Name, '${PREFIX}')].Id" \
  --output text
check CloudFront-cache aws_cli cloudfront list-cache-policies --type custom \
  --query "CachePolicyList.Items[?starts_with(CachePolicy.CachePolicyConfig.Name, '${PREFIX}')].CachePolicy.Id" \
  --output text
check CloudFront-origin aws_cli cloudfront list-origin-request-policies --type custom \
  --query "OriginRequestPolicyList.Items[?starts_with(OriginRequestPolicy.OriginRequestPolicyConfig.Name, '${PREFIX}')].OriginRequestPolicy.Id" \
  --output text
check CloudFront-headers aws_cli cloudfront list-response-headers-policies --type custom \
  --query "ResponseHeadersPolicyList.Items[?starts_with(ResponseHeadersPolicy.ResponseHeadersPolicyConfig.Name, '${PREFIX}')].ResponseHeadersPolicy.Id" \
  --output text
if [[ ${RESIDUES} -ne 0 ]]; then
  printf '\nAuditoría con %s categoría(s) pendiente(s).\n' "${RESIDUES}" >&2
  exit 1
fi
printf 'Auditoría limpia: no se encontraron recursos del proyecto.\n'
