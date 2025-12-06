# Temario de Linux

Repositorio de documentación del curso 'Linux desde Cero'. Cubre introducción a Linux, shell, GNOME, KDE, permisos, directorios y redes. Objetivos: uso básico como admin, asignación de permisos, configuración de GNOME y manipulación de directorios. Secundarios: redirecciones, tuberías y administración de paquetes.

## Tabla de Contenidos

### 1. [Introducción a Linux](01-introduccion-a-linux.md)
- 1.1 ¿Qué es Linux?
- 1.2 ¿Qué son las distribuciones?
- 1.3 Entorno de trabajo: EL SHELL Y X WINDOW
- 1.4 Usuarios y grupos

### 2. [Un Enfoque a Linux](02-un-enfoque-a-linux.md)
- 2.1 Entrada y salida del sistema

### 3. [Estructura del sistema de archivos de Linux](03-estructura-del-sistema-de-archivos-de-linux.md)
- 3.1 Archivos: tipos
- 3.2 Enlaces
- 3.3 El camino o path
- 3.4 Estructura del sistema de archivos de Linux
- 3.5 Acceso a los diferentes sistemas de archivos
- 3.6 Permisos

### 4. [X WINDOW](04-x-window.md)
- 4.1 X WINDOW

### 5. [GNOME](05-gnome.md)
- 5.1 Iniciación a GNOME
- 5.2 Aplicaciones auxiliares de GNOME
- 5.3 File manager
- 5.4 GNOME Search Tool
- 5.5 Color Xterm, GNOME Terminal y Regular Xterm
- 5.6 Multimedia
- 5.7 Configuración de GNOME

### 6. [KDE](06-kde.md)
- 6.1 Partes de la pantalla
- 6.2 Administración de archivos KFM
- 6.3 Navegar por la estructura de directorios y ver el contenido de los ficheros
- 6.4 Crear un nuevo directorio
- 6.5 Copiar, Borrar y Mover un documento o directorio
- 6.6 Enlaces KDE
- 6.7 Asociar un nuevo tipo de archivo
- 6.8 Propiedades de un fichero o directorio
- 6.9 Aplicaciones Auxiliares de KDE
- 6.10 konsole, kedit, kwrite, kdehelp, Kfind
- 6.11 Configuración de KDE
- 6.12 Editor de menús
- 6.13 KDE Control Center
- 6.14 Añadir aplicaciones al panel

### 7. [El Shell](07-el-shell.md)
- 7.1 Introducción
- 7.2 Algunos comandos sencillos de LINUX
- 7.3 Directorio personal
- 7.4 Listado del contenido de directorios: comando ls
- 7.5 Creación de subdirectorios. Comando mkdir
- 7.6 Borrado de subdirectorios. Comando rmdir
- 7.7 Cambio de directorio. Comando cd
- 7.8 Ruta actual. Comando pwd
- 7.9 Acceso a unidades de disco
- 7.10 Copia de ficheros. Comando cp
- 7.11 Traslado y cambio de nombre de ficheros. Comando mv
- 7.12 Enlaces a ficheros. Comando ln
- 7.13 Borrado de ficheros. Comando rm
- 7.14 Características de un fichero. Comando file
- 7.15 Cambio de modo de los ficheros comandos chmod, chown y chgrp
- 7.16 Espacio ocupado en el disco comandos DU y DF
- 7.17 Visualización sin formato de un fichero comando CAT y con formato comando PR
- 7.18 Visualización de ficheros pantalla a pantalla comandos MORE y LESS
- 7.19 Busqueda en ficheros comandos GREP, FGREP y EGREP
- 7.20 Comandos TAR y GZIP
- 7.21 Comandos de impresion lpr

### 8. [Redirecciones y tuberías](08-redirecciones-y-tuberias.md)
- 8.1 Redirecciones
- 8.2 Tuberías
- 8.3 Bifurcación o T (comando TEE)
- 8.4 Redirecciones de la salida de errores

### 9. [Ejecución de programas](09-ejecucion-de-programas.md)
- 9.1 Ejecución en el fondo &, KILL, NICE y NOHUP
- 9.2 Comando TIME
- 9.3 Comando TOP

### 10. [Programas de comandos](10-programas-de-comandos.md)
- 10.1 Introducción de comentarios
- 10.2 Variables del SHELL
- 10.3 Comando ECHO
- 10.4 Parámetros de los ficheros de comandos

### 11. [SCP Copias Remotas](11-scp-copias-remotas.md)
- 11.1 Compilado de programas en LINUX
- 11.2 Compilación y Linkado
- 11.3 Comando MAKE
- 11.4 Búsqueda avanzada en ficheros. Expresiones Regulares
- 11.5 Caracteres especiales
- 11.6 Expresiones regulares de un solo carácter
- 11.7 Expresiones regulares generales
- 11.8 Comandos utiles para trabajar en Red
- 11.9 Protocolos de Internet (IP)
- 11.10 Denominación simbólica de Sistemas de Internet
- 11.11 Comandos TELNET y FTP


## Distribución de Tiempo

El curso tiene una duración total de 20 horas, dividido en 4 sesiones de 5 horas cada sábado (de 9:00 am a 2:00 pm), con 30 minutos de receso de 11:00 am a 11:30 am por sesión. El enfoque es mínimo en teoría, máximo en práctica hands-on, ejercicios, instalaciones y revisión de ejercicios. Se incluye tiempo para revisiones de prerrequisitos (instalaciones de Docker, AWS, etc.) y prácticas en entornos virtuales.

### Sábado 1: Introducción y Estructura de Archivos (5 horas)
- **9:00 - 11:00:**
  - Revisión de prerrequisitos e instalaciones (Docker, AWS CLI, instancias EC2) - práctica hands-on
  - Tema 1: Introducción a Linux - mínima teoría, práctica: instalación de distro en Docker, usuarios y grupos
  - Tema 2: Un Enfoque a Linux - práctica: entrada/salida del sistema en contenedor
- **11:00 - 11:30:** Receso
- **11:30 - 2:00:**
  - Tema 3: Estructura del sistema de archivos - práctica: navegación, tipos de archivos, enlaces, paths, permisos (ejercicios hands-on)
  - Ejercicios y revisión: práctica de comandos básicos, resolución de problemas
  - Revisión general y Q&A

### Sábado 2: Entornos Gráficos (GNOME y KDE) (5 horas)
- **9:00 - 11:00:**
  - Tema 4: X WINDOW - mínima teoría, práctica: configuración básica en VM
  - Tema 5: GNOME - práctica: iniciación, aplicaciones auxiliares, file manager, terminales, multimedia, configuración (ejercicios hands-on)
- **11:00 - 11:30:** Receso
- **11:30 - 2:00:**
  - Tema 6: KDE - práctica: partes de pantalla, administración de archivos, navegación, creación/movimiento de directorios, enlaces, propiedades, aplicaciones, configuración (ejercicios hands-on)
  - Ejercicios y revisión: comparación GNOME vs KDE, personalización
  - Revisión general y Q&A

### Sábado 3: El Shell y Comandos Básicos (5 horas)
- **9:00 - 11:00:**
  - Repaso de navegación y permisos
  - Tema 7: El Shell - mínima teoría, práctica intensiva: comandos ls, mkdir, rmdir, cd, pwd, cp, mv, ln, rm, file, chmod/chown/chgrp, du/df, cat/pr, more/less, grep, tar/gzip, lpr (ejercicios hands-on por cada comando)
- **11:00 - 11:30:** Receso
- **11:30 - 2:00:**
  - Tema 8: Redirecciones y tuberías - práctica: redirecciones, tuberías, tee, errores (ejercicios)
  - Revisión de ejercicios y Q&A

### Sábado 4: Ejecución Avanzada y Redes (5 horas)
- **9:00 - 11:00:**
  - Tema 9: Ejecución de programas - práctica: ejecución en fondo (&), kill, nice, nohup, time, top (ejercicios)
  - Tema 10: Programas de comandos - práctica: scripts, variables, echo, parámetros (ejercicios de scripting básico)
- **11:00 - 11:30:** Receso
- **11:30 - 2:00:**
  - Tema 11: SCP Copias Remotas - práctica: compilación (make), expresiones regulares, comandos de red, scp (ejercicios en AWS EC2)
  - Ejercicios integrales y revisión
  - Revisión final, troubleshooting y Q&A

## Simular sistema con kernel Linux en macOS (Multipass)

Multipass permite crear VMs de Ubuntu ligeras en macOS para practicar Linux.

- Crear y arrancar una VM:
  - `multipass launch --name mi-linux`
  - `multipass start mi-linux`
  - `multipass list`
  - `multipass shell mi-linux`
  - Resultado esperado: `Listo: te deja dentro de la VM. Cuando termines, \`exit\` para volver a tu Mac.`

- Reset (reiniciar todas las VMs):
  - `multipass restart --all`

- Borrar la instancia y empezar limpio:
  - (Opcional) Apagar si está corriendo: `multipass stop mi-linux`
  - Borrar instancia (conserva la imagen): `multipass delete mi-linux`
  - Limpiar discos huérfanos: `multipass purge`
  - Crear una nueva: `multipass launch --name mi-linux`
  - Resultado esperado: `Listo: tendrás una VM nueva en blanco.`

Nota: si querías conservar algo, haz backup antes (`multipass mount` para copiar o `scp`/`rsync`).