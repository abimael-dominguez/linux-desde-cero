#!/bin/bash
# Script: busqueda_avanzada.sh
# Uso: ./busqueda_avanzada.sh <archivo_log> <regex>

if [[ $# -ne 2 ]]; then
  echo "Uso: $0 <archivo_log> <regex>"
  exit 1
fi

LOGFILE="$1"
PATRON="$2"

if [[ ! -f "$LOGFILE" ]]; then
  echo "Archivo $LOGFILE no encontrado."
  exit 2
fi

echo "Buscando patrón: $PATRON en $LOGFILE"
grep -En "$PATRON" "$LOGFILE"
