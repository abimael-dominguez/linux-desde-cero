# 12. Hands-on Bash Scripting

Este módulo cubre conceptos prácticos de scripting en Bash. Aprenderemos a usar comandos, variables, estructuras de control y más, con ejercicios resueltos. Los datos para los ejercicios se encuentran en la carpeta `./data`.

## Índice

- [1. Pipes y Comandos Básicos](#1-pipes-y-comandos-básicos)
  - [01_contar_ganadores.sh](#contar-equipos-ganadores-únicos)
  - [02_contar_variante.sh](#contar-apariciones-de-lakers-y-celtics)
  - [03_egrep_variante.sh](#03_egrep_variante.sh)
- [2. Edición de Archivos con sed](#2-edición-de-archivos-con-sed)
  - [03_editar_equipos.sh](#editar-nombres-de-equipos-con-sed)
- [3. Variables y Argumentos (STDIN, STDOUT, STDERR, ARGV)](#3-variables-y-argumentos-stdin-stdout-stderr-argv)
  - [04_separar_numeros.sh](#ejercicio-separar-números-pares-e-impares)
  - [05_argumentos.sh](#manejo-de-argumentos-en-scripts)
  - [06_grep_parametrizado.sh](#búsqueda-parametrizada-en-hire_data)
- [4. Cálculos con bc](#4-cálculos-con-bc)
  - [07_convertir_temperatura.sh](#conversión-de-temperaturas-con-bc)
  - [08_leer_temperaturas.sh](#leer-temperaturas-de-archivos)
- [5. Arrays](#5-arrays)
  - [09_array_capitales.sh](#trabajar-con-arrays-indexados)
  - [11_calcular_promedio_arrays.sh](#calcular-promedio-con-arrays)
- [6. Estructuras de Control: If](#6-estructuras-de-control-if)
  - [12_mover_modelos.sh](#mover-modelos-basado-en-precisión)
  - [13_mover_logs.sh](#mover-logs-basado-en-contenido)
- [7. Bucles: For](#7-bucles-for)
  - [16_mover_archivos_python.sh](#mover-archivos-python-con-condición)
- [8. Case Statements](#8-case-statements)
  - [17_clasificar_modelos.sh](#clasificar-modelos-con-case)
- [9. Funciones](#9-funciones)
  - [18_subir_nube.sh](#función-para-subir-a-la-nube)
  - [19_obtener_dia.sh](#obtener-el-día-actual)
  - [20_calcular_porcentaje.sh](#calcular-porcentaje)
  - [21_contar_victorias.sh](#contar-victorias-de-un-equipo)
  - [22_sumar_array.sh](#sumar-elementos-de-un-array)
- [10. Cron Jobs](#10-cron-jobs)

## Recursos Útiles

- Para evaluar expresiones regulares: [Regex101.com](https://regex101.com/)
- Para programar tareas con cron: [Crontab Guru](https://crontab.guru/)

## 1. Pipes y Comandos Básicos

Los pipes (`|`) permiten conectar la salida de un comando a la entrada de otro. Usaremos datos del archivo `basketball_scores.csv` ubicado en `./data/basketball_scores.csv`.

### Ejercicio: Contar apariciones de nombres en un archivo

Primero, veamos el contenido del archivo:

```bash
head -5 ./data/basketball_scores.csv
```

Salida esperada:
```
Year, Winner, Winner Points
2020,Lakers,120
2021,Bucks,125
2022,Warriors,118
2023,Celtics,122
2024,Lakers,115
```

Ahora, contemos las apariciones de "Lakers" y "Celtics" en un archivo de texto (ejemplo hipotético, adaptado a nuestros datos). Para nuestros datos, contemos los equipos ganadores únicos.

#### Contar Equipos Ganadores Únicos

Utiliza la base de datos: `basketball_scores.csv`

Crear el archivo:
```bash
touch 01_contar_ganadores.sh
```

```bash
#!/bin/bash

cat ./data/basketball_scores.csv | cut -d "," -f 2 | tail -n +2 | sort | uniq -c | sort
```

Ejecuta el script:
```bash
chmod +x 01_contar_ganadores.sh
./01_contar_ganadores.sh
```

Explicación de comandos y flags:
- `cat`: imprime el contenido del archivo.
- `cut -d "," -f 2`: especifica el delimitador (coma) y selecciona el campo 2.
- `tail -n +2`: muestra desde la línea 2 en adelante.
- `sort`: ordena líneas alfabéticamente (orden por defecto).
- `uniq -c`: cuenta líneas duplicadas consecutivas.
- `sort`: ordena líneas alfabéticamente nuevamente (orden por defecto).

### Variante con grep

#### Contar Apariciones de Lakers y Celtics

Utiliza la base de datos: `basketball_scores.csv`

Crear el archivo:
```bash
touch 02_contar_variante.sh
```

```bash
#!/bin/bash

cat ./data/basketball_scores.csv | grep -e "Lakers" -e "Celtics" | wc -l
```

Explicación de comandos y flags:
- `cat`: imprime el contenido del archivo.
- `grep -e`: especifica patrón.
- `wc -l`: cuenta líneas.

#### 03_egrep_variante.sh

O con egrep (equivalente a grep -E):

Crear el archivo:
```bash
touch 03_egrep_variante.sh
```

```bash
#!/bin/bash

cat ./data/basketball_scores.csv | egrep 'Lakers|Celtics' | wc -l
```

Explicación de comandos y flags:
- `cat`: imprime el contenido del archivo.
- `egrep 'Lakers|Celtics'`: busca líneas que contengan "Lakers" o "Celtics" (equivalente a grep -E).
- `wc -l`: cuenta el número de líneas.

## 2. Edición de Archivos con sed

Usaremos `sed` para reemplazar texto en el archivo.

#### Editar Nombres de Equipos con sed

Utiliza la base de datos: `basketball_scores.csv`

Crear el archivo:
```bash
touch 03_editar_equipos.sh
```

```bash
#!/bin/bash

cat ./data/basketball_scores.csv | sed 's/Lakers/LA Lakers/g' | sed 's/Celtics/Boston Celtics/g' > ./data/basketball_scores_edited.csv
```

Ejecuta:
```bash
./03_editar_equipos.sh
head -5 ./data/basketball_scores_edited.csv
```

Explicación de comandos y flags:
`sed 's/patrón/reemplazo/g'`: substituye globalmente.

- `cat`: imprime el contenido del archivo.
- `sed 's/Lakers/LA Lakers/g'`: substituye globalmente "Lakers" por "LA Lakers".
- `sed 's/Celtics/Boston Celtics/g'`: substituye globalmente "Celtics" por "Boston Celtics".
- `>`: redirige la salida al archivo especificado.

## 3. Variables y Argumentos (STDIN, STDOUT, STDERR, ARGV)

### Ejercicio: Separar números pares e impares

Crea un script que genere los números del 1 al 100, los separe en pares e impares en archivos separados (`pares.txt` e `impares.txt`), y genere errores en `errores.log`.

Crear el archivo:
```bash
touch 04_separar_numeros.sh
```

Ejemplo:

```bash
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

```

#### Explicación de Descriptores Estándar
- **stdin**: Descriptor 0. No usado aquí.
- **stdout**: Descriptor 1. `printf` y `grep` envían salida a archivos con `>`. Nota: `>` es equivalente a `1>`, redirige stdout sobrescribiendo el archivo.
- **stderr**: Descriptor 2. `echo` y `ls` fallido se redirigen con `2>` al final del bloque. Nota: El bloque `{ ... }` agrupa comandos para redirigir su stderr colectivamente.

Nota: `>&2` redirige stdout al descriptor 2 (stderr), útil para enviar mensajes de error.

Ejecuta el script y verifica los archivos.

```bash
./04_separar_numeros.sh
```


### Manejo de Argumentos en Scripts

Los argumentos se pasan al script como `$1`, `$2`, etc. `$*` y `$@` representan todos los argumentos (con diferencias en cómo se expanden dentro de comillas), `$#` es el número de argumentos.

Crear el archivo:
```bash
touch 05_argumentos.sh
```

```bash
#!/bin/bash

# Imprime el primer y segundo argumento
echo "Primer argumento: $1"
echo "Segundo argumento: $2"

# Imprime todos los argumentos
echo "Todos los argumentos: $*"

# Imprime el número de argumentos
echo "Número de argumentos: $#"
```

Ejecuta con argumentos:
```bash
./05_argumentos.sh hola mundo
```

Los archivos están en `./data/hire_data/`.

#### Búsqueda Parametrizada en hire_data

Utiliza la base de datos: archivos en `hire_data/`

Crear el archivo:
```bash
touch 06_grep_parametrizado.sh
```

```bash
#!/bin/bash

# Busca el primer argumento en todos los archivos CSV de hire_data
# grep "$1": busca el patrón en la entrada
# > "$1".csv: guarda en archivo nombrado con el argumento

cat ./data/hire_data/*.csv | grep "$1" > "./data/$1.csv"
```

Ejemplo:
```bash
./06_grep_parametrizado.sh "Engineer"
```

Explicación de comandos y flags:
- `cat ./data/hire_data/*.csv`: concatena todos los archivos CSV en hire_data.
- `grep "$1"`: busca líneas que contengan el primer argumento.
- `> "./data/$1.csv"`: redirige la salida a un archivo CSV nombrado con el argumento.

## 4. Cálculos con bc

Usa `bc` para cálculos de punto flotante.

#### Conversión de Temperaturas con bc

Crear el archivo:
```bash
touch 07_convertir_temperatura.sh
```

```bash
#!/bin/bash

temp_f=$1
temp_f2=$(echo "scale=2; $temp_f - 32" | bc)
temp_c=$(echo "scale=2; $temp_f2 * 5 / 9" | bc)
echo "$temp_f F es $temp_c C"
```

Ejecuta:
```bash
./07_convertir_temperatura.sh 100
```

Explicación de comandos y flags:
- `scale=2`: dos decimales.
- `bc`: ejecuta cálculo.

Suponiendo archivos en `./data/temps/region_A`, etc.

#### Leer Temperaturas de Archivos

Utiliza archivos en: `temps/`

Crear el archivo:
```bash
touch 08_leer_temperaturas.sh
```

```bash
#!/bin/bash

# Lee temperaturas de archivos
temp_a=$(cat ./data/temps/region_A)
temp_b=$(cat ./data/temps/region_B)
temp_c=$(cat ./data/temps/region_C)

echo "Las temperaturas son $temp_a, $temp_b, y $temp_c"
```

Explicación de comandos y flags:
- `temp_a=$(cat ./data/temps/region_A)`: asigna el contenido del archivo a la variable.
- `echo "Las temperaturas son $temp_a, $temp_b, y $temp_c"`: imprime las variables.

## 5. Arrays

### Array Normal

#### Trabajar con Arrays Indexados

Crear el archivo:
```bash
touch 09_array_capitales.sh
```

```bash
#!/bin/bash

declare -a capital_cities
capital_cities+=("Sydney")
capital_cities+=("Albany")
capital_cities+=("Paris")

echo "Ciudades: ${capital_cities[@]}"

echo "Número de ciudades: ${#capital_cities[@]}"
```

Explicación de comandos y flags:
- `declare -a capital_cities`: declara un array indexado.
- `capital_cities+=("Sydney")`: añade elemento al array.
- `echo "Ciudades: ${capital_cities[@]}"`: imprime todos los elementos del array.
- `echo "Número de ciudades: ${#capital_cities[@]}"`: imprime la longitud del array.

### Array Asociativo

#### Trabajar con Arrays Asociativos

```bash
#!/bin/bash

declare -A model_metrics
model_metrics[model_accuracy]=98
model_metrics[model_name]="knn"
model_metrics[model_f1]=0.82

echo "Valores: ${model_metrics[@]}"

echo "Claves: ${!model_metrics[@]}"
```

Explicación de comandos y flags:
- `declare -A model_metrics`: declara un array asociativo.
- `model_metrics[model_accuracy]=98`: asigna valor a clave.
- `echo "Valores: ${model_metrics[@]}"`: imprime todos los valores.
- `echo "Claves: ${!model_metrics[@]}"`: imprime todas las claves.

### Cálculo con Arrays

#### Calcular Promedio con Arrays

Utiliza archivos en: `temps/`

Crear el archivo:
```bash
touch 11_calcular_promedio_arrays.sh
```

```bash
#!/bin/bash

temp_b="$(cat ./data/temps/region_B)"
temp_c="$(cat ./data/temps/region_C)"
region_temps=($temp_b $temp_c)
average_temp=$(echo "scale=2; (${region_temps[0]} + ${region_temps[1]}) / 2" | bc)
region_temps+=($average_temp)
echo "Temperaturas y promedio: ${region_temps[@]}"
```

Explicación de comandos y flags:
- `cat ./data/temps/region_B`: lee el archivo de temperatura.
- `region_temps=($temp_b $temp_c)`: crea array con las temperaturas.
- `echo "scale=2; ... | bc"`: calcula promedio con bc.
- `region_temps+=($average_temp)`: añade promedio al array.
- `echo "Temperaturas y promedio: ${region_temps[@]}"`: imprime el array.

## 6. Estructuras de Control: If

Archivos en `./data/model_results/`.

#### Mover Modelos Basado en Precisión

Utiliza archivos en: `model_results/`

Crear el archivo:
```bash
touch 12_mover_modelos.sh
```

```bash
#!/bin/bash

# Extrae precisión y mueve a carpetas
accuracy=$(grep "Accuracy" "$1" | sed 's/.* //')
if [ $accuracy -ge 90 ]; then
    mv "$1" ./data/good_models/
elif [ $accuracy -lt 90 ]; then
    mv "$1" ./data/bad_models/
fi
```

Ejecuta:
```bash
./12_mover_modelos.sh ./data/model_results/model1.txt
```

Explicación de comandos y flags:
- `grep "Accuracy" "$1"`: busca "Accuracy" en el archivo pasado como argumento.
- `sed 's/.* //'`: extrae el último campo (el valor de accuracy).
- `[ $accuracy -ge 90 ]`: condición si accuracy >= 90.
- `mv "$1" ./data/good_models/`: mueve el archivo a good_models si condición.
- `elif [ $accuracy -lt 90 ]`: condición alternativa si < 90.
- `mv "$1" ./data/bad_models/`: mueve a bad_models.

#### Mover Logs Basado en Contenido

Crear el archivo:
```bash
touch 13_mover_logs.sh
```

```bash
#!/bin/bash

sfile=$1

if grep -q 'SRVM_' "$sfile" && grep -q 'vpt' "$sfile"; then
    mv "$sfile" ./data/good_logs/
fi
```

Explicación de comandos y flags:
- `grep -q 'SRVM_' "$sfile"`: busca 'SRVM_' en el archivo silenciosamente (-q).
- `&&`: operador lógico AND.
- `grep -q 'vpt' "$sfile"`: busca 'vpt' silenciosamente.
- `mv "$sfile" ./data/good_logs/`: mueve el archivo si ambas condiciones son true.

## 7. Bucles: For

#### Listar Archivos en un Directorio

Utiliza directorio: `inherited_folder/`

```bash
#!/bin/bash

for file in ./data/inherited_folder/*.R
do
    echo "$file"
done
```

Explicación de comandos y flags:
- `for file in ./data/inherited_folder/*.R`: itera sobre archivos .R.
- `echo "$file"`: imprime el nombre del archivo.

#### Mover Archivos Python con Condición

Utiliza directorio: `robs_files/`

Crear el archivo:
```bash
touch 16_mover_archivos_python.sh
```

```bash
#!/bin/bash

for file in ./data/robs_files/*.py
do
    if grep -q 'RandomForestClassifier' "$file"; then
        mv "$file" ./data/to_keep/
    fi
done
```

Explicación de comandos y flags:
- `for file in ./data/robs_files/*.py`: itera sobre archivos .py.
- `grep -q 'RandomForestClassifier' "$file"`: busca la cadena silenciosamente.
- `mv "$file" ./data/to_keep/`: mueve el archivo si encontrado.

## 8. Case Statements

#### Evaluar Días de la Semana con case

```bash
#!/bin/bash

case $1 in
    Monday|Tuesday|Wednesday|Thursday|Friday)
        echo "Es un día de semana!";;
    Saturday|Sunday)
        echo "Es fin de semana!";;
    *)
        echo "No es un día!";;
esac
```

Ejecuta:
```bash
./16_evaluar_dias.sh Monday
```

Explicación de comandos y flags:
- `case $1 in`: evalúa el primer argumento.
- `Monday|Tuesday|... )`: patrón para días de semana.
- `echo "Es un día de semana!";;`: acción para el patrón.
- `Saturday|Sunday)`: patrón para fin de semana.
- `*)`: patrón por defecto.

#### Clasificar Modelos con case

Utiliza directorio: `model_out/`

Crear el archivo:
```bash
touch 17_clasificar_modelos.sh
```

```bash
#!/bin/bash

for file in ./data/model_out/*
do
    case $(cat "$file") in
        *"Random Forest"*|*GBM*|*XGBoost*)
            mv "$file" ./data/tree_models/ ;;
        *KNN*|*Logistic*)
            rm "$file" ;;
        *)
            echo "Modelo desconocido en $file" ;;
    esac
done
```

Explicación de comandos y flags:
- `for file in ./data/model_out/*`: itera sobre archivos en model_out.
- `case $(cat "$file") in`: evalúa el contenido del archivo.
- `*"Random Forest"*|*GBM*|*XGBoost*)`: patrón para modelos de árbol.
- `mv "$file" ./data/tree_models/ ;;`: mueve a tree_models.
- `*KNN*|*Logistic*)`: patrón para otros modelos.
- `rm "$file" ;;`: elimina el archivo.
- `*)`: caso por defecto.

## 9. Funciones

### Función simple

#### Función para Subir a la Nube

Utiliza directorio: `output_dir/`

Crear el archivo:
```bash
touch 18_subir_nube.sh
```

```bash
#!/bin/bash

function upload_to_cloud () {
    for file in ./data/output_dir/*results.txt
    do
        echo "Subiendo $file a la nube"
    done
}

upload_to_cloud
```

### Función con parsing

#### Obtener el Día Actual

Crear el archivo:
```bash
touch 19_obtener_dia.sh
```

```bash
#!/bin/bash

what_day_is_it() {
    date=$(date | cut -d " " -f1)
    echo "$date"
}

what_day_is_it
```

### Función con retorno

#### Calcular Porcentaje

Crear el archivo:
```bash
touch 20_calcular_porcentaje.sh
```

```bash
#!/bin/bash

function return_percentage () {
    percent=$(echo "scale=2; 100 * $1 / $2" | bc)
    echo "$percent"
}

return_test=$(return_percentage 456 632)
echo "456 de 632 es $return_test%"
```

#### Contar Victorias de un Equipo

Utiliza la base de datos: `basketball_scores.csv`

Crear el archivo:
```bash
touch 21_contar_victorias.sh
```

```bash
#!/bin/bash

function get_number_wins () {
    win_stats=$(cat ./data/basketball_scores.csv | cut -d "," -f2 | tail -n +2 | sort | uniq -c | grep "$1")
}

get_number_wins "Lakers"
echo "Estadísticas: $win_stats"
```

Explicación de comandos y flags:
- `cat ./data/basketball_scores.csv`: lee el archivo.
- `cut -d "," -f2`: selecciona la columna de ganadores.
- `tail -n +2`: omite encabezado.
- `sort`: ordena.
- `uniq -c`: cuenta únicos.
- `grep "$1"`: filtra por el argumento.

#### Sumar Elementos de un Array

Crear el archivo:
```bash
touch 22_sumar_array.sh
```

```bash
#!/bin/bash

function sum_array () {
    local sum=0
    for number in "$@"
    do
        sum=$(echo "$sum + $number" | bc)
    done
    echo "$sum"
}

test_array=(14 12 23.5 16 19.34)
total=$(sum_array "${test_array[@]}")
echo "Suma total: $total"
```

Explicación de comandos y flags:
- `local sum=0`: declara variable local sum.
- `for number in "$@"`: itera sobre argumentos de la función.
- `echo "$sum + $number" | bc`: suma usando bc.
- `"${test_array[@]}"`: pasa todos los elementos del array como argumentos.

## 10. Cron Jobs

Cron es un programador de tareas que ejecuta comandos o scripts en intervalos específicos. Usa una sintaxis de 5 campos para definir cuándo ejecutar.

### Diagrama de Campos de Cron

```
* * * * * comando_a_ejecutar
│ │ │ │ │
│ │ │ │ └─ Día de la semana (0-7, donde 0 y 7 = Domingo, 1 = Lunes, ..., 6 = Sábado)
│ │ │ └─── Mes (1-12, o nombres abreviados como jan, feb)
│ │ └───── Día del mes (1-31)
│ └─────── Hora (0-23)
└───────── Minuto (0-59)
```

Cada campo puede ser:
- `*`: Cualquier valor
- `número`: Valor específico
- `número1-número2`: Rango
- `*/número`: Cada número unidades
- `número1,número2`: Lista de valores

Cron permite programar tareas.

Ejemplos de crontab:

- `30 2 * * * bash script1.sh`: Todos los días a las 2:30 AM.
- `15,30,45 * * * * bash script2.sh`: Cada hora a los 15, 30, 45 minutos.
- `30 23 * * 0 bash script3.sh`: Domingos a las 11:30 PM.

Para editar:
```bash
crontab -e  # Abre editor (nano recomendado)
```

Para listar:
```bash
crontab -l
```

Ejemplo de contenido:
```
30 2 * * * ./extract_data.sh
```

Asegúrate de que los scripts tengan permisos de ejecución y rutas absolutas si es necesario.
