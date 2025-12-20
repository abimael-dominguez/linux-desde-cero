COMPILADOR = gcc
BANDERAS_COMPILACION = -Wall -Wextra -Wpedantic -std=c11 -O2
BANDERAS_ENLACE = -lncurses

CODIGO_FUENTE = pacman.c
ARCHIVO_OBJETO = pacman.o
EJECUTABLE = pacman_game

install:
	sudo apt-get update
	sudo apt install -y build-essential libncurses-dev

# Forma 1: all -> compila y enlaza en una sola línea
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
