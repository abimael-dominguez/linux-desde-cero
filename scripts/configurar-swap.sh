#!/usr/bin/env bash
set -Eeuo pipefail

readonly SWAP_FILE=/swapfile-consultor-linux
readonly FSTAB_LINE="$SWAP_FILE none swap sw 0 0"
readonly SYSCTL_FILE=/etc/sysctl.d/99-consultor-linux-swap.conf

usage() {
  printf 'Uso:\n  sudo bash %s <1|2>\n  sudo bash %s --eliminar\n' "$0" "$0"
}

if [[ ${EUID} -ne 0 ]]; then
  printf 'Este script necesita privilegios. Ejemplo: sudo bash %s 2\n' "$0" >&2
  exit 1
fi

if [[ ${1:-} == --eliminar ]]; then
  if swapon --show=NAME --noheadings | grep --fixed-strings --line-regexp --quiet "$SWAP_FILE"; then
    swapoff "$SWAP_FILE"
  fi
  sed -i "\|^${SWAP_FILE//|/\\|}[[:space:]]|d" /etc/fstab
  rm -f -- "$SWAP_FILE" "$SYSCTL_FILE"
  sysctl --system >/dev/null
  printf 'Swap del curso eliminada.\n'
  exit 0
fi

size_gib=${1:-}
if [[ $size_gib != 1 && $size_gib != 2 ]]; then
  usage >&2
  exit 2
fi

if [[ -e $SWAP_FILE ]] && ! file "$SWAP_FILE" | grep --quiet 'swap file'; then
  printf 'Se abortó: %s existe, pero no es una swap reconocible.\n' "$SWAP_FILE" >&2
  exit 1
fi

if [[ -e $SWAP_FILE ]]; then
  desired_bytes=$((size_gib * 1024 * 1024 * 1024))
  actual_bytes=$(stat --format=%s "$SWAP_FILE")
  if (( actual_bytes != desired_bytes )); then
    printf 'Se abortó: %s ya mide %s bytes; se solicitaron %s GiB.\n' \
      "$SWAP_FILE" "$actual_bytes" "$size_gib" >&2
    printf 'Con memoria suficiente, elimínala explícitamente con --eliminar y vuelve a crearla.\n' >&2
    exit 1
  fi
fi

if [[ ! -e $SWAP_FILE ]]; then
  fallocate --length "${size_gib}G" "$SWAP_FILE"
  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE"
fi

if ! swapon --show=NAME --noheadings | grep --fixed-strings --line-regexp --quiet "$SWAP_FILE"; then
  swapon "$SWAP_FILE"
fi

if ! grep --fixed-strings --line-regexp --quiet "$FSTAB_LINE" /etc/fstab; then
  printf '%s\n' "$FSTAB_LINE" >> /etc/fstab
fi

printf 'vm.swappiness=10\n' > "$SYSCTL_FILE"
sysctl --load "$SYSCTL_FILE" >/dev/null

printf 'Swap configurada en %s.\n' "$SWAP_FILE"
swapon --show "$SWAP_FILE"
sysctl vm.swappiness
