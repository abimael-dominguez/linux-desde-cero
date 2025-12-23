#!/bin/bash
echo "Iniciando proceso largo..."
for i in {1..10}; do
    echo "Iteración $i - $(date)"
    sleep 60  # Espera 1 minuto por iteración
done
echo "Proceso completado."