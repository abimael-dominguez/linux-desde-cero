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

<!-- Comandos de terminal aquí -->

## 11.5 Caracteres especiales

<!-- Comandos de terminal aquí -->

## 11.6 Expresiones regulares de un solo carácter

<!-- Comandos de terminal aquí -->

## 11.7 Expresiones regulares generales

<!-- Comandos de terminal aquí -->

## 11.8 Comandos utiles para trabajar en Red

<!-- Comandos de terminal aquí -->

## 11.9 Protocolos de Internet (IP)

<!-- Comandos de terminal aquí -->

## 11.10 Denominación simbólica de Sistemas de Internet

<!-- Comandos de terminal aquí -->

## 11.11 Comandos TELNET y FTP

<!-- Comandos de terminal aquí -->