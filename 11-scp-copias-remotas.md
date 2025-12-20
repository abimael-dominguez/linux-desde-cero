# 11. SCP Copias Remotas
También ver [13-hands-on-ssh-scp.md](13-hands-on-ssh-scp.md)

## Índice

- [11. SCP Copias Remotas](#11-scp-copias-remotas)
  - [11.1 Compilado de programas en LINUX](#111-compilado-de-programas-en-linux)
  - [11.2 Compilación y Linkado](#112-compilación-y-linkado)
  - [11.3 Comando MAKE](#113-comando-make)
  - [11.4 Búsqueda avanzada en ficheros. Expresiones Regulares](#114-búsqueda-avanzada-en-ficheros-expresiones-regulares)
  - [11.5 Caracteres especiales](#115-caracteres-especiales)
  - [11.6 Expresiones regulares de un solo carácter](#116-expresiones-regulares-de-un-solo-carácter)
  - [11.7 Expresiones regulares generales](#117-expresiones-regulares-generales)
  - [11.8 Comandos utiles para trabajar en Red](#118-comandos-utiles-para-trabajar-en-red)
  - [11.9 Protocolos de Internet (IP)](#119-protocolos-de-internet-ip)
  - [11.10 Denominación simbólica de Sistemas de Internet](#1110-denominación-simbólica-de-sistemas-de-internet)
  - [11.11 Comandos TELNET y FTP](#1111-comandos-telnet-y-ftp)

## 11.1 Compilado de programas en LINUX (caso Pac-Man)

En esta sección veremos **qué significa “compilar” en Linux** usando como ejemplo el videojuego Pac‑Man en C. El objetivo es que el alumno entienda claramente:

- Qué archivo es el **código fuente** (`.c`).
- Qué archivo es el **binario intermedio** (`.o`).
- Qué archivo es el **ejecutable final** (nuestro juego en terminal).

### 11.1.1 Archivos del proyecto

En este punto del curso ya contamos con esta estructura básica:

```text
src/11-scp-copias-remotas/pacman-game/
├─ pacman.c            # Código fuente C
├─ Makefile            # Reglas de compilación/linkado
└─ script.sh           # Script auxiliar (equivalente al Makefile)
```

### 11.1.2 Primer contacto con `gcc`: solo compilar

Desde la raíz del repositorio:

```bash
cd src/11-scp-copias-remotas/pacman-game
ls
```

Deberías ver `pacman.c`, `Makefile` y `script.sh`.

Vamos a hacer **solo la fase de compilación**, sin crear todavía el ejecutable final:

```bash
gcc -c pacman.c -o pacman.o
ls
```

Ahora aparece un nuevo archivo:

- `pacman.o` → **archivo objeto** (código máquina, pero todavía no es el juego ejecutable).

Puntos clave para el alumno:

- `gcc -c` **compila** pero **no enlaza**.
- El código C (`pacman.c`) se convirtió en binario (`pacman.o`), pero aún no podemos jugar.

En la siguiente sección veremos cómo convertir ese `.o` en el ejecutable completo enlazando con `ncurses`.

## 11.2 Compilación y Linkado

En la sección anterior generamos **solo** el archivo objeto `pacman.o`. Ahora veremos cómo pasar de:

```text
pacman.o  -->  pacman_game
```

es decir, de **objeto** a **ejecutable**, y de paso **enlazar la librería `ncurses`** que usa el juego para dibujar el laberinto.

### 11.2.1 Compilación + linkado “a mano” con `gcc`

Flujo manual paso a paso para crear y ejecutar el juego:

```bash
cd src/11-scp-copias-remotas/pacman-game

# 1) Compilar: .c -> .o
gcc -c pacman.c -o pacman.o

# 2) Enlazar: .o + librerías -> ejecutable
gcc pacman.o -o pacman_game -lncurses

# 3) Ejecutar el juego
./pacman_game
```

Conceptos importantes:

- `-o pacman_game` → nombre del ejecutable final.
- `-lncurses` → enlaza la librería `libncurses` (necesaria para el juego en modo texto).

Podemos ver el flujo completo así:

```bash
gcc -c pacman.c      # 1) Compilación: .c -> .o
gcc pacman.o -o pacman_game -lncurses   # 2) Linkado: .o -> ejecutable
```

### 11.2.2 Tabla resumen: compilación vs linkado

| Etapa            | Flag principal       | Entrada         | Salida          | ¿Qué obtenemos en disco?                              |
| :--------------- | :------------------ | :-------------- | :-------------- | :---------------------------------------------------- |
| **Compilación**  | `-c`                | `*.c`           | `*.o`           | Código máquina parcial, aún no ejecutable             |
| **Linkado**      | `-o <nombre>`       | `*.o` (+ libs)  | ejecutable      | Programa listo para ejecutarse (`./pacman_game`)      |
| **Librerías**    | `-l<nombre>`        | referencias a lib | binario enlazado | El ejecutable ya incluye código de librerías externas |

Notas visuales (modo ncurses “8-bit”):
- Laberinto con bloques `ACS_CKBOARD` y paleta de colores.
- Pac-Man animado con boca que abre/cierra según la dirección.
- Fantasmas cambian de color al estar asustados.
- UI en color con score, vidas y modo.

En proyectos reales raramente escribiremos siempre estos comandos a mano. Para eso existe **`make`**, que veremos a continuación.

## 11.3 Comando MAKE

En lugar de recordar todos los comandos de compilación y linkado, usamos un archivo `Makefile` para que **`make` haga el trabajo por nosotros**. En este proyecto, el `Makefile` está en `src/11-scp-copias-remotas/11-1/` y contiene, de forma simplificada, lo siguiente:

```makefile
# Compilador, banderas y librerías
COMPILADOR = gcc
BANDERAS_COMPILACION = -Wall -Wextra -Wpedantic -std=c11 -O2
BANDERAS_ENLACE = -lncurses

CODIGO_FUENTE = pacman.c
ARCHIVO_OBJETO = pacman.o
EJECUTABLE = pacman_game

install:
	sudo apt-get update
	sudo apt-get install -y libncurses-dev

# Forma 1: all (compilar + enlazar en una sola línea)
all:
	$(COMPILADOR) $(BANDERAS_COMPILACION) $(CODIGO_FUENTE) -o $(EJECUTABLE) $(BANDERAS_ENLACE)

# Forma 2: pasos separados
compilar: $(ARCHIVO_OBJETO)

$(ARCHIVO_OBJETO): $(CODIGO_FUENTE)
	$(COMPILADOR) $(BANDERAS_COMPILACION) -c $(CODIGO_FUENTE) -o $(ARCHIVO_OBJETO)

enlazar: $(ARCHIVO_OBJETO)
	$(COMPILADOR) $(ARCHIVO_OBJETO) -o $(EJECUTABLE) $(BANDERAS_ENLACE)

run: enlazar
	./$(EJECUTABLE)

clean:
	rm -f $(ARCHIVO_OBJETO) $(EJECUTABLE)

.PHONY: all run clean compilar enlazar install
```

### 11.3.0 Recordatorio de sintaxis básica de `make`

```
objetivo: dependencias
	comandos...
```

- `objetivo` es lo que se quiere generar (ej: `pacman.o`, `pacman_game`, `all`).
- `dependencias` son los archivos/targets que deben existir o estar al día antes de ejecutar los comandos.
- Cada comando va en una línea separada e indentada con **TAB** (no espacios).

### 11.3.1 Flujo completo con `make`

Desde la raíz del proyecto, el flujo recomendado para el alumno es:

```bash
cd src/11-scp-copias-remotas/pacman-game

# 1) Compilar (compilación + linkado usando el Makefile)
make

# 2) Ejecutar el videojuego
make run

# 3) Limpiar archivos generados (.o y ejecutable)
make clean
```

En este curso usamos primero los comandos manuales para entender el proceso, y luego `make` para mostrar cómo se automatiza ese mismo flujo de forma limpia y mantenible.

### 11.3.2 Explicación de las banderas de compilación

Las banderas en `BANDERAS_COMPILACION` aseguran código robusto, portable y eficiente:

- **`-Wall`**: Advierte sobre errores y malas prácticas frecuentes.
- **`-Wextra`**: Suma advertencias útiles para mayor seguridad.
- **`-Wpedantic`**: Exige cumplir el estándar C al 100%, facilitando portabilidad.
- **`-std=c11`**: Usa el estándar moderno, evitando funciones obsoletas.
- **`-O2`**: Optimización de nivel 2: aumenta la velocidad de ejecución y reduce el tamaño del ejecutable.

Estas opciones previenen errores difíciles y fomentan buenas prácticas profesionales.

## 11.4 Búsqueda avanzada en ficheros. Expresiones Regulares


En esta sección aprenderás a buscar información en archivos usando expresiones regulares (regex) con herramientas como `grep`, `egrep`, y `awk`. Las expresiones regulares son esenciales para DevOps, ya que permiten filtrar logs, analizar datos y automatizar tareas.

### ¿Qué es una expresión regular?
Una expresión regular es un patrón que describe un conjunto de cadenas. Se usan para buscar, validar o extraer información de texto.

### Cheat Sheet de Expresiones Regulares (Regex)

| Símbolo/Patrón | Significado | Ejemplo | Coincide con | Explicación detallada |
|:--------------:|:-----------:|:--------|:-------------|:----------------------|
| .              | Cualquier carácter excepto salto de línea | a.c | abc, a1c, a-c | 'a.c' coincide con cualquier secuencia de tres caracteres donde el primero es 'a', el segundo puede ser cualquier cosa (b, 1, -, etc.), y el tercero es 'c'. |
| ^              | Inicio de línea | ^Hola | Hola mundo (al inicio) | El símbolo `^` al inicio busca solo al principio de la línea. Ejemplo: `^Hola` solo encuentra "Hola" si está al inicio. |
| $              | Fin de línea | mundo$ | Hola mundo (al final) | El símbolo `$` al final busca solo al final de la línea. Ejemplo: `mundo$` solo encuentra "mundo" si está al final. |
| *              | 0 o más repeticiones | ab*c | ac, abc, abbc | El asterisco `*` significa "cero o más" del carácter anterior. Ejemplo: `ab*c` encuentra "ac", "abc", "abbc". Si pones `*` después de una letra, busca repeticiones de esa letra. |
| +              | 1 o más repeticiones | ab+c | abc, abbc | El signo `+` significa "una o más" repeticiones del carácter anterior. Ejemplo: `ab+c` encuentra "abc", "abbc" pero no "ac". |
| ?              | 0 o 1 repetición | colou?r | color, colour | El signo `?` significa "cero o una vez" del carácter anterior. Ejemplo: `colou?r` encuentra "color" y "colour". |
| []             | Cualquier carácter dentro de los corchetes | gr[ae]y | gray, grey | Los corchetes `[ ]` permiten elegir entre varios caracteres. Ejemplo: `gr[ae]y` encuentra "gray" y "grey". |
| [^]            | Cualquier carácter excepto los listados | [^0-9] | a, b, c | El símbolo `^` dentro de corchetes significa "no". Ejemplo: `[^0-9]` encuentra cualquier cosa que no sea un número. |
| {n}            | Exactamente n repeticiones | a{3} | aaa | Las llaves `{n}` indican exactamente n repeticiones. Ejemplo: `a{3}` encuentra "aaa". |
| {n,}           | Al menos n repeticiones | a{2,} | aa, aaa, aaaa | Las llaves `{n,}` indican al menos n repeticiones. Ejemplo: `a{2,}` encuentra "aa", "aaa", etc. |
| {n,m}          | Entre n y m repeticiones | a{2,4} | aa, aaa, aaaa | Las llaves `{n,m}` indican entre n y m repeticiones. Ejemplo: `a{2,4}` encuentra "aa", "aaa", "aaaa". |
| \\              | Escapa un carácter especial | \\$ | $ | La barra invertida `\\` sirve para buscar caracteres especiales literalmente. Ejemplo: `\\$` busca el símbolo de dólar. |
| \|             | Alternancia (o) | `foo\|bar` | foo, bar | El símbolo \| significa "o". El patrón `foo\|bar` coincide con "foo" o "bar". |
| ()             | Agrupación | (ab)+ | ab, abab | Los paréntesis agrupan partes del patrón. Ejemplo: `(ab)+` encuentra "ab", "abab". |
| \\d             | Dígito (solo egrep, perl, awk) | \\d+ | 123 | `\\d` representa cualquier dígito (0-9). Ejemplo: `\\d+` encuentra "123". No funciona en grep básico, sí en egrep/awk/perl. |
| \\w             | Alfanumérico | \\w+ | abc123 | `\\w` representa letras, números o guion bajo. Ejemplo: `\\w+` encuentra "abc123". |
| \\s             | Espacio en blanco | \\s+ |   (espacios) | `\\s` representa cualquier espacio, tabulación, salto de línea. Ejemplo: `\\s+` encuentra espacios. |

> **Para principiantes:**
> - El símbolo `*` siempre afecta al carácter o grupo que está justo antes. Ejemplo: en `ab*`, el `*` afecta solo a la `b`.
> - Si quieres que el `*` afecte a varias letras, usa paréntesis: `(ab)*`.
> - Si pones `*` al inicio de un patrón, no tiene sentido: siempre va después de algo.
> - Lo mismo aplica para `+`, `?`, `{n}`: siempre van después del carácter o grupo que quieres repetir.

> **Valida tus regex online:** [regex101.com](https://regex101.com/) (elige el flavor "ECMAScript" o "POSIX" para bash/grep)

---

## Ejercicios prácticos y explicados

Usaremos un archivo de ejemplo `data/dummy_logs.txt`:

```text
2025-12-20 10:00:01 INFO User abimael logged in
2025-12-20 10:01:15 ERROR Disk full on /dev/sda1
2025-12-20 10:02:30 WARN CPU temperature high
2025-12-20 10:03:45 INFO User maria logged out
2025-12-20 10:04:50 ERROR Network unreachable
```

### 1. Buscar líneas que contienen "ERROR"

```bash
grep 'ERROR' data/dummy_logs.txt
# Output esperado:
# 2025-12-20 10:01:15 ERROR Disk full on /dev/sda1
# 2025-12-20 10:04:50 ERROR Network unreachable
```

### 2. Buscar líneas que empiezan con fecha (4 dígitos)

```bash
grep -E '^[0-9]{4}-' data/dummy_logs.txt
# Output: Todas las líneas (todas empiezan con fecha)
```

### 3. Buscar líneas con usuario (INFO seguido de User y un nombre)

```bash
grep -E 'INFO User [a-z]+' data/dummy_logs.txt
# Output:
# 2025-12-20 10:00:01 INFO User abimael logged in
# 2025-12-20 10:03:45 INFO User maria logged out
```

### 4. Buscar líneas que terminan en "out"

```bash
grep 'out$' data/dummy_logs.txt
# Output:
# 2025-12-20 10:03:45 INFO User maria logged out
```

### 5. Contar líneas con "WARN" o "ERROR"

```bash
grep -E 'WARN|ERROR' data/dummy_logs.txt | wc -l
# Output: 3
```

### 6. Extraer solo los nombres de usuario

```bash
grep -oE 'User [a-z]+' data/dummy_logs.txt | awk '{print $2}'
# Output:
# abimael
# maria
```

---

## 11.4.1 Ejercicio largo: Filtrar logs y generar reporte

Crea un script `ejercicios-bash-scripting/filtra_logs.sh` que:
1. Reciba como argumento un archivo de logs.
2. Cuente cuántos errores, advertencias e infos hay.
3. Extraiga los usuarios únicos.
4. Genere un resumen en pantalla.

```bash
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
```

Hazlo ejecutable:
```bash
chmod +x ejercicios-bash-scripting/filtra_logs.sh
./ejercicios-bash-scripting/filtra_logs.sh data/dummy_logs.txt
```

---

## 11.5 Caracteres especiales


Los caracteres especiales son aquellos que tienen un significado especial en regex y deben escaparse con una barra invertida (\) si quieres buscarlos literalmente. Ejemplos: $, ., *, +, ?, [, ], (, ), |, ^, \\.

| Carácter | Ejemplo de escape | Coincide con | Explicación |
|:--------:|:----------------:|:-------------|:------------|
| `$`      | `\$`             | `$`          | Busca el símbolo de dólar, no el final de línea. |
| `.`      | `\.`             | `.`          | Busca un punto, no cualquier carácter. |
| `*`      | `\*`             | `*`          | Busca el asterisco, no repeticiones. |
| `+`      | `\+`             | `+`          | Busca el signo más, no repeticiones. |
| `?`      | `\?`             | `?`          | Busca el signo de interrogación, no opcionalidad. |
| `[`      | `\[`             | `[`          | Busca el corchete de apertura. |
| `]`      | `\]`             | `]`          | Busca el corchete de cierre. |
| `(`      | `\(`             | `(`          | Busca el paréntesis de apertura. |
| `)`      | `\)`             | `)`          | Busca el paréntesis de cierre. |
| `^`      | `\^`             | `^`          | Busca el símbolo de inicio, no el inicio de línea. |
| `\|`  | `\\|`                | `\|`             | Busca la barra vertical (pipe) como carácter literal, no como alternancia. Ejemplo: grep '\|' busca el símbolo | en el texto. |
| `\`     | `\\`           | `\`         | Busca la barra invertida. |

**Ejemplo práctico:**
Supón que tienes el archivo `data/specials.txt` con este contenido:
```
Precio: $100
Archivo: data[1].csv
Regex: a.c
Pregunta: ?
Alternativa: foo|bar
Ruta: C:\\Users\\devops
```

Buscar líneas con el símbolo de dólar:
```bash
grep '\$' data/specials.txt
# Output: Precio: $100
```
Buscar líneas con corchetes:
```bash
grep '\[' data/specials.txt
# Output: Archivo: data[1].csv
```
Buscar líneas con barra vertical:
```bash
grep '\|' data/specials.txt
# Output: Alternativa: foo|bar
```
Buscar líneas con barra invertida:
```bash
grep '\\' data/specials.txt
# Output: Ruta: C:\Users\devops
```


## 11.6 Expresiones regulares de un solo carácter


Las expresiones de un solo carácter permiten buscar letras, dígitos o símbolos específicos usando corchetes, punto, etc.

| Patrón   | Significado           | Ejemplo     | Coincide con         | Explicación |
|:--------:|:---------------------:|:------------|:--------------------|:------------|
| .        | Cualquier carácter    | a.c         | abc, a1c, a-c        | El punto equivale a cualquier carácter excepto salto de línea. Ejemplo: `a.c` encuentra "abc", "a1c", "a-c". |
| [abc]    | a, b o c              | [aeiou]     | vocales              | `[aeiou]` busca cualquier vocal individual. |
| [a-z]    | Letras minúsculas     | [a-z]       | a, b, ..., z         | `[a-z]` busca cualquier letra minúscula. |
| [A-Z]    | Letras mayúsculas     | [A-Z]       | A, B, ..., Z         | `[A-Z]` busca cualquier letra mayúscula. |
| [0-9]    | Dígitos               | [0-9]       | 0, 1, ..., 9         | `[0-9]` busca cualquier dígito. |
| [^a-z]   | No minúsculas         | [^a-z]      | 1, A, #, etc.        | `[^a-z]` busca cualquier cosa que NO sea minúscula. El `^` va justo después del `[`. |
| $        | Fin de línea          | error$      | ...error             | Coincide solo si el patrón está al final de la línea. |
| ^        | Inicio de línea       | ^INFO       | INFO...              | Coincide solo si el patrón está al inicio de la línea. |
| ?        | 0 o 1 repetición      | colou?r     | color, colour        | La letra o grupo antes de `?` puede estar o no. |
| \|       | Alternancia (o)       | foo\|bar    | foo, bar             | Coincide con "foo" o "bar". |

> **Para principiantes:**
> - Dentro de `[ ]`, puedes poner letras, números o rangos. Ejemplo: `[A-Za-z0-9]` busca cualquier letra o número.
> - El `^` de negación solo funciona si va inmediatamente después del `[`. Si lo pones en otro lugar, busca el carácter `^`.

**Ejemplo:**
```bash
grep -E '[0-9]{2}:[0-9]{2}:[0-9]{2}' data/dummy_logs.txt
# Busca líneas con hora en formato HH:MM:SS
```

## 11.7 Expresiones regulares generales


Aquí combinamos todo lo aprendido para búsquedas avanzadas y útiles en DevOps.

**Ejemplo 1: Buscar líneas con errores de disco**
```bash
grep -E 'ERROR.*Disk' data/dummy_logs.txt
# Output:
# 2025-12-20 10:01:15 ERROR Disk full on /dev/sda1
```

**Ejemplo 2: Buscar líneas con usuario y acción (login/logout)**
```bash
grep -E 'User [a-z]+ logged (in|out)' data/dummy_logs.txt
# Output:
# 2025-12-20 10:00:01 INFO User abimael logged in
# 2025-12-20 10:03:45 INFO User maria logged out
```

**Ejemplo 3: Buscar líneas que NO contienen "INFO"**
```bash
grep -v 'INFO' data/dummy_logs.txt
# Output:
# 2025-12-20 10:01:15 ERROR Disk full on /dev/sda1
# 2025-12-20 10:02:30 WARN CPU temperature high
# 2025-12-20 10:04:50 ERROR Network unreachable
```

**Ejemplo 4: Buscar líneas que terminan en "out"**
```bash
grep 'out$' data/dummy_logs.txt
# Output:
# 2025-12-20 10:03:45 INFO User maria logged out
```

**Ejemplo 5: Contar líneas con "WARN" o "ERROR"**
```bash
grep -E 'WARN|ERROR' data/dummy_logs.txt | wc -l
# Output: 3
```

**Ejemplo 6: Extraer solo los nombres de usuario**
```bash
grep -oE 'User [a-z]+' data/dummy_logs.txt | awk '{print $2}'
# Output:
# abimael
# maria
```


---

## 11.8 Comandos utiles para trabajar en Red

<!-- Comandos de terminal aquí -->

## 11.9 Protocolos de Internet (IP)

<!-- Comandos de terminal aquí -->

## 11.10 Denominación simbólica de Sistemas de Internet

<!-- Comandos de terminal aquí -->

## 11.11 Comandos TELNET y FTP

<!-- Comandos de terminal aquí -->