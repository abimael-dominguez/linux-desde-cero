#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  printf 'Uso: %s <directorio_origen> <directorio_destino>\n' "$0"
}

if (( $# != 2 )); then
  usage >&2
  exit 2
fi

# Los respaldos pueden contener configuración o datos sensibles.
umask 077

origin=$(realpath -- "$1")
destination=$(realpath --canonicalize-missing "$2")

if [[ ! -d $origin ]]; then
  printf 'El origen no es un directorio: %s\n' "$origin" >&2
  exit 1
fi

case "$destination/" in
  "$origin/"*)
    printf 'El destino no puede estar dentro del origen.\n' >&2
    exit 1
    ;;
esac

install -d -m 0700 -- "$destination"
timestamp=${FECHA_RESPALDO:-$(date --utc +%Y%m%dT%H%M%SZ)}
archive="respaldo-${timestamp}.tar.gz"

if [[ -e $destination/$archive || -e $destination/$archive.sha256 ]]; then
  printf 'Ya existe un respaldo con esa marca: %s\n' "$destination/$archive" >&2
  exit 1
fi

tar --create --gzip --file "$destination/$archive" \
  --directory "$(dirname -- "$origin")" \
  "$(basename -- "$origin")"

(
  cd -- "$destination"
  sha256sum "$archive" > "$archive.sha256"
)
chmod 0600 "$destination/$archive" "$destination/$archive.sha256"

printf 'Respaldo: %s\n' "$destination/$archive"
printf 'Checksum: %s\n' "$destination/$archive.sha256"
