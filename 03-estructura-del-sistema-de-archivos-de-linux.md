# 3. Estructura del sistema de archivos de Linux

## Índice

- [Objetivos](#objetivos)
- [Antes de empezar](#antes-de-empezar)
- [3.1 Tipos de archivo](#31-tipos-de-archivo)
- [3.2 Enlaces](#32-enlaces)
- [3.3 Rutas o paths](#33-rutas-o-paths)
- [3.4 Jerarquía principal](#34-jerarquía-principal)
- [3.5 Acceso a sistemas de archivos](#35-acceso-a-sistemas-de-archivos)
- [3.6 Permisos](#36-permisos)
- [Práctica guiada resuelta](#práctica-guiada-resuelta)
- [Errores frecuentes](#errores-frecuentes)
- [Reto 3](#reto-3--directorio-compartido)

## Objetivos

- Reconocer tipos de archivos y rutas.
- Navegar la jerarquía principal de Linux.
- Crear enlaces y explicar su diferencia.
- inspeccionar montajes sin modificar discos.
- aplicar permisos y propietarios de forma consciente.

## Antes de empezar

Abre la terminal en la raíz del curso —la carpeta que contiene `README.md`— y crea el espacio de trabajo. La ruta depende de dónde clonaste el repositorio; usa la navegación de la Clase 1, no una ruta copiada de otro equipo:

```bash
pwd
ls README.md
mkdir -p laboratorio/enlaces
```

En los ejemplos usaremos estos nombres concretos:

| Nombre | Qué representa |
|---|---|
| `config.ini` | archivo original |
| `config-duro.ini` | enlace duro al original |
| `config-actual.ini` | enlace simbólico al original |
| `deploy.sh` | archivo para practicar permisos |

> **Antes de ejecutar.** `laboratorio/enlaces` es una carpeta de práctica de Clase 1. Puedes crearla con `mkdir -p` sin afectar `data/` ni otros ejercicios. Antes de copiar, mover o borrar, confirma la ruta con `pwd` y `ls`.

## 3.1 Tipos de archivo

> **Situación real.** Un nombre terminado en `.conf` o `.log` ayuda a una persona, pero Linux decide cómo tratar un objeto por su tipo y permisos. Antes de modificar un archivo recibido, confirma qué es realmente.

El primer carácter de `ls -l` indica el tipo:

| Carácter | Tipo | Ejemplo |
|---|---|---|
| `-` | archivo regular | texto, CSV, binario |
| `d` | directorio | `/home` |
| `l` | enlace simbólico | acceso alternativo |
| `b`/`c` | dispositivo de bloque/carácter | discos, terminales |
| `s` | socket | comunicación local |
| `p` | pipe con nombre | comunicación entre procesos |

```bash
file /etc/passwd /bin/ls /dev/null
ls -ld /etc/passwd /tmp /dev/null
```

Las opciones usadas:

- `file <rutas>`: inspecciona contenido y metadatos para estimar el tipo.
- `ls -l`: `-l` muestra permisos, dueño, grupo y tamaño.
- `ls -d`: `-d` describe el directorio indicado, en lugar de listar su contenido.

Salida representativa:

```text
/etc/passwd: ASCII text
/bin/ls: ELF 64-bit LSB pie executable
/dev/null: character special
drwxrwxrwt ... /tmp
```

`file` inspecciona el contenido o metadatos; la extensión no decide el tipo en Linux.

## 3.2 Enlaces

> **Situación real.** Un servicio puede consultar siempre `config-actual`, aunque la configuración real cambie de versión. Un enlace evita copiar el archivo y permite conservar un nombre estable.

Un enlace **no es una segunda copia**. Es otra forma de llegar al mismo contenido, pero hay dos mecanismos que se comportan de forma distinta.

| Tipo | Modelo mental | Qué ocurre si el nombre original desaparece | Límite importante |
|---|---|---|---|
| Enlace duro | Dos nombres apuntan al mismo inode y a los mismos datos. | El otro nombre sigue funcionando. | Sólo vive en el mismo sistema de archivos; normalmente no se crea para directorios. |
| Enlace simbólico | Un archivo pequeño guarda la ruta de otro archivo. Es parecido a un acceso directo. | Queda roto si esa ruta deja de existir. | Puede apuntar a directorios y cruzar sistemas de archivos. |

### Modelo mental: nombre, inode y contenido

Un directorio guarda **nombres**. Cada nombre de archivo apunta a un **inode**, la ficha que identifica los datos y sus metadatos en el sistema de archivos. Por eso dos enlaces duros muestran el mismo inode: son dos nombres para los mismos datos. Un enlace simbólico tiene su propio inode y guarda una ruta hacia otro nombre.

```text
config.ini ────────┐
config-duro.ini ───┼──► inode 12345 ───► contenido: version=1
                   │
config-actual.ini ─┴──► guarda la ruta "config.ini"
```

No confundas un enlace duro con un respaldo: ambos nombres comparten los mismos datos. Si se modifica el contenido desde uno, cambia para el otro.

Sintaxis general:

```bash
ln <archivo_existente> <nuevo_enlace_duro>
ln -s <ruta_objetivo> <nuevo_enlace_simbolico>
```

### Ejemplo guiado

Trabaja en una carpeta propia para no mezclar este ejemplo con prácticas anteriores. Si ya existe `laboratorio/enlaces/demostracion/`, no repitas la creación de enlaces sobre los mismos nombres: continúa en la comprobación o crea otra carpeta de práctica.

```bash
mkdir -p laboratorio/enlaces/demostracion
touch laboratorio/enlaces/demostracion/config.ini
```

Abre `config.ini` con Text Editor y escribe `version=1`. Así podrás comprobar que los tres nombres llevan al mismo contenido sin introducir redirecciones en esta clase.

```bash
ln laboratorio/enlaces/demostracion/config.ini laboratorio/enlaces/demostracion/config-duro.ini
ln -s config.ini laboratorio/enlaces/demostracion/config-actual.ini
ls -li laboratorio/enlaces/demostracion
```

Las opciones usadas:

- `mkdir -p <ruta>`: crea la carpeta de práctica sin fallar si ya existe.
- `touch <archivo>`: crea el archivo vacío si falta; no borra contenido existente.
- `ln <origen> <destino>`: crea un enlace duro al mismo inode.
- `ln -s <objetivo> <enlace>`: `-s` crea un enlace simbólico que guarda una ruta.
- `ls -l`: muestra tipo, permisos y el destino de un enlace simbólico; `ls -i` agrega el inode.

Salida representativa:

```text
12345 -rw-r--r-- ... config-duro.ini
12345 -rw-r--r-- ... config.ini
12346 lrwxrwxrwx ... config-actual.ini -> config.ini
```

Identifica dos cosas: `config.ini` y `config-duro.ini` comparten `12345`, mientras que `config-actual.ini` empieza con `l` y muestra `-> config.ini`. Los números cambiarán en cada equipo; lo importante es qué nombres comparten número.

### Comprueba qué se rompe y qué permanece

Abre `config-duro.ini` y `config-actual.ini` con Text Editor: ambos llevan al mismo contenido. Después, sólo dentro de `laboratorio/enlaces/demostracion/`, renombra el archivo original y vuelve a listar:

```bash
mv laboratorio/enlaces/demostracion/config.ini laboratorio/enlaces/demostracion/config-v1.ini
ls -li laboratorio/enlaces/demostracion
```

El enlace duro sigue dando acceso a los datos, porque todavía apunta al inode `12345`. El enlace simbólico queda roto porque aún guarda la ruta `config.ini`. Para repararlo, elimina **sólo el enlace simbólico de práctica** y créalo con la nueva ruta:

```bash
rm laboratorio/enlaces/demostracion/config-actual.ini
ln -s config-v1.ini laboratorio/enlaces/demostracion/config-actual.ini
ls -li laboratorio/enlaces/demostracion
```

> **Cuidado.** Ejecuta el `rm` anterior sólo si la ruta completa es `laboratorio/enlaces/demostracion/config-actual.ini`. Nunca practiques este comportamiento con archivos de `/etc`, proyectos reales ni directorios del sistema.

## 3.3 Rutas o paths

> **Situación real.** La mayoría de los errores de copia, permisos o borrado empiezan con una ruta mal entendida. Antes de operar, debes saber dónde estás y cómo se interpreta el destino.

- Absoluta: comienza en `/`, por ejemplo `/var/log`.
- Relativa: comienza en el directorio actual, por ejemplo `../data`.
- `.`: directorio actual.
- `..`: directorio padre.
- `~`: home del usuario.

```bash
pwd
realpath laboratorio/enlaces/config.ini
basename /var/log/syslog
dirname /var/log/syslog
```

Las piezas que debes reconocer:

- `pwd`: muestra la ruta actual.
- `realpath <ruta>`: resuelve una ruta a su forma absoluta.
- `basename <ruta>`: devuelve sólo el último nombre.
- `dirname <ruta>`: devuelve el directorio padre.

## 3.4 Jerarquía principal

> **Situación real.** Un operador no busca una configuración de servicio en cualquier carpeta: sabe que `/etc` suele guardar configuración, `/var` datos que cambian y `/home` archivos de usuarios. La jerarquía acelera el diagnóstico.

| Ruta | Propósito práctico |
|---|---|
| `/home` | datos y configuración de usuarios |
| `/etc` | configuración del sistema y servicios |
| `/var` | datos variables, cachés y logs |
| `/tmp` | temporales; no asumir persistencia |
| `/usr` | programas, bibliotecas y datos compartidos |
| `/dev` | dispositivos |
| `/proc` | vista del kernel y procesos |
| `/run` | estado desde el arranque |

```bash
ls -lah /
head -n 5 /proc/meminfo
```

Las opciones usadas:

- `ls -l`: muestra detalles; `-a` incluye nombres ocultos; `-h` hace legibles tamaños.
- `head -n 5 <archivo>`: `-n 5` limita la salida a cinco líneas.

Salida representativa:

```text
drwxr-xr-x ... home
drwxr-xr-x ... etc
drwxr-xr-x ... var
MemTotal:       ... kB
MemAvailable:   ... kB
```

## 3.5 Acceso a sistemas de archivos

> **Situación real.** En soporte o DevOps alguien puede decir “el disco `/dev/nvme0n1p1` está lleno”, mientras que una aplicación sólo conoce rutas como `/var/log` o `/home`. Un montaje es la relación entre ambos mundos: conecta un dispositivo o sistema de archivos con una ruta dentro del único árbol de Linux.

### Antes de continuar

Este apartado pertenece a la Clase 2. Trabaja desde la raíz del curso —la carpeta que contiene `README.md`— aunque conserves carpetas de la Clase 1 en `laboratorio/`. La ruta depende de dónde clonaste el repositorio; usa la navegación de la Clase 1 para llegar a ella y confirma:

```bash
pwd
ls README.md
```

No necesitas crear discos ni particiones para este ejercicio. Los comandos consultan el estado actual del equipo. Si `laboratorio/` no existe, podrás crearlo más adelante con `mkdir -p laboratorio`; no recrees a mano archivos versionados de `data/`.

### Modelo mental

Piensa en un montaje como una puerta: el **origen** es el dispositivo o sistema de archivos, el **destino** es la carpeta por la que lo usas y el **tipo** indica cómo organiza sus datos. No trabajes con letras de unidad como en otros sistemas; pregunta siempre “¿en qué ruta está montado?”.

En este curso se inspeccionan montajes; no se formatean discos ni se modifican particiones.

### Sintaxis y ejemplo guiado

```text
lsblk -f                 # dispositivos, tipo y punto de montaje
findmnt <ruta>           # qué origen está montado en una ruta
df -hT <ruta>            # capacidad del sistema de archivos de esa ruta
```

```bash
lsblk -f
findmnt /
df -hT /
```

Salida representativa:

```text
TARGET SOURCE    FSTYPE OPTIONS
/      /dev/...  ext4   rw,relatime
```

Lee la salida en este orden:

1. `lsblk -f` muestra discos y particiones. Busca las columnas `FSTYPE` y `MOUNTPOINTS`; no cambies nada desde esa pantalla.
2. `findmnt /` responde qué está montado exactamente en la raíz `/`.
3. `df -hT /` responde cuánto espacio queda para las rutas que viven bajo esa raíz.

> **Comprueba.** Si una aplicación guarda logs en `/var/log`, prueba `findmnt /var/log` y `df -hT /var/log`. Puede pertenecer al mismo montaje que `/` o a uno independiente; la salida, no una suposición, te da la respuesta.

- `lsblk -f`: dispositivos, sistema de archivos, etiquetas y puntos de montaje.
- `findmnt`: relación entre destino y origen.
- `df -hT`: espacio disponible y tipo; `-h` usa unidades legibles y `-T` agrega el tipo.
- ext4 es común en Ubuntu; XFS y Btrfs ofrecen decisiones diferentes, pero el usuario sigue trabajando mediante rutas.

> **Cuidado.** Comandos como `mkfs`, `fdisk`, `parted` o `mount` pueden cambiar almacenamiento. No son parte de esta práctica. Primero identifica origen, destino y consecuencia antes de ejecutar una operación sobre discos.

## 3.6 Permisos

> **Situación real.** Un archivo de configuración no debe ejecutarse y un script no debe ser modificable por cualquiera. Los permisos expresan esa intención; `777` no es una solución universal.

```text
-rwxr-x--- 1 alumno devops 1200 jul 4 10:00 deploy.sh
│└┬┘└┬┘└┬┘   dueño  grupo
│ │  │  └─ otros: ---
│ │  └──── grupo: r-x
│ └─────── dueño: rwx
└───────── archivo regular
```

| Permiso | Archivo | Directorio | Valor |
|---|---|---|---:|
| `r` | leer contenido | listar nombres | 4 |
| `w` | modificar | crear/eliminar entradas | 2 |
| `x` | ejecutar | atravesar/acceder | 1 |

```bash
touch laboratorio/enlaces/deploy.sh
chmod u=rwx,g=rx,o= laboratorio/enlaces/deploy.sh
chmod 750 laboratorio/enlaces/deploy.sh
ls -l laboratorio/enlaces/deploy.sh
```

Las opciones y modos usados:

- `chmod u=rwx,g=rx,o=`: asigna permisos simbólicos para dueño, grupo y otros.
- `chmod 750`: forma octal de `rwxr-x---`.
- `ls -l`: permite comprobar el modo antes y después.

`chown` y `chgrp` cambian dueño o grupo y se usan sólo cuando el responsable de la ruta lo requiere. Los practicaremos con una VM autorizada; no copies nombres de usuario de otro equipo.

Salida representativa:

```text
-rwxr-x--- ... usuario grupo ... laboratorio/enlaces/deploy.sh
```

- `chmod`: cambia bits de permiso.
- `chown usuario:grupo`: cambia dueño y grupo cuando existe una necesidad autorizada.
- `chgrp`: cambia sólo el grupo.
- `750` equivale a `rwxr-x---`.

## Práctica guiada resuelta

La práctica crea este árbol, por lo que no necesitas preparar los archivos a mano:

```text
laboratorio/proyecto/
├── bin/status.sh
├── config/app.env
└── logs/
```

```bash
mkdir -p laboratorio/proyecto/{config,logs,bin}
touch laboratorio/proyecto/config/app.env
touch laboratorio/proyecto/bin/status.sh
chmod 640 laboratorio/proyecto/config/app.env
chmod 750 laboratorio/proyecto/bin/status.sh
ln -s ../config/app.env laboratorio/proyecto/bin/config-actual
ls -l laboratorio/proyecto/config laboratorio/proyecto/bin
```

Abre `status.sh` con Text Editor y escribe `echo "servicio listo"`. Guarda antes de intentar ejecutarlo. Esta primera clase evita redirecciones; en Clase 3 aprenderás a crear ese contenido desde terminal.

Salida principal:

```text
-rwxr-x--- ... status.sh
lrwxrwxrwx ... config-actual -> ../config/app.env
-rw-r----- ... app.env
```

El enlace muestra `rwx` por sí mismo; el acceso efectivo depende del objetivo y de los directorios de la ruta.

Para ejecutar el script después de guardarlo, usa `laboratorio/proyecto/bin/status.sh`. Si ves `Permission denied`, confirma primero `pwd` y luego ejecuta `ls -l laboratorio/proyecto/bin/status.sh`.

## Errores frecuentes

- Aplicar `chmod -R 777` para ocultar un problema.
- Confundir espacio de `df` con tamaño de archivos calculado por `du`.
- Crear un enlace simbólico relativo desde el directorio equivocado.
- Ejecutar `chown` o `rm` sin comprobar la ruta.

## Reto 3 — Directorio compartido

[Ver respuesta](instructor/soluciones.md#respuesta-reto-3)

Crea `laboratorio/compartido` para un equipo: dueño con control total, grupo con lectura/escritura/acceso y otros sin acceso. Dentro crea `app.env` como configuración no ejecutable, `check.sh` como script ejecutable y `check-actual` como enlace simbólico al script.

Usa `touch` para crear los dos archivos y Text Editor para escribir `echo "servicio listo"` dentro de `check.sh`. No uses redirecciones todavía; se explican en la Clase 3.

### Criterios de comprobación

- Los modos reflejan necesidades distintas para directorio, configuración y script.
- El script se ejecuta y la configuración no.
- `readlink` permite identificar el objetivo del enlace.

## Checklist

- [ ] Distingo tipo de archivo, extensión e inode.
- [ ] Uso rutas absolutas y relativas.
- [ ] Puedo explicar enlaces duros y simbólicos.
- [ ] Inspecciono montajes sin modificar discos.
- [ ] Interpreto y cambio permisos simbólicos y octales.
