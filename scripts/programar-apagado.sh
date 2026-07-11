#!/usr/bin/env bash
set -Eeuo pipefail

minutes=${1:-360}
if [[ ! $minutes =~ ^[0-9]+$ ]] || (( minutes < 30 || minutes > 720 )); then
  printf 'Uso: %s [minutos entre 30 y 720]\n' "$0" >&2
  exit 2
fi

printf 'Se programará el apagado dentro de %s minutos.\n' "$minutes"
printf 'Antes confirma en EC2 que Instance initiated shutdown behavior sea Stop.\n'
sudo shutdown -h "+$minutes"
printf 'Para cancelar: sudo shutdown -c\n'
