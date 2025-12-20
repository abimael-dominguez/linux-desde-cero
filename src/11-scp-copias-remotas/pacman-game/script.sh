#!/bin/bash

# ==============================================================================
# Script para compilar y ejecutar el juego de Pac-Man en C.
# Requiere gcc y la biblioteca ncurses.
# Uso: ./script.sh
# ==============================================================================

# --- Obtener la ruta del script ---
# Para obtener la carpeta en donde está localizado el script.
# Esto asegura que todos los archivos se lean y escriban en el directorio
# del script (pacman-game), sin importar desde dónde se llame.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --- PASO 1: Preparar el entorno (dependencias del compilador y ncurses) ---
echo "-> 1. Instalando dependencias (build-essential, libncurses-dev)..."
sudo apt update > /dev/null 2>&1
sudo apt install -y build-essential libncurses-dev

# --- PASO 2: Definir rutas absolutas (fuente y ejecutable) ---
# Usamos SCRIPT_DIR como base para todas las rutas para que el script funcione
# igual se lance desde la raíz del repo o desde pacman-game/.
SOURCE_FILE="$SCRIPT_DIR/pacman.c"
EXECUTABLE="$SCRIPT_DIR/pacman_game"

echo "   -> Código fuente: $SOURCE_FILE"
echo "   -> Ejecutable final: $EXECUTABLE"

# --- PASO 3: Compilar y enlazar directamente con gcc ---
echo -e "\n-> 3. Limpiando y compilando directamente con gcc..."
rm -f "$SCRIPT_DIR/pacman.o" "$EXECUTABLE" > /dev/null 2>&1
if ! gcc -Wall -Wextra -Wpedantic -std=c11 -O2 "$SOURCE_FILE" -o "$EXECUTABLE" -lncurses; then
    echo "   -> ERROR: La compilación falló."
    exit 1
fi
echo "   -> ¡Compilación exitosa! Ejecutable '$EXECUTABLE' creado."
ls -l "$EXECUTABLE"

# --- PASO 4: Ejecutar el juego ---
echo -e "\n-> 4. ¡A jugar! (Usa las flechas para moverte, 'q' para salir)"
sleep 1
"$EXECUTABLE"

# --- PASO 5: Mostrar resultado final ---
echo -e "\n-> Proceso completado."
