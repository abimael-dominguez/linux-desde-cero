#!/bin/bash

# Generar todos los números
printf "%s\n" {1..100} > all.txt
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: Números del 1 al 100 generados en all.txt" >> process.log

# Separar impares (último dígito impar)
grep -E '[13579]$' all.txt > impares.txt
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: Números impares separados en impares.txt" >> process.log

# Separar pares (último dígito par)
grep -E '[02468]$' all.txt > pares.txt
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: Números pares separados en pares.txt" >> process.log

# Generar errores
{
    echo "Error: procesamiento incompleto" >&2
    ls /archivo_falso >&2
} 2> errores.log

echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: Proceso completado" >> process.log

# Ejemplo en una sóla línea. Separar usando tee para duplicar el stream
# printf "%s\n" {1..100} | tee all.txt | tee >(grep -E '[13579]$' > impares.txt) >(grep -E '[02468]$' > pares.txt) > /dev/null
