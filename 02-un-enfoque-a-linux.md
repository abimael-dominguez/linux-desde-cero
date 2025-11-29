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

## 2.4 Archivos especiales: /proc y /sys

### /proc: información de procesos y kernel
```bash
# Información del kernel
cat /proc/version
uname -a

# CPU y memoria
cat /proc/cpuinfo | head -20
cat /proc/meminfo | head -20

# PID actual y su cmdline
echo $$          # PID del shell actual
cat /proc/$$/cmdline | tr "\0" " "; echo
```

**Explicación:** `/proc` es un pseudo-filesystem que expone estados del kernel y procesos en tiempo real.

### /sys: configuración del sistema y dispositivos
```bash
# Ver dispositivos de bloque (discos)
ls -l /sys/block

# Parámetros de dispositivos
ls /sys/class/net
cat /sys/class/net/eth0/mtu    # MTU actual
```

**💡 Tip:** cambios en `/sys` suelen requerir privilegios y afectan hardware en vivo.

---

## 2.5 Entrada/Salida en archivos y texto

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

## 2.6 I/O de procesos: redirecciones avanzadas

### Operadores útiles
- `<<< "texto"`: here-string (pasa texto directo a `stdin`).
- `<<EOF ... EOF`: here-documento (bloques largos).
- `>|`: sobrescribe incluso si `noclobber` está activo.
- `exec`: reconfigura descriptores del shell actual.

```bash
# Here-string
grep -i linux <<< "Aprendiendo Linux desde cero"

# Here-doc para crear un archivo
cat <<'EOF' > script.sh
#!/usr/bin/env bash
set -euo pipefail
echo "Hola desde script"
EOF
chmod +x script.sh

# Reasignar stdout a un archivo para el shell actual
exec 1>salida_global.log
printf "Esta linea va al archivo stdout global\n"
# Restaurar stdout a la terminal
exec 1>&2; exec 2>/dev/tty
```

**Explicación:** `exec` cambia los descriptores del proceso shell. Úsalo con cuidado.

---

## 2.7 I/O y red: sockets y herramientas

```bash
# Ver puertos en escucha
ss -tuln

# Probar conexión TCP simple (instalar netcat)
apt update && apt install -y netcat-openbsd
nc -vz google.com 80

# Escuchar en un puerto local (ejemplo)
nc -l 12345
# En otra terminal:
echo "Hola" | nc 127.0.0.1 12345
```

**Salida esperada:**
- `ss -tuln`: servicios escuchando (tcp/udp) y direcciones.
- `nc -vz`: prueba conexión y reporta si el puerto está abierto.
- `nc -l`: muestra el mensaje recibido por el socket.

**💡 Tip de seguridad:** limitar accesos con firewall (`ufw`, `iptables`) y no dejar `nc -l` en entornos productivos.

---

## 2.8 Monitoreo de I/O del sistema

```bash
# I/O de disco
apt install -y iotop sysstat
sudo iotop      # I/O por proceso (requiere CAP_SYS_ADMIN)
iostat -x 1 5   # Estadísticas extendidas cada 1s, 5 iteraciones

# I/O de archivos en tiempo real
apt install -y inotify-tools
inotifywait -m -r -e create,modify,delete /var/log

# I/O del kernel y mensajes
dmesg | less
journalctl -f   # Follow logs en tiempo real
```

**Explicación:**
- `iotop`: consumo de I/O por proceso.
- `iostat`: latencia, throughput y utilización de discos.
- `inotifywait`: eventos de filesystem.
- `journalctl`: sistema de logging de systemd.

---

## 2.9 Ejercicios prácticos guiados

### Ejercicio 1: Redirecciones y pipes
Objetivo: dominar `>`, `>>`, `2>`, `|`, `tee`.
```bash
printf "%s\n" {1..100} | tee numeros.txt | grep -E '^[13579]$|[13579]$' > impares.txt 2> errores.log
wc -l numeros.txt impares.txt
```
**Salida esperada:**
- `numeros.txt`: 100 líneas
- `impares.txt`: 50 líneas

### Ejercicio 2: Inspección de procesos y /proc
```bash
sleep 120 &
echo $! > pid.txt
cat /proc/$(cat pid.txt)/status | head -20
kill $(cat pid.txt)
```
**Explicación:**
- `sleep 120 &`: ejecuta en segundo plano.
- `$!`: PID del último job en background.
- `/proc/<pid>/status`: estado detallado.

### Ejercicio 3: Monitoreo de I/O
```bash
( dd if=/dev/zero of=prueba.bin bs=1M count=200 ) &
iostat -x 1 3
```
**Explicación:**
- `dd`: genera I/O de escritura controlado.
- `iostat`: verifica comportamiento del disco durante la operación.

---

## 2.10 Tips y buenas prácticas
- Usa `set -euo pipefail` en scripts para manejo robusto de errores.
- Valida primero con `head`, `tail`, `wc -l` antes de procesar archivos grandes.
- Prefiere `ss` sobre `netstat` (más moderno y sin dependencias).
- Redirige `stderr` por separado cuando depures (`2>debug.log`).
- Documenta cambios de `umask` y permisos al crear archivos.
- No ejecutes comandos intensivos en I/O en servidores en horario pico.

---

## 2.11 Referencias rápidas
- `man bash`, `man 2 open`, `man tee`, `man grep`, `man sed`, `man awk`
- `info coreutils` para detalles exhaustivos de utilidades GNU.

---

## 2.12 Casos de Uso Real en el Trabajo (SysAdmin/DevOps)

Estas son situaciones comunes que enfrentarán en entornos laborales reales.

### Caso 1: Limpiar un log gigante sin detener el servicio
**Problema:** Un servidor web tiene un log de 50GB (`access.log`) y el disco está lleno. No puedes reiniciar el servicio (Apache/Nginx) porque es producción.
**Solución Incorrecta:** `rm access.log` (El proceso sigue escribiendo en el descriptor de archivo borrado y el espacio no se libera).
**Solución Profesional:** Truncar el archivo.
```bash
# Opción 1: Redirección nula (la más rápida y común)
> /var/log/nginx/access.log

# Opción 2: Usando truncate
truncate -s 0 /var/log/nginx/access.log
```
**Por qué funciona:** Mantiene el mismo inodo y descriptor de archivo, pero el tamaño se vuelve 0 bytes. El servicio sigue escribiendo felizmente desde el byte 0.

### Caso 2: ¿Quién tiene bloqueado este archivo?
**Problema:** Intentas desmontar un USB o borrar un directorio y obtienes "Device or resource busy".
**Herramienta:** `lsof` (List Open Files) o `fuser`.
```bash
# Ver quién usa el archivo/directorio
lsof /mnt/backup
# O
fuser -v /mnt/backup

# Matar todos los procesos que usan ese punto de montaje (¡Cuidado!)
fuser -k -v /mnt/backup
```

### Caso 3: Depurar scripts que fallan silenciosamente
**Problema:** Un cronjob falla pero no ves nada en la salida.
**Solución:** Redirigir stdout y stderr + modo debug.
```bash
#!/bin/bash
set -x  # Imprime cada comando antes de ejecutarlo
exec > /tmp/debug_script.log 2>&1  # Todo va al log

echo "Iniciando backup..."
# ... resto del script
```

---

## 2.13 Dinámicas para clase en vivo (Instructor)

Ejercicios visuales para despertar a la clase y demostrar conceptos en tiempo real.

### Dinámica 1: "La carrera del disco vs RAM"
**Objetivo:** Demostrar la velocidad de I/O y el concepto de dispositivos especiales.
```bash
# Escribir a disco (lento - limitado por I/O)
# Nota: conv=fdatasync asegura que se escriba físicamente
time dd if=/dev/zero of=testfile bs=1M count=1000 conv=fdatasync

# Escribir a /dev/null (rápido - limitado por CPU)
time dd if=/dev/zero of=/dev/null bs=1M count=10000
```
**Pregunta:** "¿Por qué el segundo comando procesó 10 veces más datos en una fracción del tiempo?"

### Dinámica 2: "Chat Hacker" (Sockets)
**Objetivo:** Entender que "todo es un archivo", incluso la red.
1.  **Instructor:** Ejecuta `nc -l 8080` (Se pone a escuchar).
2.  **Alumno:** Ejecuta `nc localhost 8080` (o la IP del instructor).
3.  **Acción:** Escriban mensajes y vean cómo aparecen en la otra terminal.
4.  **Bonus:** Redirigir un archivo al chat: `cat /etc/issue | nc localhost 8080`.

### Dinámica 3: "Espiando procesos" (File Descriptors)
**Objetivo:** Ver los archivos abiertos de un proceso en tiempo real.
1.  Abrir un editor de texto en una terminal: `nano secreto.txt`.
2.  En otra terminal, buscar su PID: `pgrep -a nano`.
3.  Listar sus descriptores de archivo: `ls -l /proc/<PID>/fd`.
4.  **Resultado:** Verán `0`, `1`, `2` (stdin, stdout, stderr) apuntando a `/dev/pts/X` (la terminal) y quizás el descriptor del archivo `secreto.txt`.