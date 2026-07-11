# 1. Introducción a Linux

## Objetivos

- Distinguir kernel, distribución, shell, terminal y escritorio.
- Identificar la distribución y el kernel de una máquina.
- Consultar ayuda e instalar paquetes en Ubuntu.
- Trabajar con usuarios, grupos y privilegios mediante `sudo`.

## Antes de empezar

Abre una terminal y sitúate en la raíz del curso:

```bash
cd ~/linux-desde-cero
test -f README.md && echo "Directorio correcto"
```

Si el mensaje no aparece, revisa dónde clonaste el repositorio antes de continuar. En este capítulo instalarás o crearás temporalmente:

- el paquete `tree`, para visualizar directorios;
- un grupo llamado `devops-lab`;
- un usuario de práctica llamado `alumno`;
- la carpeta `~/curso-linux/evidencias` para guardar resultados.

## 1.1 ¿Qué es Linux?

Linux es el **kernel**: administra CPU, memoria, dispositivos, procesos y sistemas de archivos. Una distribución combina ese kernel con herramientas, bibliotecas, un gestor de paquetes y decisiones de configuración.

```text
hardware → kernel Linux → herramientas del sistema → aplicaciones → usuario
```

### Comprobar el sistema

```bash
uname -r
cat /etc/os-release
```

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

## 1.2 ¿Qué son las distribuciones?

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

## 1.3 Entorno de trabajo: shell y entorno gráfico

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

## 1.4 Usuarios y grupos

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

Para comprobar si una cuenta existe sin imprimir información innecesaria:

```bash
if getent passwd alumno > /dev/null; then
  echo "El usuario alumno existe"
else
  echo "El usuario alumno no existe"
fi
```

`getent` devuelve estado `0` cuando encuentra el registro y un estado distinto de cero cuando no lo encuentra. Por eso puede utilizarse directamente como condición de un `if`.

### Crear un usuario de laboratorio

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

Objetivo: inspeccionar el host e instalar una herramienta.

Esta práctica se ejecuta con tu usuario habitual, no con la cuenta `alumno`. Creará `~/curso-linux/evidencias/sistema.txt` y después mostrará la estructura con `tree`.

```bash
mkdir -p ~/curso-linux/evidencias
{
  echo "Usuario: $(whoami)"
  echo "Kernel: $(uname -r)"
  grep '^PRETTY_NAME=' /etc/os-release
  id
} | tee ~/curso-linux/evidencias/sistema.txt

sudo apt update
sudo apt install -y tree
tree ~/curso-linux
```

Salida representativa:

```text
/home/ubuntu/curso-linux
└── evidencias
    └── sistema.txt
```

- `{ ...; }` agrupa comandos en el shell actual.
- `$(...)` sustituye un comando por su salida.
- `tee` muestra y guarda el reporte.
- `-y` confirma la instalación; úsalo sólo si ya revisaste el paquete.

Comprueba el resultado:

```bash
test -s ~/curso-linux/evidencias/sistema.txt \
  && echo "Evidencia creada correctamente"
```

## Errores frecuentes

- Confundir Ubuntu con el kernel Linux.
- Trabajar siempre como `root` en vez de usar `sudo` por comando.
- Ejecutar `apt upgrade` sin revisar qué cambiará.
- Usar `usermod -G` sin `-a` y perder grupos secundarios.

## Reto 1 — Inventario reproducible

[Ver respuesta](instructor/soluciones.md#respuesta-reto-1)

Crea `~/curso-linux/evidencias/inventario.txt` con hostname, distribución, kernel, usuario, grupos y ruta del ejecutable `bash`. No escribas esos valores a mano.

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
