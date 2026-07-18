# 1. Introducción a Linux

## Índice

- [Objetivos](#objetivos)
- [Antes de empezar](#antes-de-empezar)
- [Ruta práctica de la Clase 1](#ruta-práctica-de-la-clase-1)
- [1.1 ¿Qué es Linux?](#11-qué-es-linux)
- [1.2 ¿Qué son las distribuciones?](#12-qué-son-las-distribuciones)
- [1.3 Entorno de trabajo: shell y entorno gráfico](#13-entorno-de-trabajo-shell-y-entorno-gráfico)
- [1.4 Usuarios y grupos](#14-usuarios-y-grupos)
- [Práctica guiada resuelta](#práctica-guiada-resuelta)
- [Errores frecuentes](#errores-frecuentes)
- [Reto 1](#reto-1--inventario-reproducible)

## Objetivos

- Distinguir kernel, distribución, shell, terminal y escritorio.
- Identificar la distribución y el kernel de una máquina.
- Consultar ayuda e instalar paquetes en Ubuntu.
- Trabajar con usuarios, grupos y privilegios mediante `sudo`.

## Antes de empezar

Abre una terminal y sitúate en la raíz del curso:

```bash
cd ~/linux-desde-cero
pwd
ls README.md
```

Si `ls README.md` indica que no encuentra el archivo, revisa dónde clonaste el repositorio antes de continuar. En este capítulo instalarás o crearás temporalmente:

- el paquete `tree`, para visualizar directorios;
- un grupo llamado `devops-lab`;
- un usuario de práctica llamado `alumno`;
- la carpeta `~/curso-linux/evidencias` para guardar resultados.

> **Antes de ejecutar.** Esta es la primera sesión. `~/curso-linux` y `laboratorio/` son espacios de práctica; puedes crearlos. No crees archivos vacíos dentro de `data/` para ocultar un error de ruta.

## Ruta práctica de la Clase 1

1. Identifica qué sistema y usuario estás usando.
2. Comprende qué cambia `sudo` y qué cambia un gestor de paquetes.
3. Aprende a recorrer y reconocer rutas antes de modificarlas.
4. Crea una estructura segura, copia y renombra archivos.
5. Comprueba tipo, enlace, dueño y permisos antes de corregirlos.

## 1.1 ¿Qué es Linux?

> **Situación real.** Una alerta puede mencionar “Linux”, “Ubuntu” o “kernel”. Para operar un servidor con seguridad debes saber si hablan del núcleo que controla recursos o de la distribución que instala y configura herramientas.

Linux es el **kernel**: administra CPU, memoria, dispositivos, procesos y sistemas de archivos. Una distribución combina ese kernel con herramientas, bibliotecas, un gestor de paquetes y decisiones de configuración.

```text
hardware → kernel Linux → herramientas del sistema → aplicaciones → usuario
```

### Comprobar el sistema

```bash
uname -r
cat /etc/os-release
```

Las opciones usadas:

- `uname -r`: `-r` pide el *release* o versión del kernel en ejecución.
- `cat /etc/os-release`: no tiene bandera; lee el archivo estándar que describe la distribución.

Salida representativa:

```text
6.8.0-xx-generic
PRETTY_NAME="Ubuntu 24.04.x LTS"
ID=ubuntu
VERSION_ID="24.04"
```

- `uname -r`: muestra la versión del kernel en ejecución.
- `/etc/os-release`: describe la distribución, no el kernel.
- `-r`: solicita el *kernel release*.

> **Comprueba.** La primera salida identifica el kernel; las líneas `PRETTY_NAME` e `ID` identifican la distribución. No tienen por qué usar el mismo número de versión.

## 1.2 ¿Qué son las distribuciones?

> **Situación real.** Un runbook puede decir `apt install`, pero otro servidor usar `dnf`. El objetivo es reconocer el flujo consultar → revisar → instalar, no aprender una lista aislada de comandos.

Las distribuciones comparten el kernel, pero cambian herramientas, versiones, soporte y paquetes.

| Familia | Ejemplos | Gestor habitual |
|---|---|---|
| Debian | Ubuntu, Debian | `apt`/`dpkg` |
| RHEL | Red Hat Enterprise Linux, Fedora, Rocky Linux | `dnf`/`rpm` |
| Arch | Arch Linux, Manjaro | `pacman` |

El laboratorio usa Ubuntu. Aprender los conceptos y consultar ayuda es más importante que memorizar tres gestores.

### Administración esencial de paquetes

```bash
sudo apt update
apt search tree
apt show tree
sudo apt install tree
tree --version
```

Las opciones y subcomandos usados:

- `sudo`: ejecuta sólo el comando que sigue con privilegios administrativos.
- `apt update`: actualiza el catálogo local de paquetes; no actualiza programas instalados.
- `apt search <texto>`: busca por nombre o descripción.
- `apt show <paquete>`: muestra versión, tamaño, dependencias y descripción.
- `apt install <paquete>`: instala el paquete indicado después de revisarlo.
- `tree --version`: `--version` confirma qué versión se instaló.

- `apt update`: actualiza el índice local; no actualiza todavía los programas.
- `search`: busca por nombre y descripción.
- `show`: enseña versión, tamaño y dependencias.
- `install`: instala el paquete solicitado.
- `sudo`: ejecuta sólo ese comando con privilegios administrativos.

En este capítulo **no eliminamos `tree` todavía**, porque se utiliza en la práctica final. Cuando termines y sólo si deseas retirarlo, la sintaxis es:

```bash
sudo apt remove tree
```

En una distribución con DNF, el flujo equivalente usa `dnf search`, `dnf info`, `dnf install` y `dnf remove`.

### Ayuda antes de ejecutar

```bash
man uname
uname --help
type uname
command -v uname
```

- `man`: manual completo; sal con `q`.
- `--help`: resumen rápido de opciones.
- `type`: indica si el nombre es alias, builtin o ejecutable.
- `command -v`: muestra cómo lo resolverá el shell.

> **Cuidado.** `apt upgrade` cambia paquetes ya instalados y no forma parte de esta práctica. Primero aprende a consultar qué haría una acción administrativa.

## 1.3 Entorno de trabajo: shell y entorno gráfico

> **Situación real.** La terminal es la ventana de texto; Bash es el intérprete que entiende lo que escribes. En una EC2 puedes tener shell sin escritorio, y en GNOME/KDE puedes abrir distintas terminales que usen el mismo shell.

- **Terminal:** interfaz que recibe texto y muestra resultados.
- **Shell:** programa que interpreta comandos; Bash es el principal del curso.
- **Escritorio:** entorno gráfico como GNOME o KDE Plasma.
- **Servidor gráfico/compositor:** conecta aplicaciones gráficas, entrada y pantalla.

```bash
echo "$SHELL"
ps -p "$$" -o comm=
tty
```

Salida representativa:

```text
/bin/bash
bash
/dev/pts/0
```

- `$SHELL` contiene el shell configurado para el usuario.
- `$$` es el PID del shell actual.
- `tty` identifica la terminal asociada a la sesión.

Las piezas que debes reconocer:

- `$SHELL`: variable con el shell configurado para tu usuario.
- `$$`: identificador del shell actual; lo usaremos sólo para observar, no para terminar procesos.
- `ps -p <PID> -o comm=`: `-p` selecciona un proceso y `-o` elige la columna mostrada.

## 1.4 Usuarios y grupos

> **Situación real.** Cuando un archivo rechaza acceso, la pregunta no es “¿cómo obtengo permisos totales?”, sino “¿con qué usuario trabajo, a qué grupos pertenezco y qué autorización requiere la tarea?”.

Linux separa identidades y permisos mediante UID y GID.

```bash
whoami
id
groups
getent passwd "$USER"
```

Salida representativa:

```text
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),27(sudo)
```

- `uid`: identidad numérica del usuario.
- `gid`: grupo principal.
- `groups`: grupos adicionales; `sudo` suele conceder administración en Ubuntu.

Las opciones y consultas usadas:

- `whoami`: muestra el nombre efectivo del usuario actual.
- `id`: muestra UID, GID y grupos en una sola salida.
- `groups`: lista grupos por nombre.
- `getent passwd "$USER"`: consulta el registro de tu usuario; `passwd` es la base de cuentas y `$USER` se sustituye por tu nombre de sesión.

### ¿Qué hace `getent`?

`getent` significa **get entries**: obtener registros de las bases de datos que Linux tiene configuradas en `/etc/nsswitch.conf`.

Esto es importante porque los usuarios y grupos no siempre provienen únicamente de `/etc/passwd` y `/etc/group`. En una organización también pueden venir de LDAP, Active Directory u otro servicio de identidades. `getent` consulta esas fuentes mediante la configuración del sistema y presenta una salida uniforme.

Sintaxis general:

```bash
getent <base_de_datos> [clave]
```

Ejemplos resueltos:

```bash
getent passwd "$USER"
getent passwd root
getent group sudo
```

- `passwd`: base de datos de cuentas de usuario.
- `group`: base de datos de grupos.
- `"$USER"`: se sustituye automáticamente por tu usuario actual.
- `root` y `sudo`: claves concretas que queremos buscar.

Una salida de usuario tiene siete campos separados por `:`:

```text
ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash
│      │ │    │    │      │            └─ shell de inicio
│      │ │    │    │      └─ directorio personal
│      │ │    │    └─ descripción de la cuenta
│      │ │    └─ GID del grupo principal
│      │ └─ UID del usuario
│      └─ la contraseña/hash no se guarda aquí
└─ nombre de usuario
```

La `x` no es la contraseña. Indica que la información protegida se guarda en `/etc/shadow`, que sólo puede leer `root`.

Para esta primera clase basta ejecutar `getent passwd alumno` y leer la salida. Las condiciones, redirecciones y estados de salida se automatizan en la Clase 3.

### Crear un usuario de laboratorio

> **Cuidado.** Crear usuarios y grupos cambia el equipo. La práctica se realiza sólo en una VM o instancia de laboratorio autorizada; si trabajas en un equipo corporativo, observa la demostración y no copies el bloque.

Vamos a crear dos objetos diferentes:

| Objeto | Nombre usado | Propósito |
|---|---|---|
| Grupo | `devops-lab` | Representa a un equipo que comparte permisos. |
| Usuario | `alumno` | Cuenta temporal con la que practicaremos administración. |

El nombre del usuario es `alumno`; aparece como último argumento en comandos como `useradd`, `passwd`, `id` y `usermod`.

### Sintaxis general

```bash
sudo groupadd <nombre_grupo>
sudo useradd -U -m -s /bin/bash -G <nombre_grupo> <nombre_usuario>
sudo passwd <nombre_usuario>
sudo usermod -aG sudo <nombre_usuario>
id <nombre_usuario>
```

- `<nombre_grupo>`: grupo adicional al que pertenecerá la cuenta.
- `<nombre_usuario>`: nombre de la cuenta que quieres crear.
- Los marcadores `<...>` se sustituyen; no se escriben literalmente.

### Ejemplo resuelto para copiar

```bash
sudo groupadd devops-lab
sudo useradd -U -m -s /bin/bash -G devops-lab alumno
sudo passwd alumno
sudo usermod -aG sudo alumno
id alumno
```

Qué ocurre en cada línea:

1. `groupadd devops-lab` crea el grupo `devops-lab`.
2. `useradd ... alumno` crea el usuario `alumno`.
3. `passwd alumno` solicita dos veces una contraseña para `alumno`; mientras escribes no se muestran caracteres, pero el teclado sí está funcionando.
4. `usermod -aG sudo alumno` agrega `alumno` al grupo administrativo `sudo`.
5. `id alumno` confirma UID, grupo principal y grupos secundarios después del cambio.

- `-m`: crea el directorio personal.
- `-U`: crea un grupo principal con el mismo nombre del usuario.
- `-s`: define el shell de inicio.
- `-G`: asigna grupos secundarios.
- `-aG`: **añade** grupos; omitir `-a` puede reemplazar membresías existentes.

Comprueba que la cuenta y su home existen:

```bash
getent passwd alumno
id alumno
sudo ls -ld /home/alumno
```

Salida representativa:

```text
alumno:x:1001:1001::/home/alumno:/bin/bash
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno),27(sudo),1002(devops-lab)
drwxr-x--- ... alumno alumno ... /home/alumno
```

Los números UID/GID pueden ser distintos. Lo importante es ver `alumno`, `/home/alumno`, `/bin/bash`, `sudo` y `devops-lab`. La nueva membresía de grupo se aplica al iniciar una sesión nueva; no necesitas cambiar de usuario para continuar el capítulo.

Limpieza, después de la práctica:

```bash
sudo userdel -r alumno
sudo groupdel devops-lab
```

`userdel -r alumno` elimina la cuenta **y `/home/alumno`**. Ejecútalo únicamente cuando ya no necesites los archivos de ese usuario. Después se elimina el grupo temporal `devops-lab`.

## Práctica guiada resuelta

> **Situación real.** Antes de administrar un equipo necesitas dejar una evidencia que otra persona pueda leer. En esta primera clase la evidencia se guarda con Text Editor; en la Clase 3 aprenderás a generarla automáticamente desde la terminal.

Objetivo: inspeccionar el host, instalar una herramienta y organizar una evidencia.

Esta práctica se ejecuta con tu usuario habitual, no con la cuenta `alumno`. Creará `~/curso-linux/evidencias/` y después mostrará la estructura con `tree`.

```bash
mkdir -p ~/curso-linux/evidencias
sudo apt update
sudo apt install -y tree
tree ~/curso-linux
```

Las opciones usadas:

- `mkdir -p`: crea las carpetas padre faltantes y no falla si ya existen.
- `apt install -y`: `-y` confirma automáticamente; úsalo sólo después de revisar el paquete con `apt show`.
- `tree <ruta>`: muestra una estructura de directorios legible.

Ahora abre Text Editor, crea `~/curso-linux/evidencias/sistema.txt` y pega las salidas de `whoami`, `uname -r`, `cat /etc/os-release` e `id`. Los valores siguen viniendo de comandos; no los inventes ni copies valores de otro equipo.

Salida representativa:

```text
/home/ubuntu/curso-linux
└── evidencias
    └── sistema.txt
```

> **Comprueba.** En Files o con `ls -l ~/curso-linux/evidencias`, verifica que existe `sistema.txt`. En `tree ~/curso-linux` debes reconocer la carpeta `evidencias` y el archivo que acabas de guardar.

## Errores frecuentes

- Confundir Ubuntu con el kernel Linux.
- Trabajar siempre como `root` en vez de usar `sudo` por comando.
- Ejecutar `apt upgrade` sin revisar qué cambiará.
- Usar `usermod -G` sin `-a` y perder grupos secundarios.

## Reto 1 — Inventario reproducible

[Ver respuesta](instructor/soluciones.md#respuesta-reto-1)

Crea `~/curso-linux/evidencias/inventario.txt` desde Text Editor con hostname, distribución, kernel, usuario, grupos y ruta del ejecutable `bash`. Obtén cada valor ejecutando el comando correspondiente; no copies valores de otro equipo. La Clase 3 automatizará este mismo inventario desde terminal.

### Criterios de comprobación

- El archivo contiene seis datos con etiquetas legibles.
- Los valores provienen de comandos.
- El comando puede ejecutarse nuevamente sin producir errores.

## Checklist

- [ ] Distingo kernel y distribución.
- [ ] Distingo terminal, shell y escritorio.
- [ ] Sé consultar `man` y `--help`.
- [ ] Puedo buscar e instalar un paquete.
- [ ] Puedo interpretar UID, GID y grupos.
