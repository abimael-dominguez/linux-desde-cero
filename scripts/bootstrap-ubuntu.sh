#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -eq 0 ]]; then
  printf 'Ejecuta este script como el usuario ubuntu, no como root. Usará sudo cuando sea necesario.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != ubuntu || ${VERSION_ID:-} != 24.04 ]]; then
  printf 'Este bootstrap sólo admite Ubuntu 24.04. Detectado: %s\n' "${PRETTY_NAME:-desconocido}" >&2
  exit 1
fi

docker_already_valid=false
if command -v docker >/dev/null 2>&1; then
  if ! docker compose version >/dev/null 2>&1; then
    printf 'Docker ya existe, pero falta Compose v2. No se mezclará otra instalación.\n' >&2
    printf 'Usa una VM limpia o retira el canal anterior antes del bootstrap.\n' >&2
    exit 1
  fi

  if command -v snap >/dev/null 2>&1 && snap list docker >/dev/null 2>&1; then
    printf 'Se detectó Docker mediante Snap; el curso usa Docker CE de APT.\n' >&2
    printf 'Usa una VM limpia para evitar dos daemons y ciclos de actualización.\n' >&2
    exit 1
  fi

  if dpkg-query -W -f='${db:Status-Abbrev}' docker.io 2>/dev/null \
    | grep --quiet '^ii'; then
    printf 'Se detectó docker.io; el curso usa Docker CE y no mezclará canales.\n' >&2
    printf 'Usa una VM limpia o retira conscientemente la instalación anterior.\n' >&2
    exit 1
  fi
  docker_already_valid=true
fi

printf 'Se instalarán herramientas del curso en esta máquina desechable.\n'
printf 'No se ejecutará apt upgrade ni se modificarán reglas de red.\n'
sudo -v

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates \
  cron \
  curl \
  dnsutils \
  e2fsprogs \
  file \
  git \
  htop \
  iputils-ping \
  iputils-tracepath \
  jq \
  less \
  lsof \
  lvm2 \
  netcat-openbsd \
  openssl \
  openssh-client \
  parted \
  procps \
  rsync \
  shellcheck \
  traceroute \
  tree \
  ufw \
  vim-tiny

if [[ $docker_already_valid != true ]]; then
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl --fail --silent --show-error --location \
    https://download.docker.com/linux/ubuntu/gpg \
    --output /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  arch=$(dpkg --print-architecture)
  codename=${UBUNTU_CODENAME:-$VERSION_CODENAME}
  temporary_source=$(mktemp)
  trap 'rm -f -- "$temporary_source"' EXIT
  printf '%s\n' \
    'Types: deb' \
    'URIs: https://download.docker.com/linux/ubuntu' \
    "Suites: $codename" \
    'Components: stable' \
    "Architectures: $arch" \
    'Signed-By: /etc/apt/keyrings/docker.asc' > "$temporary_source"
  sudo install -m 0644 "$temporary_source" /etc/apt/sources.list.d/docker.sources

  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin
fi

sudo systemctl enable --now cron docker

printf '\nBootstrap terminado. Verificación:\n'
printf '  Docker:  %s\n' "$(sudo docker version --format '{{.Server.Version}}')"
printf '  Compose: %s\n' "$(sudo docker compose version --short)"
printf '  Cron:    %s\n' "$(systemctl is-active cron)"
printf '\nDocker se utilizará con sudo; no se añadió al usuario al grupo docker, que equivale a privilegios de root.\n'
