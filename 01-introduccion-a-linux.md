# 1. Introducción a Linux

Este módulo se cubre el **Sábado 1 de 9:00 a 11:00**. Se combina mínima teoría con práctica inmediata dentro de contenedores Docker o máquinas virtuales, preparando el terreno para el resto del curso.

## 1.1 ¿Qué es Linux?

Linux es un núcleo (kernel) libre y de código abierto que, combinado con utilidades GNU y otros proyectos, forma sistemas operativos completos. Sus pilares son estabilidad, seguridad y flexibilidad para servidores, dispositivos embebidos y escritorios.

### Objetivos rápidos
- Comprender la diferencia entre kernel y sistema operativo.
- Identificar ventajas de Linux frente a sistemas propietarios.

### Actividad práctica (15 min)

#### 1. Crear o entrar a un contenedor base

```bash
docker run -it --rm ubuntu:22.04 bash
```

**Explicación del comando:**
- `docker run`: ejecuta un nuevo contenedor
- `-it`: modo interactivo con terminal (`-i` = interactivo, `-t` = pseudo-TTY)
- `--rm`: elimina el contenedor automáticamente al salir
- `ubuntu:22.04`: imagen base de Ubuntu versión 22.04 LTS
- `bash`: comando a ejecutar (shell bash)

**Salida esperada:**
```
Unable to find image 'ubuntu:22.04' locally
22.04: Pulling from library/ubuntu
...
Status: Downloaded newer image for ubuntu:22.04
root@a1b2c3d4e5f6:/#
```

**Explicación de la salida:**
- Docker descarga la imagen si no existe localmente
- El prompt cambia a `root@[ID-CONTENEDOR]` indicando que estás dentro del contenedor como usuario root
- El `#` al final indica privilegios de superusuario

**💡 Tip:** Si ya tienes la imagen descargada, el contenedor inicia inmediatamente sin descargar nada.

---

#### 2. Consultar versión del kernel y la distribución

```bash
uname -sr
```

**Salida esperada:**
```
Linux 5.15.0-91-generic
```

**Explicación de la salida:**
- `Linux`: nombre del kernel
- `5.15.0-91-generic`: versión completa del kernel
  - `5`: versión mayor
  - `15`: versión menor
  - `0-91`: revisión y número de compilación
  - `generic`: variante del kernel (optimizado para uso general)

**Opciones adicionales útiles:**
```bash
uname -a        # Toda la información del sistema
uname -r        # Solo la versión del kernel
uname -m        # Arquitectura de la máquina (x86_64, aarch64, etc.)
uname -n        # Nombre del host
uname -o        # Nombre del sistema operativo
```

**Salida de `uname -a`:**
```
Linux a1b2c3d4e5f6 5.15.0-91-generic #101-Ubuntu SMP Tue Nov 14 13:30:08 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```

---

```bash
cat /etc/os-release
```

**Salida esperada:**
```
PRETTY_NAME="Ubuntu 22.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.3 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy
```

**Explicación de campos importantes:**
- `NAME`: nombre de la distribución
- `VERSION_ID`: versión numérica (útil para scripts)
- `VERSION_CODENAME`: nombre en clave de la versión (jammy)
- `ID_LIKE`: familia de distribuciones (debian indica compatibilidad con paquetes .deb)

**Comandos alternativos:**
```bash
lsb_release -a      # Información detallada de la distribución (si está instalado)
hostnamectl         # Información del sistema y SO
cat /etc/issue      # Versión del sistema (formato simple)
```

**💡 Tip:** En sistemas embebidos o contenedores mínimos, algunos de estos archivos pueden no existir.

---

#### 3. Investigar módulos del kernel cargados

```bash
lsmod | head
```

**Salida esperada:**
```
Module                  Size  Used by
xt_conntrack           16384  1
nf_conntrack          139264  1 xt_conntrack
nf_defrag_ipv6         24576  1 nf_conntrack
nf_defrag_ipv4         16384  1 nf_conntrack
ip_tables              32768  0
x_tables               40960  2 xt_conntrack,ip_tables
overlay               147456  0
bridge                176128  0
stp                    16384  1 bridge
```

**Explicación de las columnas:**
- `Module`: nombre del módulo del kernel
- `Size`: tamaño en bytes que ocupa en memoria
- `Used by`: contador de referencias y módulos que lo usan

**Comandos relacionados útiles:**
```bash
lsmod                          # Lista todos los módulos cargados
lsmod | wc -l                  # Cuenta cuántos módulos hay cargados
modinfo <nombre_modulo>        # Información detallada de un módulo
modinfo overlay                # Ejemplo: info del módulo overlay (usado por Docker)
```

**Salida de `modinfo overlay`:**
```
filename:       /lib/modules/5.15.0-91-generic/kernel/fs/overlayfs/overlay.ko
license:        GPL
description:    Overlay filesystem
author:         Miklos Szeredi <miklos@szeredi.hu>
...
```

**Más comandos para explorar el sistema:**

```bash
# Ver información de CPU
lscpu
cat /proc/cpuinfo

# Ver información de memoria
free -h
cat /proc/meminfo | head

# Ver dispositivos PCI
lspci

# Ver dispositivos USB
lsusb

# Ver dispositivos de bloque (discos)
lsblk

# Ver información del hardware
dmidecode -t system    # Requiere privilegios root
```

**💡 Tips importantes:**
- Los módulos del kernel son controladores cargables que extienden la funcionalidad sin recompilar
- En contenedores Docker, los módulos provienen del kernel del host
- `lsmod` lee información de `/proc/modules`

## 1.2 ¿Qué son las distribuciones?

Una distribución empaqueta el kernel con gestores de paquetes, utilidades y configuraciones específicas (como Debian, Fedora o Arch). Se clasifican por objetivo (servidor, escritorio, seguridad) y modelo de actualización.

### Comparativa exprés
| Distribución | Gestor | Ciclo     | Caso de uso             |
|--------------|--------|-----------|-------------------------|
| Debian       | APT    | estable   | Servidores e IoT        |
| Fedora       | DNF    | rápido    | Desktop cutting-edge    |
| Arch         | Pacman | rolling   | Usuarios avanzados      |

### Actividad práctica (20 min)

#### 1. Listar paquetes instalados y contarlos

```bash
apt list --installed 2>/dev/null | wc -l
```

**Explicación del comando:**
- `apt list --installed`: lista todos los paquetes instalados en el sistema
- `2>/dev/null`: redirige errores (stderr) a /dev/null para ocultarlos
- `|`: tubería (pipe) que pasa la salida al siguiente comando
- `wc -l`: cuenta el número de líneas

**Salida esperada:**
```
412
```

**Explicación:** El número indica cuántos paquetes están instalados. En una instalación mínima de Ubuntu puede haber ~400 paquetes, en un sistema de escritorio completo puede superar los 2000.

**Comandos relacionados:**
```bash
# Ver los primeros 10 paquetes instalados
apt list --installed 2>/dev/null | head -10

# Salida esperada:
# Listing...
# adduser/jammy,now 3.118ubuntu5 all [installed]
# apt/jammy-updates,now 2.4.11 amd64 [installed]
# base-files/jammy-updates,now 12ubuntu4.5 amd64 [installed]
# base-passwd/jammy,now 3.5.52build1 amd64 [installed]
# bash/jammy,now 5.1-6ubuntu1 amd64 [installed]

# Buscar si un paquete específico está instalado
dpkg -l | grep vim

# Ver información detallada de un paquete
apt show vim

# Ver archivos instalados por un paquete
dpkg -L vim-common

# Buscar qué paquete proporciona un archivo
dpkg -S /usr/bin/vim
```

**💡 Tip:** `dpkg` es el gestor de paquetes de bajo nivel, mientras `apt` es la interfaz de alto nivel más amigable.

---

#### 2. Buscar herramientas de red

```bash
apt search net-tools
```

**Salida esperada:**
```
Sorting... Done
Full Text Search... Done
net-tools/jammy 1.60+git20181103.0eebece-1ubuntu5 amd64
  NET-3 networking toolkit

gnome-nettool/jammy 42.0-1 amd64
  network information tool for GNOME
```

**Explicación de la salida:**
- `net-tools/jammy`: nombre del paquete y versión de Ubuntu
- `1.60+git...`: versión del paquete
- `amd64`: arquitectura del procesador
- Descripción breve del paquete

**Instalar el paquete encontrado:**
```bash
apt update                    # Actualiza el índice de paquetes
apt install -y net-tools      # Instala el paquete (-y confirma automáticamente)
```

**Salida esperada del install:**
```
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  net-tools
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 204 kB of archives.
After this operation, 819 kB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu jammy/main amd64 net-tools amd64 1.60+git20181103.0eebece-1ubuntu5 [204 kB]
Fetched 204 kB in 1s (342 kB/s)
Selecting previously unselected package net-tools.
(Reading database ... 4395 files and directories currently installed.)
Preparing to unpack .../net-tools_1.60+git20181103.0eebece-1ubuntu5_amd64.deb ...
Unpacking net-tools (1.60+git20181103.0eebece-1ubuntu5) ...
Setting up net-tools (1.60+git20181103.0eebece-1ubuntu5) ...
```

**Explicación:** 
- Muestra el tamaño de descarga (204 kB) y espacio en disco necesario (819 kB)
- Descarga el paquete .deb desde los repositorios
- Desempaqueta e instala el paquete

**Comandos útiles de búsqueda:**
```bash
# Búsqueda más específica
apt search network | grep -i tool

# Buscar paquetes que contienen un archivo específico (requiere apt-file)
apt install apt-file
apt-file update
apt-file search ifconfig

# Listar paquetes disponibles con patrón
apt list 'net-*'

# Ver dependencias de un paquete
apt depends net-tools

# Ver qué paquetes dependen de este
apt rdepends net-tools
```

**💡 Tip:** Usa `apt search` para búsquedas amplias y `apt-cache search` para búsquedas más rápidas en caché.

---

#### 3. Gestores de paquetes en diferentes distribuciones

**Debian/Ubuntu (APT - Advanced Package Tool):**
```bash
# Actualizar índice de paquetes
apt update

# Actualizar todos los paquetes instalados
apt upgrade

# Instalar un paquete
apt install nombre-paquete

# Remover un paquete (mantiene configuración)
apt remove nombre-paquete

# Remover completamente (incluye configuración)
apt purge nombre-paquete

# Buscar paquetes
apt search palabra-clave

# Limpiar caché de paquetes descargados
apt clean
```

**Fedora/RHEL/CentOS (DNF - Dandified YUM):**
```bash
# Actualizar índice
dnf check-update

# Actualizar sistema
dnf upgrade

# Instalar paquete
dnf install nombre-paquete

# Remover paquete
dnf remove nombre-paquete

# Buscar paquetes
dnf search palabra-clave

# Ver información de paquete
dnf info nombre-paquete

# Listar paquetes instalados
dnf list installed

# Limpiar caché
dnf clean all
```

**Arch Linux (Pacman):**
```bash
# Actualizar sistema completo
pacman -Syu

# Instalar paquete
pacman -S nombre-paquete

# Remover paquete
pacman -R nombre-paquete

# Remover con dependencias huérfanas
pacman -Rns nombre-paquete

# Buscar paquetes
pacman -Ss palabra-clave

# Listar paquetes instalados
pacman -Q

# Información de paquete
pacman -Qi nombre-paquete
```

**Comparativa rápida:**

| Acción | Debian/Ubuntu | Fedora/RHEL | Arch |
|--------|---------------|-------------|------|
| Actualizar índice | `apt update` | `dnf check-update` | `pacman -Sy` |
| Instalar | `apt install pkg` | `dnf install pkg` | `pacman -S pkg` |
| Remover | `apt remove pkg` | `dnf remove pkg` | `pacman -R pkg` |
| Buscar | `apt search word` | `dnf search word` | `pacman -Ss word` |
| Actualizar sistema | `apt upgrade` | `dnf upgrade` | `pacman -Syu` |

**💡 Tips importantes:**
- Siempre ejecuta `apt update` antes de `apt install` para tener el índice actualizado
- En producción, evita `apt upgrade` sin revisar; usa `apt list --upgradable` primero
- Los gestores de paquetes requieren privilegios root (usa `sudo`)
- Puedes combinar acciones: `apt update && apt upgrade -y`

## 1.3 Entorno de trabajo: EL SHELL Y X WINDOW

- **Shell**: interfaz de comandos (bash, zsh) que permite automatizar tareas mediante scripts.
- **X Window System**: capa gráfica modular que habilita escritorios como GNOME o KDE y soporta arquitectura cliente/servidor.

### Flujo sugerido (25 min)

#### 1. Identificar shell actual

```bash
echo $SHELL
```

**Salida esperada:**
```
/bin/bash
```

**Explicación:** 
- `$SHELL` es una variable de entorno que contiene la ruta al shell de login del usuario
- `/bin/bash` indica que Bash (Bourne Again Shell) es el shell predeterminado
- Otros posibles valores: `/bin/zsh`, `/bin/sh`, `/bin/dash`, `/bin/fish`

**Comando alternativo para ver el shell en ejecución:**
```bash
ps -p $$ -o cmd=
```

**Salida esperada:**
```
bash
```

**Explicación del comando:**
- `ps`: muestra información de procesos
- `-p $$`: selecciona el proceso con PID igual a `$$` (variable que contiene el PID del shell actual)
- `-o cmd=`: muestra solo la columna de comando, sin encabezado
- Esto muestra el shell que está ejecutando el comando actualmente

**Más formas de verificar el shell:**
```bash
# Ver versión de bash
bash --version

# Salida esperada:
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
# Copyright (C) 2020 Free Software Foundation, Inc.

# Ver todos los shells disponibles en el sistema
cat /etc/shells

# Salida esperada:
# /bin/sh
# /bin/bash
# /usr/bin/bash
# /bin/rbash
# /usr/bin/rbash
# /usr/bin/sh
# /bin/dash
# /usr/bin/dash

# Ver qué shell está usando un usuario específico
getent passwd $USER | cut -d: -f7

# Ver el shell predeterminado del sistema
readlink /bin/sh
# Salida típica: dash (en Ubuntu) o bash (en otros sistemas)
```

**💡 Tip:** `$SHELL` muestra el shell de login, pero puedes estar ejecutando un shell diferente. Usa `ps -p $$` para verificar el shell actual.

---

#### 2. Practicar navegación básica

```bash
pwd
```

**Salida esperada:**
```
/root
```

**Explicación:** 
- `pwd` = Print Working Directory
- Muestra la ruta absoluta del directorio actual
- En contenedores Docker como root, típicamente inicias en `/root`
- En sistemas normales como usuario regular, estarías en `/home/usuario`

---

```bash
ls -lha
```

**Salida esperada:**
```
total 24K
drwx------ 1 root root 4.0K Nov 27 10:30 .
drwxr-xr-x 1 root root 4.0K Nov 27 10:25 ..
-rw-r--r-- 1 root root  571 Apr 10  2021 .bashrc
-rw-r--r-- 1 root root  161 Jul  9  2019 .profile
drwxr-xr-x 2 root root 4.0K Nov 27 10:30 .cache
```

**Explicación detallada de cada columna:**

1. **Permisos** (`drwx------`):
   - Primer carácter: tipo (`d`=directorio, `-`=archivo, `l`=enlace)
   - Siguientes 3: permisos del propietario (rwx = lectura, escritura, ejecución)
   - Siguientes 3: permisos del grupo (---)
   - Últimos 3: permisos de otros (---)

2. **Enlaces duros** (`1`):
   - Número de enlaces duros al archivo/directorio
   - Directorios tienen al menos 2 (el directorio mismo y `.`)

3. **Propietario** (`root`):
   - Usuario dueño del archivo

4. **Grupo** (`root`):
   - Grupo propietario del archivo

5. **Tamaño** (`4.0K`):
   - Tamaño en formato legible gracias a `-h`
   - Directorios muestran el tamaño de los metadatos, no su contenido

6. **Fecha** (`Nov 27 10:30`):
   - Fecha de última modificación

7. **Nombre** (`.bashrc`):
   - Nombre del archivo/directorio
   - `.` al inicio indica archivo oculto

**Explicación de las opciones:**
- `-l`: formato largo (detallado)
- `-h`: tamaños en formato human-readable (K, M, G)
- `-a`: muestra todos los archivos, incluyendo ocultos (que empiezan con `.`)

**Variaciones útiles del comando ls:**
```bash
# Solo archivos (sin directorios)
ls -lh | grep ^-

# Solo directorios
ls -lh | grep ^d

# Ordenar por tamaño (más grande primero)
ls -lhS

# Ordenar por fecha (más reciente primero)
ls -lht

# Ordenar por fecha (más antiguo primero)
ls -lhtr

# Recursivo (incluye subdirectorios)
ls -R

# Mostrar con indicadores de tipo
ls -F
# Salida: directorio/ ejecutable* enlace@ socket=

# Listado con inodos
ls -i

# Un archivo por línea (útil para scripts)
ls -1

# Con código de color según tipo
ls --color=auto
```

**Más comandos de navegación y exploración:**

```bash
# Cambiar al directorio home del usuario
cd ~
# o simplemente
cd

# Volver al directorio anterior
cd -

# Subir un nivel
cd ..

# Subir dos niveles
cd ../..

# Ir a un directorio específico
cd /etc

# Ver el árbol de directorios (si está instalado tree)
apt install tree -y
tree -L 2 /etc    # Muestra 2 niveles de profundidad

# Salida esperada:
# /etc
# ├── adduser.conf
# ├── alternatives
# │   ├── awk -> /usr/bin/mawk
# │   └── ...
# ├── apt
# │   ├── sources.list
# │   └── ...
# ...

# Buscar archivos por nombre
find /etc -name "*.conf" -type f 2>/dev/null | head -5

# Salida esperada:
# /etc/adduser.conf
# /etc/nsswitch.conf
# /etc/host.conf
# /etc/resolv.conf
# /etc/sysctl.conf

# Ver el tamaño de directorios
du -sh /*

# Salida esperada:
# 0       /bin
# 0       /boot
# 0       /dev
# 94M     /etc
# 8.0K    /home
# ...
```

**💡 Tips prácticos:**
- Usa `Tab` para autocompletar nombres de archivos y directorios
- Usa `Ctrl+R` para buscar en el historial de comandos
- `!!` repite el último comando
- `!$` usa el último argumento del comando anterior
- Alias útil: `alias ll='ls -lha'` (agrégalo a `.bashrc`)

---

#### 3. Variables de entorno para X Window

```bash
echo $DISPLAY
```

**Salida esperada (si X11 está activo):**
```
:0
```

**Salida en contenedor sin X11:**
```
(salida vacía)
```

**Explicación:**
- `$DISPLAY` indica dónde mostrar las ventanas X11
- `:0` = primera sesión X local (display 0)
- `:1` = segunda sesión X
- `localhost:10.0` = sesión X remota vía SSH con X forwarding
- Si está vacío, no hay servidor X disponible

---

```bash
echo $XDG_SESSION_TYPE
```

**Salida esperada:**
```
x11
```
o
```
wayland
```
o
```
(vacío si no hay sesión gráfica)
```

**Explicación:**
- `x11`: sesión usando X Window System (tradicional)
- `wayland`: sesión usando Wayland (protocolo moderno)
- `tty`: sesión en terminal virtual sin entorno gráfico

**Más variables de entorno importantes:**

```bash
# Ver todas las variables de entorno
env
# o
printenv

# Variables comunes importantes:
echo $USER          # Usuario actual
echo $HOME          # Directorio home del usuario
echo $PATH          # Rutas donde se buscan ejecutables
echo $PWD           # Directorio actual
echo $OLDPWD        # Directorio anterior
echo $LANG          # Configuración de idioma
echo $TERM          # Tipo de terminal
echo $EDITOR        # Editor predeterminado

# Ejemplo de salida:
# $USER: root
# $HOME: /root
# $PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# $PWD: /root
# $LANG: en_US.UTF-8
# $TERM: xterm

# Definir una variable temporal
MI_VARIABLE="Hola Linux"
echo $MI_VARIABLE

# Hacer una variable disponible para procesos hijos
export MI_VARIABLE_GLOBAL="Accesible en subprocesos"

# Ver una variable específica
printenv HOME
```

**💡 Tip:** Las variables con `$` al inicio son variables del shell. Para hacerlas permanentes, agrégalas a `~/.bashrc` o `~/.profile`.

---

#### 4. Ejecutar aplicación gráfica simple

```bash
# Primero, instalar paquetes de X11 si no están
apt update && apt install -y x11-apps

# Ejecutar xeyes en segundo plano
xeyes &
```

**Salida esperada (con X11 funcional):**
```
[1] 1234
```

**Explicación:**
- `&` al final ejecuta el proceso en segundo plano
- `[1]` es el número de trabajo (job number)
- `1234` es el PID (Process ID) del proceso
- Se abre una ventana con ojos que siguen el cursor

**Si no hay display X11:**
```
Error: Can't open display:
```

**Más ejemplos de aplicaciones X11 básicas:**

```bash
# Reloj analógico
xclock &

# Calculadora simple
xcalc &

# Información del display
xdpyinfo | head -20

# Ver aplicaciones gráficas en ejecución
ps aux | grep -E 'xeyes|xclock|xcalc'

# Traer proceso del segundo plano al primero
fg

# Listar trabajos en segundo plano
jobs

# Salida esperada:
# [1]+  Running                 xeyes &

# Matar un proceso en segundo plano por número de job
kill %1

# O por PID
kill 1234
```

**Comandos adicionales de gestión de procesos:**

```bash
# Ver procesos del usuario actual
ps aux | grep $USER

# Ver procesos en árbol
ps auxf
pstree

# Monitor interactivo de procesos
top
# (presiona 'q' para salir)

# Monitor interactivo mejorado (si está instalado)
htop

# Ver uso de recursos del sistema
vmstat 1 5      # Estadísticas cada 1 seg, 5 veces
iostat          # Estadísticas de I/O
free -h         # Uso de memoria

# Salida de free -h:
#               total        used        free      shared  buff/cache   available
# Mem:          7.7Gi       2.1Gi       3.2Gi       0.1Gi       2.4Gi       5.3Gi
# Swap:         2.0Gi          0B       2.0Gi
```

**💡 Tips:**
- En servidores sin entorno gráfico, no intentes ejecutar aplicaciones X11
- Para usar X11 desde SSH: `ssh -X usuario@servidor`
- Para contenedores Docker con GUI, debes compartir el socket X11:
  ```bash
  docker run -it --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix ubuntu:22.04
  ```

## 1.4 Usuarios y grupos

Linux implementa seguridad mediante cuentas (UID) y grupos (GID). Cada proceso corre con credenciales específicas y los permisos de archivos dependen de usuario, grupo y otros.

### Conceptos clave
- Archivos de configuración: `/etc/passwd`, `/etc/shadow` y `/etc/group`.
- Diferencia entre usuarios administrativos (UID 0) y regulares.
- Grupos primarios y suplementarios.

### Taller práctico (30 min)

#### 1. Revisar cuentas de usuario definidas

```bash
getent passwd | head
```

**Salida esperada:**
```
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
```

**Explicación de cada campo (separados por `:`):**

1. **Nombre de usuario** (`root`)
2. **Contraseña** (`x`): 
   - `x` = contraseña almacenada en `/etc/shadow` (archivo protegido)
   - `*` o `!` = cuenta bloqueada
3. **UID** (`0`): User ID
   - `0` = superusuario (root)
   - `1-999` = usuarios del sistema (servicios)
   - `1000+` = usuarios normales
4. **GID** (`0`): Group ID principal
5. **GECOS** (`root`): Información descriptiva del usuario (nombre completo, etc.)
6. **Directorio home** (`/root`): Directorio personal del usuario
7. **Shell** (`/bin/bash`): Shell de login
   - `/usr/sbin/nologin` = no puede iniciar sesión interactiva (cuentas de servicio)

**Comandos relacionados:**

```bash
# Ver solo usuarios reales (UID >= 1000)
getent passwd | awk -F: '$3 >= 1000 {print $1, $3, $6}'

# Ver información del usuario actual
whoami                # Nombre de usuario
id                    # UID, GID y grupos
id -u                 # Solo UID
id -g                 # Solo GID principal
id -G                 # Todos los GIDs
id -un                # Nombre de usuario
groups                # Grupos del usuario actual

# Salida esperada de 'id':
# uid=0(root) gid=0(root) groups=0(root)

# Ver quién está conectado al sistema
who
w

# Salida esperada de 'w':
# USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
# root     pts/0    192.168.1.100    10:30    0.00s  0.04s  0.00s w

# Ver historial de logins
last | head

# Ver intentos fallidos de login
lastb | head

# Ver información específica de un usuario
id root
getent passwd root
finger root           # Si está instalado
```

**💡 Tip:** `/etc/passwd` es legible por todos, pero las contraseñas hasheadas están en `/etc/shadow` (solo root puede leerlo).

---

#### 2. Revisar grupos del sistema

```bash
getent group | grep "sudo"
```

**Salida esperada:**
```
sudo:x:27:
```

**Explicación de los campos (separados por `:`):**

1. **Nombre del grupo** (`sudo`)
2. **Contraseña del grupo** (`x`): raramente usado
3. **GID** (`27`): Group ID
4. **Miembros** (vacío): lista de usuarios separados por comas

**Más comandos de grupos:**

```bash
# Ver todos los grupos
getent group

# Ver grupos del sistema (GID < 1000)
getent group | awk -F: '$3 < 1000 {print $1, $3}'

# Ver miembros de un grupo específico
getent group sudo
grep "^sudo:" /etc/group

# Ver todos los grupos de un usuario
groups usuario
id -Gn usuario

# Crear un nuevo grupo
groupadd desarrollo

# Ver el grupo recién creado
getent group desarrollo

# Salida esperada:
# desarrollo:x:1001:

# Eliminar un grupo
groupdel desarrollo
```

**💡 Tip:** Los grupos se usan para compartir permisos entre usuarios. Un usuario puede pertenecer a múltiples grupos.

---

#### 3. Crear usuario de laboratorio

```bash
useradd -m alumno && passwd alumno
```

**Explicación del comando:**
- `useradd`: comando para crear usuarios
- `-m`: crea el directorio home (`/home/alumno`)
- `alumno`: nombre del nuevo usuario
- `&&`: ejecuta el siguiente comando solo si el primero fue exitoso
- `passwd alumno`: establece la contraseña del usuario

**Salida esperada:**
```
Enter new UNIX password: ********
Retype new UNIX password: ********
passwd: password updated successfully
```

**Opciones útiles de useradd:**

```bash
# Crear usuario con opciones completas
useradd -m -s /bin/bash -c "Usuario de Prueba" -G sudo,developers prueba

# Explicación de las opciones:
# -m: crear directorio home
# -s: especificar shell (/bin/bash)
# -c: comentario/descripción (campo GECOS)
# -G: grupos adicionales (secundarios)
# -g: grupo principal (si no se especifica, se crea uno con el mismo nombre)

# Ver el usuario creado
getent passwd alumno

# Salida esperada:
# alumno:x:1001:1001::/home/alumno:/bin/sh

# Verificar que el home fue creado
ls -la /home/alumno

# Salida esperada:
# total 20
# drwxr-x--- 2 alumno alumno 4096 Nov 27 10:45 .
# drwxr-xr-x 3 root   root   4096 Nov 27 10:45 ..
# -rw-r--r-- 1 alumno alumno  220 Jan  6  2022 .bash_logout
# -rw-r--r-- 1 alumno alumno 3771 Jan  6  2022 .bashrc
# -rw-r--r-- 1 alumno alumno  807 Jan  6  2022 .profile

# Establecer contraseña sin interacción (útil en scripts)
echo "alumno:mipassword" | chpasswd

# O crear usuario sin contraseña (solo para pruebas)
passwd -d alumno

# Bloquear una cuenta de usuario
passwd -l alumno

# Desbloquear una cuenta
passwd -u alumno

# Forzar cambio de contraseña en el próximo login
passwd -e alumno

# Ver estado de la contraseña
passwd -S alumno

# Salida esperada:
# alumno P 11/27/2024 0 99999 7 -1
# (Usuario Contraseña-activa Última-modificación Min-días Max-días Warn Inactividad)
```

**Modificar usuarios existentes:**

```bash
# Cambiar el shell de un usuario
usermod -s /bin/bash alumno

# Cambiar el directorio home
usermod -d /home/nuevo_home -m alumno

# Cambiar el nombre de usuario
usermod -l nuevo_nombre viejo_nombre

# Cambiar el comentario/descripción
usermod -c "Alumno del Curso de Linux" alumno

# Deshabilitar temporalmente una cuenta (expira la cuenta)
usermod -e 1 alumno

# Habilitar nuevamente (quitar fecha de expiración)
usermod -e "" alumno

# Ver información de expiración de cuenta
chage -l alumno
```

**💡 Tips importantes:**
- `adduser` (Debian/Ubuntu) es un script interactivo más amigable que `useradd`
- En producción, siempre establece contraseñas seguras
- Los archivos de configuración de usuarios están en `/etc/skel/` y se copian al crear usuarios

---

#### 4. Alterar pertenencia a grupos

```bash
usermod -aG sudo alumno
```

**Explicación:**
- `usermod`: modifica un usuario existente
- `-aG`: **append** al grupo (añade sin quitar otros grupos)
- ⚠️ **IMPORTANTE:** Usar `-aG` no solo `-G`, o se eliminarán todos los otros grupos
- `sudo`: nombre del grupo
- `alumno`: usuario a modificar

**Salida:** (sin salida si es exitoso)

**Verificar los cambios:**

```bash
id alumno
```

**Salida esperada:**
```
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno),27(sudo)
```

**Explicación de la salida:**
- `uid=1001(alumno)`: User ID y nombre
- `gid=1001(alumno)`: Group ID principal
- `groups=1001(alumno),27(sudo)`: Todos los grupos a los que pertenece
  - `1001(alumno)`: grupo principal (creado automáticamente)
  - `27(sudo)`: grupo secundario que acabamos de añadir

**Más operaciones con grupos:**

```bash
# Ver grupos de forma más clara
groups alumno

# Salida esperada:
# alumno : alumno sudo

# Añadir usuario a múltiples grupos
usermod -aG sudo,adm,developers alumno

# Cambiar el grupo principal de un usuario
usermod -g developers alumno

# Eliminar usuario de un grupo (requiere listar todos los grupos excepto el que quieres quitar)
gpasswd -d alumno sudo

# Salida esperada:
# Removing user alumno from group sudo

# Verificar cambio
groups alumno

# Añadir de vuelta al grupo
gpasswd -a alumno sudo

# Salida esperada:
# Adding user alumno to group sudo

# Ver todos los usuarios de un grupo
getent group sudo

# Listar archivos con permisos del grupo sudo
find /etc -group sudo 2>/dev/null

# Ver qué puede hacer el grupo sudo
cat /etc/sudoers | grep -A 5 "^%sudo"

# Salida esperada:
# %sudo   ALL=(ALL:ALL) ALL
# (Los miembros del grupo sudo pueden ejecutar cualquier comando)
```

**💡 Tip crítico:** Después de añadir un usuario a un grupo, el usuario debe cerrar sesión y volver a entrar para que los cambios surtan efecto.

---

#### 5. Probar cambio de usuario y permisos

```bash
su - alumno
```

**Explicación:**
- `su`: switch user (cambiar usuario)
- `-`: login shell completo (carga variables de entorno del usuario)
- Sin `-` solo cambias usuario pero mantienes el entorno actual

**Salida esperada:**
```
alumno@hostname:~$
```

**Observa el cambio:**
- El prompt cambió de `#` (root) a `$` (usuario normal)
- El nombre cambió de `root` a `alumno`

**Verificar identidad actual:**

```bash
whoami
```

**Salida esperada:**
```
alumno
```

---

```bash
touch ~/prueba.txt
```

**Explicación:**
- `touch`: crea un archivo vacío o actualiza timestamp
- `~`: atajo al directorio home del usuario (`/home/alumno`)
- `/prueba.txt`: nombre del archivo

**Salida:** (sin salida si es exitoso)

---

```bash
ls -l ~/prueba.txt
```

**Salida esperada:**
```
-rw-r--r-- 1 alumno alumno 0 Nov 27 10:50 /home/alumno/prueba.txt
```

**Análisis detallado de los permisos:**

```
-rw-r--r-- 1 alumno alumno 0 Nov 27 10:50 /home/alumno/prueba.txt
│││││││││  │ │      │      │ │            │
│││││││││  │ │      │      │ │            └─ Nombre del archivo
│││││││││  │ │      │      │ └────────────── Fecha de modificación
│││││││││  │ │      │      └──────────────── Tamaño (0 bytes)
│││││││││  │ │      └─────────────────────── Grupo propietario
│││││││││  │ └────────────────────────────── Usuario propietario
│││││││││  └──────────────────────────────── Número de enlaces duros
││││││││└──────────────────────────────────── Otros: escritura (w)
│││││││└───────────────────────────────────── Otros: lectura (r)
││││││└────────────────────────────────────── Grupo: escritura (-)
│││││└─────────────────────────────────────── Grupo: lectura (r)
││││└──────────────────────────────────────── Usuario: ejecución (-)
│││└───────────────────────────────────────── Usuario: escritura (w)
││└────────────────────────────────────────── Usuario: lectura (r)
│└─────────────────────────────────────────── Tipo: archivo regular (-)
└──────────────────────────────────────────── 
```

**Más ejemplos prácticos de permisos:**

```bash
# Ver permisos en formato numérico (octal)
stat -c "%a %n" ~/prueba.txt

# Salida esperada:
# 644 /home/alumno/prueba.txt

# Explicación del formato octal:
# 6 (rw-) = 4(r) + 2(w) + 0(-) para el propietario
# 4 (r--) = 4(r) + 0(-) + 0(-) para el grupo
# 4 (r--) = 4(r) + 0(-) + 0(-) para otros

# Crear archivo con permisos específicos usando umask
umask 077       # Nuevos archivos sin permisos para grupo y otros
touch archivo_privado.txt
ls -l archivo_privado.txt

# Salida esperada:
# -rw------- 1 alumno alumno 0 Nov 27 10:55 archivo_privado.txt

# Restaurar umask por defecto
umask 022

# Cambiar permisos de un archivo
chmod 755 ~/prueba.txt
ls -l ~/prueba.txt

# Salida esperada:
# -rwxr-xr-x 1 alumno alumno 0 Nov 27 10:50 /home/alumno/prueba.txt

# Cambiar permisos con notación simbólica
chmod u+x ~/prueba.txt      # Añade ejecución al usuario
chmod g-w ~/prueba.txt      # Quita escritura al grupo
chmod o+r ~/prueba.txt      # Añade lectura a otros
chmod a+x ~/prueba.txt      # Añade ejecución a todos (all)

# Ver permisos efectivos
getfacl ~/prueba.txt

# Intentar cambiar el propietario (fallará si no eres root)
chown root ~/prueba.txt

# Salida esperada:
# chown: changing ownership of '/home/alumno/prueba.txt': Operation not permitted

# Volver a root
exit

# Ahora como root, cambiar propietario
chown root:root /home/alumno/prueba.txt
ls -l /home/alumno/prueba.txt

# Salida esperada:
# -rwxr-xr-x 1 root root 0 Nov 27 10:50 /home/alumno/prueba.txt

# Devolverlo al usuario alumno
chown alumno:alumno /home/alumno/prueba.txt
```

**Comandos adicionales de gestión de usuarios:**

```bash
# Ver usuarios conectados actualmente
who
w
users

# Ver último login de usuarios
lastlog

# Ver historial de comandos del usuario
history

# Cambiar a root desde usuario normal (requiere contraseña de root)
su -

# Ejecutar un comando como root (requiere estar en grupo sudo)
sudo apt update

# Convertirse en root con sudo (mantiene entorno)
sudo -i
# o
sudo su -

# Ejecutar comando como otro usuario
sudo -u alumno ls /home/alumno

# Ver qué puede ejecutar el usuario actual con sudo
sudo -l

# Salida esperada:
# User alumno may run the following commands on hostname:
#     (ALL : ALL) ALL

# Eliminar un usuario (mantiene su home)
userdel alumno

# Eliminar usuario y su directorio home
userdel -r alumno

# Ver usuarios que han usado sudo recientemente
journalctl _COMM=sudo | tail -20
```

**💡 Tips de seguridad:**
- Nunca uses `chmod 777` (da todos los permisos a todos)
- Usa `sudo` en lugar de trabajar como root directamente
- Revisa regularmente `/var/log/auth.log` para detectar accesos sospechosos
- Deshabilita login de root via SSH: `PermitRootLogin no` en `/etc/ssh/sshd_config`
- Usa claves SSH en lugar de contraseñas para mayor seguridad

**Comandos de práctica adicionales recomendados:**

```bash
# Configuración del sistema
hostname                    # Ver nombre del host
hostnamectl                 # Información completa del sistema
timedatectl                 # Configuración de fecha/hora
localectl                   # Configuración regional

# Información del hardware
lscpu                       # CPU
lsmem                       # Memoria
lsblk                       # Dispositivos de bloque
lsusb                       # Dispositivos USB
lspci                       # Dispositivos PCI
dmidecode                   # Información del hardware (requiere root)

# Monitoreo del sistema
uptime                      # Tiempo activo del sistema
dmesg | tail                # Mensajes del kernel
journalctl -xe              # Logs del sistema
systemctl status            # Estado de servicios

# Conectividad de red (requiere net-tools o iproute2)
ip addr                     # Interfaces de red y IPs
ip route                    # Tabla de rutas
ping -c 4 google.com        # Probar conectividad
ss -tuln                    # Puertos en escucha
netstat -tuln               # Alternativa (si está instalado net-tools)

# Búsqueda y navegación avanzada
locate archivo              # Búsqueda rápida (requiere updatedb)
which comando               # Ruta del ejecutable
whereis comando             # Binario, código fuente y manual
type comando                # Tipo de comando (builtin, alias, etc.)
```

---

## Apéndice: Comandos para macOS y zsh

Si trabajas en macOS o usas zsh como tu shell, aquí hay algunas diferencias y comandos específicos importantes.

### Diferencias principales entre Linux y macOS

**1. Sistema de paquetes:**
```bash
# En Linux (Debian/Ubuntu):
apt install paquete

# En macOS necesitas Homebrew:
brew install paquete

# Instalar Homebrew (si no lo tienes):
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Comandos útiles de Homebrew:
brew search nombre          # Buscar paquetes
brew info paquete          # Información del paquete
brew list                  # Paquetes instalados
brew update                # Actualizar Homebrew
brew upgrade               # Actualizar paquetes
brew cleanup               # Limpiar versiones antiguas
brew doctor                # Diagnosticar problemas
```

**2. Comandos específicos de macOS:**
```bash
# Información del sistema
system_profiler SPSoftwareDataType    # Versión de macOS
sw_vers                                # Versión resumida

# Salida esperada de sw_vers:
# ProductName:    macOS
# ProductVersion: 14.1.1
# BuildVersion:   23B81

# Gestión de aplicaciones
open -a "Safari"                      # Abrir aplicación
open .                                # Abrir Finder en directorio actual
open archivo.pdf                      # Abrir con app predeterminada

# Portapapeles
pbcopy < archivo.txt                  # Copiar contenido al portapapeles
echo "texto" | pbcopy                 # Copiar texto
pbpaste                               # Pegar desde portapapeles
pbpaste > archivo.txt                 # Guardar portapapeles en archivo

# Red
networksetup -listallhardwareports    # Listar interfaces de red
networksetup -getinfo Wi-Fi           # Info de interfaz Wi-Fi
scutil --dns                          # Configuración DNS

# Spotlight (búsqueda del sistema)
mdfind "nombre archivo"               # Buscar archivos
mdfind -name archivo                  # Buscar por nombre exacto
mdls archivo                          # Metadatos del archivo

# Notificaciones
osascript -e 'display notification "Mensaje" with title "Título"'

# Configuración
defaults read                         # Ver todas las preferencias
defaults read com.apple.dock          # Preferencias del Dock
defaults write com.apple.dock autohide -bool true    # Ocultar Dock automáticamente
killall Dock                          # Reiniciar Dock
```

**3. Diferencias en comandos estándar:**
```bash
# Linux usa GNU coreutils, macOS usa BSD coreutils

# Ejemplo con 'ls' - color por defecto:
# Linux:
ls --color=auto

# macOS:
ls -G

# Crear alias en zsh para compatibilidad:
alias ls='ls -G'

# Ejemplo con 'sed' - edición in-place:
# Linux:
sed -i 's/viejo/nuevo/g' archivo.txt

# macOS (requiere argumento vacío después de -i):
sed -i '' 's/viejo/nuevo/g' archivo.txt

# Instalar GNU coreutils en macOS:
brew install coreutils
# Los comandos GNU tendrán prefijo 'g': gls, gsed, gawk, etc.
gls --color=auto    # Ahora funciona como en Linux
```

### Características específicas de zsh

**1. Configuración de zsh:**
```bash
# Archivos de configuración (en orden de carga):
~/.zshenv          # Siempre se ejecuta
~/.zprofile        # Login shell
~/.zshrc           # Shell interactivo (el más usado)
~/.zlogin          # Login shell (después de .zshrc)
~/.zlogout         # Al cerrar sesión

# Ver el shell actual
echo $SHELL        # /bin/zsh

# Versión de zsh
zsh --version      # zsh 5.9 (x86_64-apple-darwin23.0)

# Framework Oh My Zsh (muy popular):
# Instalar Oh My Zsh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Editar configuración:
nano ~/.zshrc      # o vim, code, etc.

# Recargar configuración:
source ~/.zshrc
# o simplemente:
. ~/.zshrc
```

**2. Autocompletado mejorado en zsh:**
```bash
# Zsh tiene autocompletado más inteligente que bash

# Activar autocompletado:
autoload -Uz compinit && compinit

# Autocompletado con menú navegable:
setopt menucomplete

# Corrección de comandos:
setopt correct
setopt correctall

# Navegar historial con flechas (búsqueda incremental):
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Ejemplo de uso:
# Escribe: git co<TAB>
# Zsh sugiere: commit, checkout, config, etc.
```

**3. Expansiones y globbing avanzado:**
```bash
# Expansiones más potentes que bash

# Listar solo directorios:
ls -d *(/)

# Listar solo archivos:
ls *(.)

# Archivos modificados en las últimas 24 horas:
ls *(mh-24)

# Archivos mayores a 10MB:
ls *(Lm+10)

# Recursivo mejorado:
ls **/*.txt        # Todos los .txt recursivamente

# Excluir patrón:
ls ^*.txt          # Todo excepto .txt

# Rangos numéricos:
echo file{1..5}.txt     # file1.txt file2.txt file3.txt file4.txt file5.txt
```

**4. Plugins útiles de Oh My Zsh:**
```bash
# Editar ~/.zshrc y añadir a la línea plugins:
plugins=(
  git                    # Aliases para git
  docker                 # Autocompletado de docker
  kubectl                # Autocompletado de kubectl
  sudo                   # Presiona ESC dos veces para añadir sudo
  history                # Aliases para historial
  colored-man-pages      # Páginas man con colores
  zsh-autosuggestions    # Sugerencias mientras escribes
  zsh-syntax-highlighting # Resalta comandos válidos
)

# Instalar plugins adicionales (ejemplo):
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Temas populares de Oh My Zsh:
# Editar ZSH_THEME en ~/.zshrc:
ZSH_THEME="robbyrussell"   # Por defecto
ZSH_THEME="agnoster"       # Popular con powerline
ZSH_THEME="powerlevel10k/powerlevel10k"  # Muy personalizable
```

**5. Aliases útiles para añadir a ~/.zshrc:**
```bash
# Navegación
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Listados mejorados
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -lAh'
alias lt='ls -ltrh'        # Por fecha
alias lS='ls -lSrh'        # Por tamaño

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Utilidades
alias h='history'
alias j='jobs -l'
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%T"'
alias today='date +"%Y-%m-%d"'

# Seguridad
alias rm='rm -i'           # Confirmar antes de borrar
alias cp='cp -i'           # Confirmar antes de sobreescribir
alias mv='mv -i'           # Confirmar antes de sobreescribir

# macOS específico
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
alias cleanup='find . -name "*.DS_Store" -type f -delete'

# Recargar configuración
alias reload='source ~/.zshrc'
```

**6. Funciones útiles para zsh:**
```bash
# Añadir a ~/.zshrc:

# Crear y entrar a directorio
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extraer cualquier tipo de archivo comprimido
extract() {
  if [ -f $1 ]; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "'$1' no se puede extraer" ;;
    esac
  else
    echo "'$1' no es un archivo válido"
  fi
}

# Buscar en historial
h() {
  history | grep "$1"
}

# Crear backup de archivo
backup() {
  cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
}
```

### Migración de bash a zsh

Si vienes de bash, estos conceptos te ayudarán:

```bash
# La mayoría de scripts bash funcionan en zsh, pero:

# 1. Arrays (diferente sintaxis):
# Bash:
array=(a b c)
echo ${array[0]}        # a

# Zsh:
array=(a b c)
echo ${array[1]}        # a (¡índice empieza en 1!)

# 2. Variables:
# Bash y Zsh similares:
variable="valor"
echo $variable

# 3. Funciones:
# Bash y Zsh similares:
mi_funcion() {
  echo "Hola desde función"
}

# 4. Compatibilidad:
# Para ejecutar script bash en zsh:
#!/usr/bin/env bash
# o
emulate bash
```

### Tips finales para macOS/zsh:

💡 **Mejores prácticas:**
- Usa `brew` para instalar herramientas de desarrollo
- Instala `iterm2` como alternativa superior a Terminal.app
- Configura Oh My Zsh para productividad inmediata
- Aprende los atajos del teclado de macOS (⌘, ⌥, ⌃)
- Usa `tmux` o screen para multiplexación de terminal
- Configura claves SSH para GitHub/GitLab/BitBucket

💡 **Herramientas esenciales para desarrolladores en macOS:**
```bash
brew install git
brew install wget
brew install curl
brew install tree
brew install htop
brew install jq              # Procesador JSON
brew install fzf             # Búsqueda difusa en línea de comandos
brew install ripgrep         # grep más rápido
brew install bat             # cat con sintaxis highlight
brew install exa             # ls moderno
brew install tldr            # man simplificado
```

---

> **Checklist al cerrar la sesión (5 min):**
> - Kernel y distro identificados.
> - Gestor de paquetes utilizado al menos una vez.
> - Shell reconocido y comandos básicos practicados.
> - Creación y gestión de usuarios documentada para ejercicios posteriores.
> - Si usas macOS/zsh, configuración básica establecida.