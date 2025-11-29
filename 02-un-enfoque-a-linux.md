# 2. Un Enfoque a Linux

Este capítulo profundiza en cómo Linux gestiona **la entrada y salida (I/O) del sistema**: terminales, archivos, dispositivos, procesos y red. La meta es que comprendas el modelo "todo es un archivo" y practiques comandos que inspeccionan, redirigen y monitorizan I/O.

## 2.1 Fundamentos de Entrada/Salida del sistema

### Concepto clave: todo es un archivo
- Dispositivos (`/dev/sda`, `/dev/null`), sockets, pipes, terminales (`/dev/tty`), y hasta procesos (`/proc/<pid>`) se exponen como archivos.
- Esto habilita redirecciones, lectura/escritura uniforme, y scripting poderoso.

### Descriptores estándar
- `stdin` (entrada estándar) = descriptor 0
- `stdout` (salida estándar) = descriptor 1
- `stderr` (salida de error) = descriptor 2

### Operadores de redirección y pipes
- `>`: Redirige `stdout` a un archivo, sobrescribiéndolo (ej: `comando > archivo.txt`).
- `>>`: Redirige `stdout` a un archivo, añadiendo al final (ej: `comando >> archivo.txt`).
- `2>`: Redirige `stderr` a un archivo (ej: `comando 2> errores.txt`).
- `|`: Pipe, envía `stdout` de un comando como `stdin` a otro (ej: `comando1 | comando2`).
- `tee`: Lee de `stdin`, escribe a `stdout` y a un archivo (ej: `comando | tee archivo.txt`). Piensa en `tee` como una T: toma la entrada, la guarda en un archivo y la envía al siguiente comando en el pipe.

```bash
# Enviar salida a archivo y errores a otro
comando > salida.txt 2> errores.txt

# Unir errores a salida
comando > todo.txt 2>&1

# Añadir (append) en lugar de sobrescribir
comando >> historial.log 2>> errores.log
```

**Salida esperada y explicación:**
- `salida.txt`: salida normal (mensajes esperados).
- `errores.txt`: mensajes de error.
- `todo.txt`: mezcla ambos flujos; útil para auditoría.

### Redirección desde y hacia dispositivos
```bash
# Enviar salida a la nada (descartar)
ls -la > /dev/null

# Generar archivo vacío desde /dev/null
cat /dev/null > archivo_vacio.txt

# Escribir en el terminal actual
echo "Hola" > /dev/tty
```

**Explicación:**
- `/dev/null` descarta todo; leerlo produce EOF inmediato.
- `/dev/tty` representa tu terminal actual; escribir ahí imprime directo al usuario.

---

## 2.2 TTY, PTY y terminales

### Identificar tu terminal
```bash
tty
```
**Salida esperada:** `/dev/pts/0` (o similar)
- `pts` = pseudo-terminal (emuladores, SSH, Docker).

```bash
who
w
```
**Explicación:**
- `who` y `w` muestran usuarios conectados, sus TTYs, comandos activos y carga del sistema.

### Variables de entorno relacionadas
```bash
echo $TERM   # Tipo de terminal (xterm-256color, linux)
echo $COLORTERM
echo $LANG
```
**Uso:** afectan capacidades gráficas, color y localización.

**💡 Tip:** si ves caracteres raros, revisa `TERM` y configura `export TERM=xterm-256color`.

---

## 2.3 Pipes, filtros y composición

Los pipes (`|`) conectan la salida de un comando con la entrada de otro. Aprende a construir "cadenas" de procesamiento.

```bash
# Listar procesos, filtrar por nombre y ordenar por memoria
ps aux | grep -v grep | grep nginx | sort -k4 -nr | head
```

**Salida esperada:** procesos `nginx` ordenados por %MEM.

**Desglose:**
- `ps aux`: lista todos los procesos.
- `grep -v grep`: elimina la línea del propio grep.
- `sort -k4 -nr`: columna 4 (MEM), numérico, descendente.
- `head`: primeras líneas.

```bash
# Encontrar archivos grandes y mostrarlos ordenados
find /var/log -type f -size +50M 2>/dev/null | xargs -r du -h | sort -h | tail
```

**Explicación:**
- `find`: busca >50MB.
- `2>/dev/null`: oculta errores de permisos.
- `xargs -r du -h`: calcula tamaño legible.
- `sort -h`: orden human-readable.
- `tail`: los más grandes.

**💡 Tip:** usa `tee` para bifurcar la salida a archivo mientras sigues viéndola en pantalla.
```bash
journalctl -u ssh.service -n 100 | tee ssh-ultimos.log
```

---

## 2.4 Entrada/Salida en archivos y texto

### Lectura, escritura y visualización
```bash
# Crear archivo de ejemplo
printf "Linea 1\nLinea 2\nLinea 3\n" > demo.txt

# Ver principio y final
head -n 2 demo.txt
tail -n 2 demo.txt

# Mostrar con numeración y saltos de página
nl -ba demo.txt | less

# Concatenar múltiples archivos
cat *.conf 2>/dev/null | wc -l
```

**Salida esperada:**
- `head/tail`: primeras/últimas líneas.
- `nl -ba`: numera todas las líneas (incluye vacías).
- `wc -l`: cuenta líneas.

### Búsqueda y reemplazo
```bash
# Buscar patrones en archivos
grep -Rin "ERROR" /var/log 2>/dev/null | head

# Reemplazo inline (GNU sed)
sed -i 's/Linea/Linea corregida/g' demo.txt

# En macOS (BSD sed):
sed -i '' 's/Linea/Linea corregida/g' demo.txt
```

**💡 Tip:** valida con `grep` antes de un `sed -i` para evitar cambios no deseados.

---

## 2.5 I/O de procesos: redirecciones avanzadas

### Operadores útiles
- `<<< "texto"`: Here-string. Pasa una cadena de texto directamente como entrada estándar (`stdin`) a un comando, sin necesidad de archivos temporales. Útil para probar comandos con texto fijo.
- `<<EOF ... EOF`: Here-documento. Permite pasar bloques largos de texto (múltiples líneas) como `stdin` a un comando. Termina con la palabra clave (EOF). Ideal para crear archivos o scripts inline.
- `>|`: Sobrescribe un archivo incluso si la opción `noclobber` de bash está activada (que normalmente previene sobrescribir archivos existentes).

```bash
# Here-string: Busca "linux" en el texto dado, ignorando mayúsculas
grep -i linux <<< "Aprendiendo Linux desde cero"
# Salida: Linux (encuentra la palabra)

# Here-doc: Crea un script bash con contenido multilínea
cat <<'EOF' > script.sh
#!/usr/bin/env bash
set -euo pipefail
echo "Hola desde script"
EOF
chmod +x script.sh
# Ahora script.sh es un archivo ejecutable con el contenido del here-doc
```

**Explicación:** Estos operadores simplifican la automatización en scripts, permitiendo insertar texto directamente sin crear archivos intermedios. El here-string es para texto corto; el here-doc para bloques largos. `>|` es útil cuando bash protege archivos por defecto.

---

## 2.6 Ejercicios prácticos guiados

### Ejercicio 1: Redirecciones y pipes
Objetivo: dominar `>`, `>>`, `2>`, `|`, `tee`.

**Comando:**
```bash
printf "%s\n" {1..100} | tee numeros.txt | grep -E '^[13579]$|[13579]$' > impares.txt 2> errores.log
wc -l numeros.txt impares.txt
```

**Explicación paso a paso:**
- `printf "%s\n" {1..100}`: Genera los números del 1 al 100, uno por línea.
- `| tee numeros.txt`: Envía la salida a `tee`, que la duplica: una copia va a `numeros.txt` y la otra continúa por el pipe.
- `| grep -E '^[13579]$|[13579]$'`: Filtra líneas que empiecen o terminen con dígitos impares (1,3,5,7,9). El regex busca números de un dígito que sean impares.
- `> impares.txt`: Redirige la salida filtrada (números impares) a `impares.txt`.
- `2> errores.log`: Redirige cualquier error (stderr) a `errores.log`.
- `wc -l numeros.txt impares.txt`: Cuenta las líneas en ambos archivos.

**Salida esperada:**
- `numeros.txt`: 100 líneas (todos los números del 1 al 100).
- `impares.txt`: 50 líneas (números impares: 1,3,5,...,99).

**Aprendizaje:** Practica cómo combinar pipes para procesar datos en cadena, redirigir salidas y errores, y usar `tee` para bifurcar flujos.

### Ejercicio 2: Inspección básica de procesos
```bash
sleep 10 &
echo $! > pid.txt
ps -p $(cat pid.txt)
kill $(cat pid.txt)
```

**Explicación paso a paso:**
- `sleep 10 &`: Ejecuta el comando `sleep 10` en segundo plano (background), lo que pausa el proceso por 10 segundos sin bloquear la terminal.
- `echo $! > pid.txt`: `$!` es la variable que contiene el PID del último proceso ejecutado en background. Se guarda en `pid.txt`.
- `ps -p $(cat pid.txt)`: `ps -p` muestra información detallada del proceso con el PID leído de `pid.txt`. `$(cat pid.txt)` es sustitución de comando para obtener el PID.
- `kill $(cat pid.txt)`: Envía una señal SIGTERM al proceso para terminarlo.

**Salida esperada:**
- `ps -p`: Muestra detalles como PID, TTY, tiempo de CPU, comando (sleep 10).
- El proceso `sleep` se detiene antes de los 10 segundos.

**Aprendizaje:** Entiende cómo manejar procesos en background, capturar PIDs y usar `ps` para inspeccionar procesos en ejecución.

---

## 2.7 Tips y buenas prácticas
- Usa `set -euo pipefail` en scripts para manejo robusto de errores.
- Valida primero con `head`, `tail`, `wc -l` antes de procesar archivos grandes.
- Redirige `stderr` por separado cuando depures (`2>debug.log`).
- Documenta cambios de permisos al crear archivos.

---

## 2.8 Referencias rápidas
- `man bash`, `man tee`, `man grep`, `man sed`