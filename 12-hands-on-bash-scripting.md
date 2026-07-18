# 12. Hands-on Bash Scripting

Taller ampliado de Bash con ejercicios resueltos. Conserva temas que pueden exceder las cuatro sesiones para que el instructor seleccione según el grupo.

## Preparación

Desde la raíz del repositorio:

> **Continuidad entre sesiones.** Este taller usa un laboratorio desechable. Cada ejecución de `preparar-lab.sh` elimina `laboratorio/`, incluidos respaldos, reportes y retos de sesiones anteriores. Antes de ejecutarlo, guarda la evidencia que quieras conservar fuera de `laboratorio/` o consulta con el instructor si la clase continúa un ejercicio previo.

```bash
sudo apt update
sudo apt install -y bc
bash ejercicios-bash-scripting/preparar-lab.sh
cd laboratorio
```

El script copia fixtures inmutables de `data/` a `laboratorio/data/`. Todos los ejercicios modifican la copia. Para reiniciar:

```bash
cd ..
bash ejercicios-bash-scripting/preparar-lab.sh
cd laboratorio
```

Los scripts se invocan como `../ejercicios-bash-scripting/<script>` desde `laboratorio/`.

## Cómo leer los argumentos de los scripts

Un argumento es un valor escrito después del nombre del script. Por ejemplo:

```bash
../ejercicios-bash-scripting/01_contar_ganadores.sh data/basketball_scores.csv
```

En esa ejecución:

- `$0` es la ruta del script;
- `$1` es `data/basketball_scores.csv`;
- `$#` vale `1` porque se proporcionó un argumento.

Esta tabla muestra todos los valores que espera el taller:

| Script | Sintaxis general | Ejemplo concreto |
|---|---|---|
| `01_contar_ganadores.sh` | `<csv>` | `data/basketball_scores.csv` |
| `02_contar_variante.sh` | `<csv>` | `data/basketball_scores.csv` |
| `03_editar_equipos.sh` | `<entrada.csv> <salida.csv>` | `data/basketball_scores.csv salida/editado.csv` |
| `04_separar_numeros.sh` | `[directorio_salida]` | `salida` |
| `05_argumentos.sh` | `<argumento>...` | `"hola mundo" Linux` |
| `06_grep_parametrizado.sh` | `<patrón> <directorio_csv> <salida.csv>` | `Engineer data/hire_data salida/engineer.csv` |
| `07_convertir_temperatura.sh` | `<fahrenheit>` | `100` |
| `08_leer_temperaturas.sh` | `<directorio_temperaturas>` | `data/temps` |
| `09_array_capitales.sh` | sin argumentos | — |
| `11_calcular_promedio_arrays.sh` | `<directorio_temperaturas>` | `data/temps` |
| `12_mover_modelos.sh` | `<resultado> <buenos> <malos>` | `data/model_results/model1.txt data/good_models data/bad_models` |
| `13_mover_logs.sh` | `<log> <destino>` | `data/logs/servicio.log data/good_logs` |
| `16_mover_archivos_python.sh` | `<origen> <destino>` | `data/robs_files data/to_keep` |
| `16_evaluar_dias.sh` | `<día_en_inglés>` | `Monday` |
| `17_clasificar_modelos.sh` | `<origen> <árboles> <descartados>` | `data/model_out data/tree_models data/descartados` |
| `18_subir_nube.sh` | `<directorio_resultados>` | `data/output_dir` |
| `19_obtener_dia.sh` | sin argumentos | — |
| `20_calcular_porcentaje.sh` | `<parte> <total>` | `456 632` |
| `21_contar_victorias.sh` | `<equipo> <csv>` | `Lakers data/basketball_scores.csv` |
| `22_sumar_array.sh` | `<número>...` | `14 12 23.5 16 19.34` |

Los nombres entre `< >` describen valores que debes sustituir. Los valores entre `[ ]` son opcionales. La columna “Ejemplo concreto” contiene los valores usados en las prácticas y puede copiarse.

## Índice

- [Preparación](#preparación)
- [Cómo leer los argumentos de los scripts](#cómo-leer-los-argumentos-de-los-scripts)
- [1. Pipes y comandos básicos](#1-pipes-y-comandos-básicos)
- [2. Edición de archivos con `sed`](#2-edición-de-archivos-con-sed)
- [3. Variables, argumentos y descriptores](#3-variables-argumentos-y-descriptores)
- [4. Cálculos con `bc`](#4-cálculos-con-bc)
- [5. Arrays](#5-arrays)
- [6. Estructuras de control: `if`](#6-estructuras-de-control-if)
- [7. Bucles: `for`](#7-bucles-for)
- [8. Selección con `case`](#8-selección-con-case)
- [9. Funciones](#9-funciones)
- [10. Cron jobs](#10-cron-jobs)
- [Checklist del taller](#checklist-del-taller)

## 1. Pipes y comandos básicos

### 1.1 Contar equipos ganadores

```bash
../ejercicios-bash-scripting/01_contar_ganadores.sh data/basketball_scores.csv
```

Salida esperada:

```text
      1 Bucks
      2 Celtics
      2 Lakers
      1 Warriors
```

Implementación:

```bash
archivo=$1
tail -n +2 "$archivo" | cut -d',' -f2 | sort | uniq -c | sort -k2
```

`archivo=$1` guarda el primer argumento en una variable con un nombre comprensible. En el comando resuelto, `$archivo` representa `data/basketball_scores.csv`.

- `tail -n +2`: omite encabezado.
- `cut -d',' -f2`: usa coma y toma campo 2.
- `sort`: agrupa valores iguales.
- `uniq -c`: cuenta grupos consecutivos.
- `sort -k2`: ordena por nombre del equipo.

No se necesita `cat archivo |`: `tail` puede abrir el archivo directamente.

### 1.2 Contar Lakers y Celtics

```bash
../ejercicios-bash-scripting/02_contar_variante.sh data/basketball_scores.csv
```

Salida esperada:

```text
4
```

El script usa:

```bash
archivo=$1
grep -Ec 'Lakers|Celtics' "$archivo"
```

Otra vez, `$archivo` no es un nombre mágico: el script lo define a partir de `$1`.

- `-E`: alternancia extendida con `|`.
- `-c`: imprime el número de líneas coincidentes.
- El nombre histórico `egrep` equivale a `grep -E`, pero no se usa en scripts nuevos.

## 2. Edición de archivos con `sed`

### 2.1 Normalizar nombres

```bash
../ejercicios-bash-scripting/03_editar_equipos.sh \
  data/basketball_scores.csv salida/basketball_scores_edited.csv
head -n 5 salida/basketball_scores_edited.csv
```

Salida representativa:

```text
Year,Winner,Winner Points
2020,LA Lakers,120
2021,Bucks,125
2022,Warriors,118
2023,Boston Celtics,122
```

Transformación:

```bash
entrada=$1
salida=$2
sed -e 's/Lakers/LA Lakers/g' \
    -e 's/Celtics/Boston Celtics/g' "$entrada" > "$salida"
```

Con el ejemplo resuelto, `$entrada` vale `data/basketball_scores.csv` y `$salida` vale `salida/basketball_scores_edited.csv`.

- `s/origen/destino/g`: sustituye todas las apariciones por línea.
- Varios `-e` aplican varias expresiones.
- Se escribe en otro archivo; el fixture original permanece intacto.

## 3. Variables, argumentos y descriptores

### 3.1 Separar pares e impares

```bash
../ejercicios-bash-scripting/04_separar_numeros.sh salida
wc -l salida/{todos,pares,impares}.txt
cat salida/errores.log
```

Salida esperada:

```text
100 salida/todos.txt
 50 salida/pares.txt
 50 salida/impares.txt
```

El script genera números con `printf`, filtra el último dígito con `grep -E` y envía diagnósticos al descriptor 2.

`salida` es el primer argumento y representa un **directorio**, no un archivo. El script crea dentro `todos.txt`, `pares.txt`, `impares.txt`, `errores.log` y `proceso.log`.

- `stdout` es descriptor 1.
- `stderr` es descriptor 2.
- `2>` guarda errores sin mezclarlos con datos.
- `{ ...; }` permite redirigir un bloque completo.

### 3.2 Argumentos

```bash
../ejercicios-bash-scripting/05_argumentos.sh "hola mundo" Linux
```

Salida esperada:

```text
Primer argumento: hola mundo
Segundo argumento: Linux
Cantidad: 2
Todos: [hola mundo] [Linux]
```

- `$1`, `$2`: argumentos posicionales.
- `$#`: cantidad.
- `"$@"`: conserva cada argumento, incluso con espacios.

### 3.3 Búsqueda parametrizada

```bash
../ejercicios-bash-scripting/06_grep_parametrizado.sh \
  Engineer data/hire_data salida/engineer.csv
head salida/engineer.csv
```

El script valida directorio, patrón y destino; usa `grep -h` para no anteponer nombres de archivo.

## 4. Cálculos con `bc`

### 4.1 Conversión de temperatura

```bash
../ejercicios-bash-scripting/07_convertir_temperatura.sh 100
```

Salida esperada:

```text
100 F = 37.78 C
```

```bash
temp_f=$1
temp_c=$(bc -l <<< "scale=4; ($temp_f - 32) * 5 / 9")
```

Al ejecutar el ejemplo con `100`, `$1` y por tanto `$temp_f` valen `100`.

- `bc -l`: habilita biblioteca matemática y decimales; se calculan cuatro decimales y `printf` redondea a dos.
- `<<<`: here-string hacia `stdin`.
- El script valida que la entrada sea numérica.

### 4.2 Leer temperaturas de archivos

```bash
../ejercicios-bash-scripting/08_leer_temperaturas.sh data/temps
```

Salida esperada:

```text
region_A=72 F
region_B=68 F
region_C=75 F
```

`$(< archivo)` lee un archivo pequeño sin invocar `cat`.

## 5. Arrays

### 5.1 Arrays indexados y asociativos

```bash
../ejercicios-bash-scripting/09_array_capitales.sh
```

Salida representativa:

```text
Ciudades (3): Sydney Albany Paris
Modelo: knn
Accuracy: 98
F1: 0.82
```

- `declare -a`: array indexado.
- `declare -A`: array asociativo.
- `"${array[@]}"`: todos los elementos preservando límites.
- `${#array[@]}`: cantidad.
- `${mapa[clave]}`: valor por clave.

### 5.2 Promedio en un array

```bash
../ejercicios-bash-scripting/11_calcular_promedio_arrays.sh data/temps
```

Salida esperada:

```text
Temperaturas: 68 75
Promedio: 71.50
```

El promedio calculado por `bc` se agrega como tercer elemento sin expansión no citada.

## 6. Estructuras de control: `if`

### 6.1 Clasificar un resultado de modelo

```bash
../ejercicios-bash-scripting/12_mover_modelos.sh \
  data/model_results/model1.txt data/good_models data/bad_models
find data/good_models data/bad_models -maxdepth 1 -type f
```

El script extrae `Accuracy`, valida que sea entero y mueve la **copia del laboratorio**:

```bash
archivo=$1
buenos=$2
malos=$3
accuracy=$(awk '/Accuracy/ {print $NF; exit}' "$archivo")

if (( accuracy >= 90 )); then
  mv -- "$archivo" "$buenos/"
else
  mv -- "$archivo" "$malos/"
fi
```

En el ejemplo, `$archivo` representa `data/model_results/model1.txt`, `$buenos` representa `data/good_models` y `$malos` representa `data/bad_models`. Esas variables se asignan desde `$1`, `$2` y `$3`. `awk` extrae el último campo de la línea `Accuracy: 94`, por lo que `accuracy` vale `94`.

- `(( ... ))`: contexto aritmético de Bash.
- `--`: termina opciones; protege nombres que comienzan con `-`.

### 6.2 Clasificar un log

```bash
../ejercicios-bash-scripting/13_mover_logs.sh \
  data/logs/servicio.log data/good_logs
```

Se mueve únicamente cuando aparecen ambos patrones `SRVM_` y `vpt`. `grep -q` comprueba sin imprimir.

## 7. Bucles: `for`

### 7.1 Listar archivos R

```bash
for archivo in data/inherited_folder/*.R; do
  printf '%s\n' "$archivo"
done
```

Las comillas protegen cada ruta. El glob se expande antes de ejecutar el bucle.

### 7.2 Seleccionar modelos Python

```bash
../ejercicios-bash-scripting/16_mover_archivos_python.sh \
  data/robs_files data/to_keep
find data/to_keep -maxdepth 1 -type f
```

El script mueve copias que contienen `RandomForestClassifier` y deja el resto en origen.

`data/robs_files` es el directorio origen y `data/to_keep` el destino. Ambos están dentro de la copia `laboratorio/data`, por lo que repetir `preparar-lab.sh` restaura el estado original.

## 8. Selección con `case`

### 8.1 Día de la semana

```bash
../ejercicios-bash-scripting/16_evaluar_dias.sh Monday
../ejercicios-bash-scripting/16_evaluar_dias.sh Sunday
```

Salida:

```text
Es un día de semana
Es fin de semana
```

`case` compara una palabra contra patrones. `|` separa alternativas y `*` es el caso por defecto.

### 8.2 Clasificar tipos de modelo

```bash
../ejercicios-bash-scripting/17_clasificar_modelos.sh \
  data/model_out data/tree_models data/descartados
```

- Random Forest, GBM y XGBoost se mueven a `tree_models`.
- KNN y Logistic se mueven a `descartados`; no se eliminan.
- Los desconocidos permanecen y se informan.

## 9. Funciones

### 9.1 Simular una carga

```bash
../ejercicios-bash-scripting/18_subir_nube.sh data/output_dir
```

El ejercicio simula la acción con `printf`; no usa credenciales ni modifica servicios externos.

```bash
upload_to_cloud() {
  local directorio=$1
  local archivo
  for archivo in "$directorio"/*results.txt; do
    [[ -e "$archivo" ]] || continue
    printf 'Simulación: subir %s\n' "$archivo"
  done
}
```

La función recibe `data/output_dir` como `$1`. Dentro de la función ese valor se guarda en una variable local llamada `directorio`.

- `local`: alcance dentro de la función.
- `[[ -e ... ]] || continue`: maneja un glob sin coincidencias.

### 9.2 Obtener el día

```bash
../ejercicios-bash-scripting/19_obtener_dia.sh
```

El script usa `date +%A`; no intenta separar una salida dependiente de espacios.

### 9.3 Calcular porcentaje

```bash
../ejercicios-bash-scripting/20_calcular_porcentaje.sh 456 632
```

Salida esperada:

```text
456 de 632 = 72.15%
```

La función valida divisor distinto de cero y devuelve el resultado mediante `stdout`.

### 9.4 Contar victorias

```bash
../ejercicios-bash-scripting/21_contar_victorias.sh \
  Lakers data/basketball_scores.csv
```

Salida esperada:

```text
Lakers: 2
```

### 9.5 Sumar un array

```bash
../ejercicios-bash-scripting/22_sumar_array.sh 14 12 23.5 16 19.34
```

Salida esperada:

```text
Suma total: 84.84
```

`"$@"` entrega cada número a la función y `bc` permite decimales.

## 10. Cron jobs

Cron ejecuta comandos según cinco campos:

```text
minuto hora día-del-mes mes día-de-semana comando
  30    2       *        *         *         /ruta/absoluta/script.sh
```

Ejemplos:

```cron
30 2 * * * /home/ubuntu/bin/respaldo.sh >> /home/ubuntu/logs/respaldo.log 2>&1
15,30,45 * * * * /home/ubuntu/bin/metricas.sh
30 23 * * 0 /home/ubuntu/bin/reporte-semanal.sh
```

- `*`: cualquier valor.
- `a-b`: rango.
- `*/n`: cada n unidades.
- `a,b`: lista.

### Práctica segura resuelta

No se espera a que cron ejecute durante clase. Primero prueba el comando directamente:

```bash
mkdir -p "$HOME/bin" "$HOME/logs"
cp ../ejercicios-bash-scripting/19_obtener_dia.sh "$HOME/bin/"
chmod +x "$HOME/bin/19_obtener_dia.sh"
"$HOME/bin/19_obtener_dia.sh" >> "$HOME/logs/dia.log" 2>&1
tail "$HOME/logs/dia.log"
crontab -l 2>/dev/null || true
```

Una entrada posible para cada lunes a las 09:00:

```cron
0 9 * * 1 /home/ubuntu/bin/19_obtener_dia.sh >> /home/ubuntu/logs/dia.log 2>&1
```

Usa rutas absolutas: cron tiene un entorno y `PATH` más limitados que una terminal interactiva.

## Checklist del taller

- [ ] Puedo explicar cada etapa de un pipeline.
- [ ] Mis scripts validan argumentos y citan rutas.
- [ ] Los ejercicios modifican `laboratorio/`, no los fixtures.
- [ ] Distingo `if`, `for`, `case` y función.
- [ ] Pruebo un comando antes de programarlo con cron.
