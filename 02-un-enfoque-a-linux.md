# 2. Entrada y salida del sistema

## Índice

- [Objetivos](#objetivos)
- [Antes de empezar](#antes-de-empezar)
- [2.1 Entrada y salida](#21-entrada-y-salida)
- [Terminales TTY y PTY](#terminales-tty-y-pty)
- [Todo es componible](#todo-es-componible)
- [Dispositivos útiles](#dispositivos-útiles)
- [Práctica guiada resuelta](#práctica-guiada-resuelta)
- [Errores frecuentes](#errores-frecuentes)
- [Reto 2](#reto-2--flujo-de-componentes)

## Objetivos

- Reconocer entrada estándar, salida estándar y salida de error.
- Relacionar un proceso con su terminal.
- Comprender por qué los comandos pequeños pueden componerse.

## Antes de empezar

Ejecuta los ejemplos desde la raíz del curso. Este capítulo sólo creará archivos dentro de `laboratorio/salida`:

```bash
cd ~/linux-desde-cero
mkdir -p laboratorio/salida
```

`laboratorio` es una carpeta de práctica dentro del repositorio; no es una parte especial de Linux. Puedes eliminarla y volverla a crear sin afectar `data/` ni los capítulos.

> **Continuidad entre sesiones.** Puedes llegar con evidencia de las Clases 1 o 2 dentro de `laboratorio/`. Este capítulo sólo necesita `laboratorio/salida`, que `mkdir -p` crea sin borrar las demás carpetas. Si `data/dummy_logs.txt` no existe cuando un ejemplo lo solicite, no crees un archivo vacío: confirma que estás en `~/linux-desde-cero` y recupera el repositorio con el instructor.

Los operadores completos se practican en [08-redirecciones-y-tuberias.md](08-redirecciones-y-tuberias.md). Este capítulo establece el modelo mental.

## 2.1 Entrada y salida

Al iniciar un proceso, Linux le proporciona tres descriptores:

| Descriptor | Nombre | Uso |
|---:|---|---|
| 0 | `stdin` | Entrada de datos. |
| 1 | `stdout` | Resultado normal. |
| 2 | `stderr` | Diagnósticos y errores. |

```text
teclado/archivo → stdin → proceso → stdout → terminal/archivo
                              └→ stderr → terminal/archivo
```

### Ejemplo resuelto

Los nombres `modelo-A` y `modelo-B` son texto de ejemplo. `/etc/hosts` es un archivo real del sistema y `/ruta/inexistente` es una ruta deliberadamente falsa para provocar un mensaje en `stderr`.

```bash
printf '%s\n' "modelo-A" "modelo-B"
ls /etc/hosts
ls /ruta/inexistente
```

Salida representativa:

```text
modelo-A
modelo-B
/etc/hosts
ls: cannot access '/ruta/inexistente': No such file or directory
```

Los dos primeros comandos producen salida normal. El tercero escribe el diagnóstico en `stderr`; esto permite separar datos válidos de errores.

## Terminales TTY y PTY

- **TTY:** nombre histórico de una terminal.
- **PTY:** pseudoterminal usado por SSH y emuladores gráficos.

### Diferencia entre terminal y shell

Una **terminal** es el medio de entrada y salida: recibe lo que escribes, muestra texto y proporciona funciones como tamaño de pantalla, colores y combinaciones de teclas. GNOME Terminal, Konsole y Windows Terminal son emuladores de terminal.

Un **shell** es el programa que interpreta lo escrito dentro de esa terminal. Reconoce comandos, variables, pipes, redirecciones y scripts. Bash, Zsh, Fish y PowerShell son shells.

```text
teclado
   ↓
terminal o PTY  ↔  shell Bash  →  comandos como ls, grep o python
   ↑                  ↓
pantalla          interpreta |, >, $VARIABLE, etc.
```

Una terminal puede ejecutar distintos shells. Del mismo modo, un shell puede ejecutarse sin una ventana gráfica: por ejemplo, dentro de un script automatizado. En una conexión SSH normalmente ocurre esto:

1. SSH crea una pseudoterminal remota o PTY.
2. Dentro de esa PTY inicia el shell del usuario, por ejemplo Bash.
3. Bash interpreta los comandos y la PTY devuelve la salida a tu terminal local.

### Cómo identificar cada uno

```bash
tty
ps -p "$$" -o comm=
echo "$SHELL"
ps -o pid,ppid,tty,stat,comm -p "$$"
```

Salida representativa:

```text
/dev/pts/0
bash
/bin/bash
  PID  PPID TT       STAT COMMAND
 2481  2479 pts/0    Ss   bash
```

- `tty` muestra la terminal asociada: aquí es `/dev/pts/0`.
- `ps -p "$$" -o comm=` muestra el shell que está ejecutándose ahora: `bash`.
- `$SHELL` muestra el shell configurado como predeterminado para el usuario. Puede ser distinto del shell activo si abriste otro manualmente.

Si `tty` responde `not a tty`, el comando se ejecutó sin terminal interactiva —por ejemplo, desde automatización o algunos entornos de ejecución—. El shell puede seguir existiendo aunque no tenga una TTY asociada.

- `PID`: identificador del proceso.
- `PPID`: proceso padre.
- `TT`: terminal asociada.
- `STAT`: estado del proceso.
- `COMMAND`: programa ejecutado.

## Todo es componible

Muchas herramientas aceptan texto por entrada y producen texto por salida. Esto permite reutilizarlas:

```bash
printf '%s\n' api worker api scheduler | sort | uniq -c
```

Salida esperada:

```text
      2 api
      1 scheduler
      1 worker
```

- `sort` agrupa líneas iguales.
- `uniq -c` cuenta elementos consecutivos; por eso se ordena primero.
- Cada comando resuelve una parte y no necesita conocer al siguiente.

## Dispositivos útiles

```bash
printf 'mensaje visible\n' > /dev/tty
printf 'mensaje descartado\n' > /dev/null
```

- `/dev/tty`: terminal del proceso.
- `/dev/null`: descarta lo que recibe.
- Los dispositivos se exponen mediante archivos especiales, pero no son archivos regulares.

## Práctica guiada resuelta

Crearemos `componentes.txt` con cuatro líneas y luego contaremos cuántas veces aparece cada componente. No necesitas crear el archivo manualmente: el primer `printf` lo hace.

```bash
mkdir -p laboratorio/salida

printf '%s\n' inference training inference serving > laboratorio/salida/componentes.txt
sort laboratorio/salida/componentes.txt | uniq -c

tty
ps -o pid,ppid,tty,stat,comm -p "$$"
```

Resultado: se crea una entrada reproducible, se cuenta cada componente y se identifica el shell que ejecutó el pipeline.

Comprueba los archivos:

```bash
wc -l laboratorio/salida/componentes.txt
cat laboratorio/salida/componentes.txt
```

La primera salida debe indicar `4`, porque escribimos cuatro componentes.

## Errores frecuentes

- Creer que todo texto visible pertenece a `stdout`.
- Usar `uniq -c` sin ordenar cuando se quieren totales globales.
- Confundir una terminal con el shell: la terminal transporta y muestra texto; el shell interpreta comandos dentro de ella.

## Reto 2 — Flujo de componentes

[Ver respuesta](instructor/soluciones.md#respuesta-reto-2)

Crea `laboratorio/reto2/servicios.txt` con al menos ocho nombres de servicios repetidos. Genera `laboratorio/reto2/resumen.txt` con el conteo de cada servicio, ordenado por nombre. Debes conservar ambos archivos.

### Criterios de comprobación

- No se cuenta manualmente.
- Entrada y resumen están en archivos distintos.
- La suma de los conteos coincide con el número de líneas de entrada.

## Checklist

- [ ] Identifico los descriptores 0, 1 y 2.
- [ ] Puedo explicar TTY frente a shell.
- [ ] Comprendo por qué `sort | uniq -c` funciona.
