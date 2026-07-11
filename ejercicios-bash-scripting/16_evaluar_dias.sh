#!/usr/bin/env bash
set -o nounset

case ${1:-} in
  Monday|Tuesday|Wednesday|Thursday|Friday)
    printf 'Es un día de semana\n' ;;
  Saturday|Sunday)
    printf 'Es fin de semana\n' ;;
  *)
    printf 'Día no reconocido\n' >&2
    exit 64 ;;
esac
