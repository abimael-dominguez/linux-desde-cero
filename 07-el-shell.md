# 7. El shell

## Índice

- [Objetivos](#objetivos)
- [Antes de empezar](#antes-de-empezar)
- [7.1–7.3 Shell, comandos y directorio personal](#71-73-shell-comandos-y-directorio-personal)
- [7.4 Listar](#74-listar-ls)
- [7.5–7.8 Directorios y navegación](#75-78-directorios-y-navegación)
- [7.9 Unidades y montajes](#79-unidades-y-montajes)
- [7.10 Copiar](#710-copiar-cp)
- [7.11 Mover y renombrar](#711-mover-y-renombrar-mv)
- [7.12 Enlaces](#712-enlaces-ln)
- [7.13 Borrar](#713-borrar-rm)
- [7.14 Identificar](#714-identificar-file-y-stat)
- [7.15 Permisos y propiedad](#715-permisos-y-propiedad)
- [Ruta práctica de la Clase 2](#ruta-práctica-de-la-clase-2)
- [7.16 Espacio](#716-espacio-du-y-df)
- [7.17–7.18 Visualizar](#717-718-visualizar-cat-head-tail-less-y-pr)
- [7.19 Buscar](#719-buscar-grep-y-find)
- [7.20 Empaquetar y comprimir](#720-empaquetar-y-comprimir-targzip)
- [7.21 Impresión](#721-impresión-lpr)
- [Práctica guiada: respaldo de evidencia](#práctica-guiada-resuelta--respaldo-de-evidencia-de-un-incidente)
- [Errores frecuentes](#errores-frecuentes)
- [Reto 7](#reto-7--snapshot-de-evidencias)

## Objetivos

- Navegar y administrar archivos desde Bash.
- Consultar ayuda y verificar el efecto de cada comando.
- Buscar, medir, empaquetar y recuperar información.
- Aplicar opciones de seguridad antes de borrar o sobrescribir.

## Antes de empezar

Este capítulo forma una secuencia: cada apartado reutiliza archivos del anterior. Al iniciar la **Clase 1**, empieza desde la raíz del curso y prepara una copia limpia de los datos:

```bash
cd ~/linux-desde-cero
bash ejercicios-bash-scripting/preparar-lab.sh
mkdir -p laboratorio/shell/{entrada,salida,backup}
```

Trabajaremos con `modelo.txt` como archivo original, `backup-modelo.txt` como copia y `modelo-validado.txt` como nombre nuevo. No uses archivos personales para estas prácticas.

`preparar-lab.sh` elimina y recrea `laboratorio/`. Úsalo al iniciar la Clase 1 o cuando el instructor indique un reinicio deliberado. Si ya estás en la Clase 2 y quieres conservar evidencia previa, ve al apartado “Antes de continuar con la Clase 2” y no ejecutes este reinicio.

## 7.1–7.3 Shell, comandos y directorio personal

> **Situación real.** La terminal no es un lugar para memorizar hechizos: es una conversación con el sistema. El shell decide qué programa ejecuta y conserva tu contexto, por ejemplo la carpeta actual.

Bash interpreta palabras, expansiones, redirecciones y operadores. Un comando puede ser **builtin del shell** o un **ejecutable externo**:

| Tipo | Descripción | Ejemplos |
|------|-------------|---------|
| **Builtin** | Integrado en el propio shell; no existe como archivo en el sistema | `cd`, `echo`, `export`, `source` |
| **Alias** | Atajo definido en la sesión o en `.bashrc`; envuelve otro comando | `ls` → `ls --color=auto`, `grep` → `grep --color=auto` |
| **Función** | Función definida en el shell o en archivos de configuración | funciones personalizadas en `.bashrc` |
| **Externo** | Archivo binario en el sistema de archivos; el shell lo localiza vía `$PATH` | `ls`, `grep`, `awk`, `sed`, `find`, `cp`, `mv`, `rm`, `cat`, `git`, `python3` |

El shell resuelve en este orden: alias → función → builtin → externo.

**¿Por qué importa?** Los builtins son más rápidos (no crean un proceso nuevo) y pueden modificar el estado del shell actual. `cd`, por ejemplo, solo funciona como builtin: si fuera externo, cambiaría el directorio de un proceso hijo y el shell padre nunca lo notaría.

Usa `type` para identificar la naturaleza de cualquier comando:

```bash
type cd
type ls
type echo
```

La salida depende de tu configuración; ejemplos comunes:

```text
cd is a shell builtin
ls is aliased to `ls --color=auto'
echo is a shell builtin
```

Para saltar aliases y llegar al ejecutable real, usa `type -a` o `which`:

```bash
type -a ls     # alias → /usr/bin/ls → /bin/ls  (alias + externo)
type -a grep   # alias → /usr/bin/grep           (alias + externo)
type -a echo   # builtin → /usr/bin/echo         (builtin Y también externo)
type -a mkdir  # solo /usr/bin/mkdir             (puro externo, sin alias ni builtin)
type -a cd     # cd is a shell builtin           (solo builtin, sin archivo)

which ls       # /usr/bin/ls   (ignora el alias, devuelve el binario)
which grep     # /usr/bin/grep (ignora el alias, devuelve el binario)
which echo     # /usr/bin/echo (ignora el builtin, devuelve el binario externo)
which mkdir    # /usr/bin/mkdir (externo puro, sin alias ni builtin)
which cd       # (sin salida — cd es builtin, no tiene archivo ejecutable)
```

Las opciones usadas:

- `type -a <nombre>`: muestra todas las formas en que el shell puede resolver un nombre.
- `which <nombre>`: busca un ejecutable en `PATH`; úsalo como pista, no para sustituir a `type` al investigar aliases o builtins.

Directorio personal y navegación básica:

```bash
echo "$HOME"
cd
pwd
```

Salida representativa:

```text
/home/ubuntu
/home/ubuntu
```

## 7.4 Listar: `ls`

> **Situación real.** Antes de copiar, mover o borrar, lista la ruta exacta. `ls` responde qué hay y, con opciones, quién es dueño, cuánto mide y cuándo cambió.

```bash
ls -lah
ls -lt laboratorio
```

- `-l`: formato largo.
- `-a`: incluye nombres que comienzan con `.`.
- `-h`: tamaños legibles junto con `-l`.
- `-t`: ordena por modificación.

Salida representativa:

```text
drwxr-xr-x ... usuario grupo ... laboratorio
-rw-r--r-- ... usuario grupo ... archivo.txt
```

No analices `ls` en scripts complejos: nombres con espacios o saltos de línea requieren herramientas como `find`.

## 7.5–7.8 Directorios y navegación

> **Situación real.** Una operación segura empieza por la carpeta correcta. `cd` cambia el contexto de la terminal; por eso siempre confirmas con `pwd` antes de actuar.

```bash
mkdir -p laboratorio/shell/{entrada,salida,backup}
cd laboratorio/shell/entrada
pwd
cd -
rmdir laboratorio/shell/backup
```

Después de `cd laboratorio/shell/entrada`, `pwd` debe terminar en `/laboratorio/shell/entrada`. `cd -` vuelve a la raíz del curso desde la que comenzaste. `rmdir` elimina `backup` porque todavía está vacío; más adelante los respaldos se crearán con otros nombres.

- `mkdir -p`: crea padres y tolera rutas existentes.
- `rmdir`: elimina sólo directorios vacíos.
- `cd -`: regresa a la ruta anterior.
- `pwd`: muestra la ruta efectiva actual.

Salida representativa después de `cd laboratorio/shell/entrada`:

```text
/home/usuario/linux-desde-cero/laboratorio/shell/entrada
```

## 7.9 Unidades y montajes

Linux presenta los sistemas de archivos dentro de una sola jerarquía:

```bash
lsblk -f
findmnt /
```

- `lsblk -f`: `-f` agrega tipo de sistema de archivos, etiqueta y punto de montaje.
- `findmnt /`: pregunta qué está montado en la ruta raíz.

No accedas a “una unidad” por letra; identifica su punto de montaje.

## 7.10 Copiar: `cp`

> **Situación real.** Antes de cambiar una configuración o un artefacto, haces una copia. La regla es siempre la misma: primer argumento = origen, segundo argumento = destino.

Sintaxis general:

```bash
cp [opciones] <origen> <destino>
```

En el ejemplo resuelto, `modelo.txt` es el origen. Créalo vacío con `touch`; si quieres contenido, ábrelo con Text Editor y escribe `accuracy=0.93`.

```bash
touch laboratorio/shell/entrada/modelo.txt
cp -v laboratorio/shell/entrada/modelo.txt laboratorio/shell/backup-modelo.txt
cp -a laboratorio/shell/entrada laboratorio/shell/entrada-copia
```

- `-v`: informa operaciones.
- `-a`: copia recursivamente preservando metadatos apropiados.
- Para evitar sobrescritura accidental puede usarse `cp -i`.

Salida representativa de `cp -v`:

```text
'laboratorio/shell/entrada/modelo.txt' -> 'laboratorio/shell/backup-modelo.txt'
```

## 7.11 Mover y renombrar: `mv`

> **Situación real.** Renombrar una copia deja claro cuál configuración o versión es la vigente sin cambiar su contenido.

Sintaxis general: `mv <origen> <destino>`. Aquí renombraremos la copia `backup-modelo.txt` como `modelo-validado.txt`; el archivo original `entrada/modelo.txt` permanece intacto.

```bash
mv -i laboratorio/shell/backup-modelo.txt laboratorio/shell/modelo-validado.txt
```

Dentro del mismo sistema de archivos, renombrar suele ser inmediato. Entre sistemas puede implicar copiar y eliminar.

- `-i`: solicita confirmación antes de sobrescribir un destino existente.

## 7.12 Enlaces: `ln`

> **Situación real.** Un enlace simbólico permite usar un nombre estable como `modelo-actual` sin duplicar el archivo. Es una referencia, no una segunda copia.

La diferencia entre enlace duro, enlace simbólico e inode se trabaja paso a paso en la sección 3.2. Aquí sólo aplicas un enlace simbólico relativo dentro del laboratorio del shell.

El objetivo se escribe como `entrada/modelo.txt` porque el enlace estará dentro de `laboratorio/shell`. Esa ruta se interpreta desde la ubicación del enlace, no desde tu terminal.

```bash
ln -s entrada/modelo.txt laboratorio/shell/modelo-actual
readlink laboratorio/shell/modelo-actual
```

`-s` crea un enlace simbólico; `readlink` muestra su objetivo almacenado.

Salida representativa:

```text
entrada/modelo.txt
```

## 7.13 Borrar: `rm`

> **Cuidado.** Borrar es la única operación de este bloque que no tiene recuperación general en terminal. Por eso se practica sólo dentro de `laboratorio/shell/` y con confirmaciones.

```bash
rm -i laboratorio/shell/modelo-validado.txt
rm -rI laboratorio/shell/entrada-copia
```

- `-i`: pregunta por cada archivo.
- `-r`: recorre directorios.
- `-I`: una confirmación para una eliminación recursiva o numerosa.

Antes de un `rm -r`, ejecuta `ls` sobre la misma ruta. No uses `-f` como solución automática.

Ambos comandos pedirán confirmación. Responde `y` sólo después de comprobar que las rutas comienzan con `laboratorio/shell/`.

Salida representativa de una confirmación:

```text
rm: remove regular file 'laboratorio/shell/modelo-validado.txt'?
```

## 7.14 Identificar: `file` y `stat`

> **Situación real.** Si un archivo no se comporta como esperas, primero identifica su tipo, tamaño y permisos. La extensión no basta para diagnosticarlo.

```bash
file laboratorio/shell/entrada/modelo.txt
stat -c '%F | %s bytes | %a | %n' laboratorio/shell/entrada/modelo.txt
```

Salida representativa:

```text
ASCII text
regular file | 14 bytes | 644 | laboratorio/shell/entrada/modelo.txt
```

- `%F`: tipo.
- `%s`: bytes.
- `%a`: modo octal.
- `%n`: nombre.

Las opciones usadas:

- `stat -c '<formato>'`: `-c` define qué campos mostrar.
- `%F`, `%s`, `%a` y `%n`: tipo, bytes, permisos octales y nombre.

## 7.15 Permisos y propiedad

> **Situación real.** Los permisos expresan quién puede leer, modificar o ejecutar. Cambiarlos debe ser una decisión basada en el uso del archivo, no un intento de hacer desaparecer un error.

```bash
chmod 640 laboratorio/shell/entrada/modelo.txt
ls -l laboratorio/shell/entrada/modelo.txt
```

- `chmod`: modo.
- `chmod 640`: dueño con lectura/escritura, grupo con lectura y otros sin acceso.
- `ls -l`: confirma el modo aplicado.

`chgrp` y `chown` cambian grupo o dueño y se usan sólo con autorización sobre la ruta. En esta primera clase se observan y se explican; no copies un nombre de usuario o grupo de otra máquina.

Salida representativa:

```text
-rw-r----- ... usuario grupo ... laboratorio/shell/entrada/modelo.txt
```

## Antes de continuar con la Clase 2

Esta sesión empieza **después** de navegación, archivos y permisos. Por eso puedes encontrar trabajo de la Clase 1 dentro de `laboratorio/`. No hace falta borrarlo ni volver a crearlo para usar esta guía.

> **Antes de ejecutar.** Sitúate en la raíz del curso y comprueba los dos archivos de lectura de esta clase. Son fixtures del repositorio: si faltan, no los crees vacíos; recupera el repositorio o pide apoyo al instructor.

```bash
cd ~/linux-desde-cero
pwd
ls data/dummy_logs.txt data/specials.txt
```

El directorio `laboratorio/` sí es tu área de práctica. Puedes crear una carpeta nueva sin tocar los ejercicios anteriores:

```bash
mkdir -p laboratorio/shell
```

Si conservas `laboratorio/shell/entrada/modelo.txt` o `laboratorio/proyecto/` de la Clase 1, úsalos como evidencia de tu avance. Esta clase no depende de ellos. **No ejecutes `preparar-lab.sh` sólo para empezar la Clase 2:** ese script reinicia `laboratorio/` y elimina evidencia previa.

## Ruta práctica de la Clase 2

La numeración del temario conserva `du` y `df` primero, pero en clase conviene aprender en este orden:

1. leer un archivo sin modificarlo (`head`, `tail`, `less`);
2. buscar una pista o un archivo (`grep`, `find`);
3. decidir si falta espacio (`du`, `df`);
4. crear y comprobar un respaldo (`tar`, `gzip`, `sha256sum`);
5. relacionar archivos, montajes y escritorio gráfico.

Los mismos comandos sirven en distintos roles. Un técnico de soporte busca un archivo de un usuario; alguien de backend revisa configuración y logs antes de desplegar; una persona de operaciones investiga un incidente sin modificar el servidor.

## 7.16 Espacio: `du` y `df`

> **Situación real.** Un servicio empieza a fallar porque el disco está lleno. Antes de borrar algo, necesitas responder dos preguntas distintas: “¿qué carpeta creció?” y “¿cuánto espacio queda en el sistema de archivos?”.

`du` significa *disk usage*: mide cuánto ocupan los archivos visibles dentro de una **ruta**. `df` significa *disk free*: muestra la capacidad y el espacio disponible del **sistema de archivos** donde vive una ruta. No son comandos rivales; responden preguntas diferentes.

#### Antes de ejecutar

Los comandos de este apartado sólo consultan información. La ruta `data` es un directorio del curso; `.` significa “el directorio en el que estoy ahora”. Confirma primero que estás en la raíz con `pwd`.

#### Sintaxis que debes reconocer

```text
du [opciones] <ruta>
df [opciones] <ruta>
```

En `du -sh data`, `-s` pide un total resumido y `-h` usa unidades legibles, como KB, MB o GB. En `df -hT .`, `-h` vuelve legibles los tamaños y `-T` agrega el tipo de sistema de archivos, por ejemplo `ext4`.

Banderas de consulta rápida:

- `du -s`: muestra sólo el total de una ruta.
- `du -h` y `df -h`: usan unidades legibles.
- `du --max-depth=1`: separa el tamaño por carpetas inmediatas.
- `df -T`: muestra el tipo de sistema de archivos.

#### Ejemplo guiado

Ejecuta una línea y léela antes de continuar:

```bash
du -sh data
du -h --max-depth=1 data
df -hT .
```

Salida representativa:

```text
180K    data
Filesystem     Type  Size  Used Avail Use% Mounted on
/dev/...       ext4   40G   12G   26G  32% /
```

La primera línea responde cuánto ocupa todo `data`. La segunda separa el total por las carpetas inmediatamente dentro de `data`; úsala para encontrar qué zona merece investigación. La tercera muestra el tamaño total, usado y disponible del disco que contiene el directorio actual.

> **Comprueba.** Si `du -sh data` muestra poco espacio usado y `df -hT .` muestra el disco casi lleno, el problema puede estar fuera de `data`: logs de otro servicio, cachés, archivos de otro usuario o espacio reservado por el sistema.

Los números pueden diferir por metadatos, archivos eliminados que un proceso todavía mantiene abiertos y espacio reservado. No concluyas que un comando “falló” sólo porque sus totales no son idénticos.

> **Cuidado.** Ver el disco lleno no autoriza a borrar con `rm -rf`. Primero identifica la ruta, confirma dueño y permisos, y pide autorización cuando la información pertenezca a otro servicio o usuario.

## 7.17–7.18 Visualizar: `cat`, `head`, `tail`, `less` y `pr`

> **Situación real.** En una guardia recibes un log grande. No necesitas abrirlo con un editor ni imprimirlo todo: primero quieres una muestra inicial, las últimas líneas o una búsqueda segura sin modificar el archivo.

Todos estos comandos **leen** el archivo. Elige el que responde tu pregunta:

| Comando | Pregunta que responde | Cuándo usarlo |
|---|---|---|
| `cat` | “¿Qué contiene completo este archivo pequeño?” | configuración corta o archivo de prueba |
| `head` | “¿Cómo empieza?” | encabezados, formato o primeras líneas |
| `tail` | “¿Qué ocurrió al final?” | eventos recientes de un log |
| `less` | “¿Cómo exploro sin editar?” | archivos medianos o grandes |

#### Ejemplo guiado

```bash
head -n 3 data/dummy_logs.txt
tail -n 2 data/dummy_logs.txt
less data/dummy_logs.txt
```

En `head -n 3`, `-n 3` significa “muestra tres líneas”. `tail -n 2` muestra las dos últimas. Dentro de `less`, escribe `/ERROR` y presiona Enter para buscar; presiona `n` para la siguiente coincidencia y `q` para salir. `less` no modifica el archivo.

Banderas y teclas de consulta rápida:

- `head -n <líneas>`: limita la lectura inicial.
- `tail -n <líneas>`: limita la lectura final.
- `/texto` dentro de `less`: busca texto; `n` repite la búsqueda y `q` sale.

Salida representativa:

```text
2026-07-04 09:00:01 INFO User abimael logged in
2026-07-04 09:01:15 ERROR Disk full on /dev/xvda1
```

`cat data/dummy_logs.txt` también funcionará porque el archivo de práctica es pequeño. En un log de producción evita usar `cat` por costumbre: inundar la terminal dificulta detectar lo importante.

`more` y `pr` aparecen en temarios históricos. `more` es un visor más limitado; `pr` prepara texto para impresión. Para administrar servidores actuales, aprende primero `less`.

> **Comprueba.** Explica con tus palabras por qué usarías `tail` para un incidente reciente y `less` para investigar varias coincidencias sin editar nada.

### Opcional — tipo MIME y aplicación predeterminada

Un tipo MIME describe qué clase de contenido tiene un archivo, por ejemplo `text/plain` o `application/pdf`. No es algo propio de KDE: los escritorios Linux usan esta convención para decidir qué aplicación propone abrir un archivo. Esta consulta es útil en soporte cuando un archivo se abre con una aplicación inesperada.

Ejecuta estas consultas sólo si estás en una sesión gráfica. No cambian ninguna asociación:

```bash
file --mime-type data/dummy_logs.txt
xdg-mime query filetype data/dummy_logs.txt
xdg-mime query default text/plain
```

- `file --mime-type <archivo>`: `--mime-type` pide sólo el tipo detectado por `file`.
- `xdg-mime query filetype <archivo>`: pregunta al entorno qué tipo MIME asigna al archivo.
- `xdg-mime query default <tipo>`: pregunta qué aplicación está registrada para abrir ese tipo.

Salida representativa:

```text
data/dummy_logs.txt: text/plain
text/plain
org.kde.kate.desktop
```

Las dos primeras líneas deben identificar `text/plain`. La última puede ser `org.kde.kate.desktop`, otra aplicación o no mostrar nada si no hay una asociación gráfica en esa sesión. Es una consulta; no intentes corregir una asociación durante esta clase.

## 7.19 Buscar: `grep` y `find`

> **Situación real.** Un ticket dice “hay errores de autenticación” o “no encuentro el archivo de configuración”. Antes de cambiar algo debes separar dos preguntas: `grep` busca **texto dentro de archivos**; `find` busca **archivos y directorios por sus características**.

#### `grep`: encontrar una pista dentro de un archivo

Sintaxis general:

```text
grep [opciones] '<texto a buscar>' <archivo>
```

Las comillas simples conservan el texto tal como lo escribiste. En esta clase buscamos texto literal; las expresiones regulares avanzadas se trabajan en la Clase 4.

```bash
grep -n 'ERROR' data/dummy_logs.txt
grep -ni 'warn' data/dummy_logs.txt
grep -F '[INFO]' data/specials.txt
```

`-n` agrega el número de línea, útil para reportar una evidencia. `-i` ignora mayúsculas y minúsculas. `-F` dice “trata el patrón literalmente”: los corchetes de `[INFO]` no se interpretan como una regla especial.

Banderas de consulta rápida:

- `grep -n`: agrega número de línea.
- `grep -i`: ignora mayúsculas y minúsculas.
- `grep -F`: busca el texto literalmente.

Salida representativa:

```text
2:2026-07-04 09:01:15 ERROR Disk full on /dev/xvda1
5:2026-07-04 09:04:50 ERROR Network unreachable
```

#### `find`: localizar archivos por nombre o tipo

Sintaxis general:

```text
find <dónde_buscar> [condiciones]
```

```bash
find data -maxdepth 2 -type f -name '*.csv'
```

Aquí `data` es el lugar donde comienzas a buscar; `-maxdepth 2` limita la exploración a dos niveles; `-type f` evita devolver directorios; `-name '*.csv'` pide nombres que terminen en `.csv`. Las comillas evitan que el shell intente expandir `*.csv` antes de que `find` lo use.

Banderas de consulta rápida:

- `find <ruta>`: punto de inicio de la búsqueda.
- `-maxdepth 2`: limita niveles recorridos.
- `-type f`: devuelve sólo archivos regulares.
- `-name '<patrón>'`: filtra por nombre.

Salida representativa:

```text
data/basketball_scores.csv
data/hire_data/hiring_01.csv
```

> **Comprueba.** Si buscas la palabra `ERROR` dentro de un log usa `grep`. Si buscas todos los CSV que existen bajo `data`, usa `find`. Di qué parte es la entrada y cuál es el resultado esperado antes de ejecutarlos.

> **Cuidado.** En una búsqueda inicial evita acciones que modifiquen resultados, como opciones de borrado. Primero lista y revisa; actuar sobre resultados masivos es un paso posterior que requiere confirmación.

## 7.20 Empaquetar y comprimir: `tar`/`gzip`

> **Situación real.** Antes de escalar un incidente o entregar evidencia a otro equipo, necesitas mandar varios archivos sin alterar los originales. Un respaldo útil se puede crear, listar, restaurar en otro lugar y comprobar.

`tar` reúne varios archivos en un solo paquete. `gzip` comprime ese paquete para ocupar menos. El nombre `.tar.gz` comunica ambas cosas: primero se agrupó con `tar`, después se comprimió con gzip.

#### Sintaxis que debes reconocer

```text
tar -czf <paquete.tar.gz> <archivos de entrada>
tar -tzf <paquete.tar.gz>
tar -xzf <paquete.tar.gz> -C <directorio de restauración>
```

- `-c`: crear un paquete.
- `-t`: listar lo que contiene, sin extraerlo.
- `-x`: extraer o restaurar.
- `-z`: usar compresión gzip.
- `-f`: el siguiente argumento es el nombre del paquete.
- `-C`: restaurar dentro de otro directorio.

Salida representativa al listar el paquete:

```text
data/dummy_logs.txt
data/specials.txt
```

#### Ejemplo guiado

Primero crea una carpeta segura para la restauración. Si ya existe porque repetiste el ejercicio, `mkdir -p` no borra nada.

```bash
mkdir -p laboratorio/shell/restaurado
```

Ahora crea el paquete. Las entradas son los dos archivos originales; el primer nombre es el nuevo archivo que se creará.

```bash
tar -czf laboratorio/shell/respaldo-clase2.tar.gz data/dummy_logs.txt data/specials.txt
```

Lista el paquete **antes** de extraerlo. Debes ver `data/dummy_logs.txt` y `data/specials.txt`.

```bash
tar -tzf laboratorio/shell/respaldo-clase2.tar.gz
```

Restaura en una ruta diferente para no sobrescribir los originales:

```bash
tar -xzf laboratorio/shell/respaldo-clase2.tar.gz -C laboratorio/shell/restaurado
```

#### Verificar con `sha256sum`

Un hash es una huella calculada a partir del contenido de un archivo. Si dos archivos tienen el mismo contenido, sus hashes SHA-256 coinciden. No necesitas memorizar criptografía para usarlo como comprobación.

```bash
sha256sum data/dummy_logs.txt laboratorio/shell/restaurado/data/dummy_logs.txt
sha256sum data/specials.txt laboratorio/shell/restaurado/data/specials.txt
```

Cada línea empieza con un hash largo. En cada pareja, los dos hashes deben ser iguales. Eso indica que la copia restaurada conserva el mismo contenido que el original.

Salida representativa:

```text
8b3130...  data/dummy_logs.txt
8b3130...  laboratorio/shell/restaurado/data/dummy_logs.txt
```

> **Cuidado.** Nunca extraigas a ciegas un paquete recibido. Primero usa `tar -tzf` para saber qué contiene y elige un directorio de restauración que no pise archivos de trabajo.

## 7.21 Impresión: `lpr`

> **Situación real.** En soporte local puede ser necesario enviar un documento a una impresora compartida. En servidores, contenedores y EC2 normalmente no hay impresora configurada; no es un error que estos comandos no tengan salida útil allí.

En un equipo con CUPS e impresora configurada:

```bash
lpstat -p
lpr documento.pdf
lpq
```

`lpstat -p` muestra las impresoras conocidas. `lpr documento.pdf` envía el archivo indicado a la cola predeterminada. `lpq` consulta trabajos pendientes. Antes de enviar algo, confirma qué impresora es la predeterminada y que el documento no contiene información sensible.

> **Comprueba.** Si `lpstat -p` no muestra impresoras en una EC2, la decisión correcta es no instalar una GUI ni servicios de impresión sólo para “hacer que el ejemplo funcione”. Esta sección es referencia de soporte de escritorio.

## Práctica guiada resuelta — Respaldo de evidencia de un incidente

Una aplicación produjo mensajes de nivel `ERROR` y necesitas entregar al siguiente turno una copia de los logs de práctica. Esta práctica no modifica los originales y no utiliza redirecciones ni pipes: esos mecanismos se estudian en la Clase 3.

1. Comprueba que existen los dos archivos de entrada con el bloque de “Antes de continuar”.
2. Crea `laboratorio/shell/restaurado` si no existe.
3. Crea el paquete, lista su contenido, restaura en otra ruta y compara los hashes.

```bash
mkdir -p laboratorio/shell/restaurado
tar -czf laboratorio/shell/respaldo-clase2.tar.gz data/dummy_logs.txt data/specials.txt
tar -tzf laboratorio/shell/respaldo-clase2.tar.gz
tar -xzf laboratorio/shell/respaldo-clase2.tar.gz -C laboratorio/shell/restaurado
sha256sum data/dummy_logs.txt laboratorio/shell/restaurado/data/dummy_logs.txt
sha256sum data/specials.txt laboratorio/shell/restaurado/data/specials.txt
```

La evidencia mínima es: el nombre del paquete, su listado y dos parejas de hashes iguales. Si un hash no coincide, no entregues el respaldo como válido; vuelve a revisar la ruta de restauración y el archivo comparado.

## Errores frecuentes

- Medir una carpeta con `du` y asumir que eso describe todo el disco; para eso consulta `df`.
- Usar `cat` por costumbre sobre un archivo grande en vez de `head`, `tail` o `less`.
- Confundir buscar texto (`grep`) con localizar archivos (`find`).
- Tratar `*.csv` como una regex; en este caso es un patrón de nombre que recibe `find`.
- Extraer un `tar.gz` sin haberlo listado o restaurarlo sobre los originales.
- Borrar, cambiar permisos o instalar paquetes para resolver una duda que sólo requiere inspección.

## Reto 7 — Snapshot de evidencias

[Ver respuesta](instructor/soluciones.md#respuesta-reto-7)

Imagina que debes entregar evidencia a un compañero de soporte. Dentro de `laboratorio/reto7`, localiza con `find` dos archivos de texto o CSV no vacíos bajo `data/`. Elige dos, crea un único paquete, lista su contenido, restáuralo dentro de `laboratorio/reto7/restaurado` y compara los hashes de los originales y las copias.

Si `laboratorio/reto7` no existe, créalo con `mkdir -p laboratorio/reto7/restaurado`. Si `data/` o los archivos que elegiste no existen, no crees sustitutos vacíos: vuelve al bloque “Antes de continuar”.

### Criterios de comprobación

- Los dos archivos se localizan con `find`, no recorriendo carpetas manualmente.
- El paquete puede listarse sin extraerse.
- La restauración no sobrescribe los originales.
- Dos pares de `sha256sum` demuestran que cada archivo restaurado coincide con su original.
- El alumno puede explicar qué archivo era entrada, cuál fue el paquete y dónde quedó la restauración.

## Checklist

- [ ] Puedo explicar cuándo usaría `du` y cuándo `df` en un incidente.
- [ ] Elijo `head`, `tail` o `less` según la pregunta que necesito responder.
- [ ] Distingo buscar texto con `grep` de localizar archivos con `find`.
- [ ] Creo, listo, restauro y verifico un `tar.gz` sin tocar los originales.
- [ ] Sé qué rutas son datos versionados del curso y cuáles son mi laboratorio de práctica.
