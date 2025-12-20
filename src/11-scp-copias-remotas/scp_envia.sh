#!/bin/bash
# Script para enviar un archivo por SCP con autenticación por clave RSA
# Uso: ./scp_envia.sh <archivo_local> <usuario> <host> <ruta_destino>

set -e

ARCHIVO_LOCAL="$1"
USUARIO="$2"
HOST="$3"
RUTA_DESTINO="$4"
CLAVE_RSA="$HOME/.ssh/id_rsa"

if [[ -z "$ARCHIVO_LOCAL" || -z "$USUARIO" || -z "$HOST" || -z "$RUTA_DESTINO" ]]; then
  echo "[ERROR] Uso: $0 <archivo_local> <usuario> <host> <ruta_destino>"
  exit 1
fi

if [[ ! -f "$ARCHIVO_LOCAL" ]]; then
  echo "[ERROR] El archivo '$ARCHIVO_LOCAL' no existe."
  exit 2
fi

# 1. Verificar si existe clave RSA, si no, crearla
if [[ ! -f "$CLAVE_RSA" ]]; then
  echo "[INFO] No se encontró clave RSA. Generando nueva clave..."
  ssh-keygen -t rsa -b 2048 -N "" -f "$CLAVE_RSA"
  echo "[OK] Clave RSA generada en $CLAVE_RSA"
else
  echo "[INFO] Clave RSA ya existe en $CLAVE_RSA"
fi

# 2. Copiar clave pública al host remoto (requiere password la primera vez)
echo "[INFO] Copiando clave pública al host remoto ($USUARIO@$HOST)..."
sshpass -p 'TU_PASSWORD_AQUI' ssh-copy-id -i "$CLAVE_RSA.pub" "$USUARIO@$HOST"
echo "[OK] Clave pública copiada."

# 3. Enviar archivo por SCP usando clave RSA
echo "[INFO] Enviando archivo '$ARCHIVO_LOCAL' a $USUARIO@$HOST:$RUTA_DESTINO ..."
scp -i "$CLAVE_RSA" "$ARCHIVO_LOCAL" "$USUARIO@$HOST:$RUTA_DESTINO"
if [[ $? -eq 0 ]]; then
  echo "[OK] Archivo enviado correctamente."
else
  echo "[ERROR] Falló la transferencia."
  exit 3
fi
