#!/usr/bin/env bash
set -Eeuo pipefail

readonly MIN_DISK_GIB=8
errors=0
warnings=0

ok() { printf 'OK    %s\n' "$*"; }
warn() { printf 'AVISO %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'ERROR %s\n' "$*"; errors=$((errors + 1)); }

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 24.04 ]]; then
    ok "Sistema: Ubuntu ${VERSION_ID}"
  else
    fail "Se esperaba Ubuntu 24.04; se detectó ${PRETTY_NAME:-desconocido}."
  fi
else
  fail 'No se pudo leer /etc/os-release.'
fi

arch=$(uname -m)
if [[ $arch == x86_64 ]]; then
  ok "Arquitectura: $arch"
else
  warn "Arquitectura $arch: el curso se valida principalmente en x86_64."
fi

memory_mib=$(awk '/^MemTotal:/ { printf "%d", $2 / 1024 }' /proc/meminfo)
if (( memory_mib >= 1800 )); then
  profile='t3.small (2 GiB o más)'
  ok "Memoria: ${memory_mib} MiB; perfil $profile."
elif (( memory_mib >= 850 )); then
  profile='t3.micro (requiere 2 GiB de swap)'
  ok "Memoria: ${memory_mib} MiB; perfil $profile."
else
  fail "Memoria insuficiente: ${memory_mib} MiB; se requieren al menos 850 MiB."
fi

swap_mib=$(awk '/^SwapTotal:/ { printf "%d", $2 / 1024 }' /proc/meminfo)
if (( memory_mib < 1800 && swap_mib < 1800 )); then
  warn "Sólo hay ${swap_mib} MiB de swap; ejecuta: sudo bash scripts/configurar-swap.sh 2"
else
  ok "Swap disponible: ${swap_mib} MiB."
fi

disk_bytes=$(df --output=avail -B1 "$HOME" | awk 'NR == 2 { print $1 }')
disk_gib=$((disk_bytes / 1024 / 1024 / 1024))
if (( disk_gib >= MIN_DISK_GIB )); then
  ok "Espacio libre en $HOME: ${disk_gib} GiB."
else
  fail "Espacio insuficiente en $HOME: ${disk_gib} GiB; se requieren ${MIN_DISK_GIB} GiB."
fi

required=(bash awk sed grep find tar gzip sha256sum curl ssh scp ip ss systemctl)
optional=(dig tracepath shellcheck docker)

for command_name in "${required[@]}"; do
  if command -v "$command_name" >/dev/null 2>&1; then
    ok "Comando disponible: $command_name"
  else
    fail "Falta el comando requerido: $command_name"
  fi
done

for command_name in "${optional[@]}"; do
  if command -v "$command_name" >/dev/null 2>&1; then
    ok "Comando disponible: $command_name"
  else
    warn "Falta $command_name; se necesitará en sesiones posteriores."
  fi
done

instance_type='no detectado (esto es normal fuera de EC2)'
if command -v curl >/dev/null 2>&1; then
  token=$(curl --silent --show-error --fail --max-time 1 \
    --request PUT \
    --header 'X-aws-ec2-metadata-token-ttl-seconds: 60' \
    http://169.254.169.254/latest/api/token 2>/dev/null || true)
  if [[ -n $token ]]; then
    instance_type=$(curl --silent --show-error --fail --max-time 1 \
      --header "X-aws-ec2-metadata-token: $token" \
      http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || true)
  fi
fi
printf '\nPerfil del laboratorio\n'
printf '  Instancia EC2: %s\n' "${instance_type:-desconocida}"
printf '  Errores:       %d\n' "$errors"
printf '  Avisos:        %d\n' "$warnings"

(( errors == 0 ))
