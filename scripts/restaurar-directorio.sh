#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  printf 'Uso: %s <respaldo.tar.gz> <directorio_destino_vacio>\n' "$0"
}

if (( $# != 2 )); then
  usage >&2
  exit 2
fi

archive=$(realpath -- "$1")
checksum="$archive.sha256"
destination=$(realpath --canonicalize-missing "$2")

if [[ ! -f $archive || ! -f $checksum ]]; then
  printf 'Falta el respaldo o su archivo .sha256.\n' >&2
  exit 1
fi

mkdir -p -- "$destination"
if find "$destination" -mindepth 1 -print -quit | grep --quiet .; then
  printf 'El destino debe estar vacío: %s\n' "$destination" >&2
  exit 1
fi

(
  cd -- "$(dirname -- "$archive")"
  sha256sum --check "$(basename -- "$checksum")"
)

tar --extract --gzip --file "$archive" --directory "$destination"
printf 'Restauración verificada en: %s\n' "$destination"
