#!/bin/bash
LOGFILE="$1"
if [[ ! -f "$LOGFILE" ]]; then
  echo "Uso: $0 <archivo_log>"
  exit 1
fi
echo "Resumen de $LOGFILE:"
echo "----------------------"
echo "Errores:   $(grep -c 'ERROR' "$LOGFILE")"
echo "Warnings:  $(grep -c 'WARN' "$LOGFILE")"
echo "Infos:     $(grep -c 'INFO' "$LOGFILE")"
echo "Usuarios únicos:"
grep -oE 'User [a-z]+' "$LOGFILE" | awk '{print $2}' | sort | uniq
