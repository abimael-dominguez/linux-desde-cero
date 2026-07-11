# 1. Introducción a Linux y al entorno de trabajo

## Objetivos

Al terminar este capítulo podrás:

- distinguir hardware, kernel, distribución, shell y terminal;
- reconocer por qué Linux es habitual en servidores, nube y DevOps;
- identificar Ubuntu, la versión del kernel y el entorno de ejecución;
- consultar ayuda antes de ejecutar un comando;
- crear la primera evidencia del curso sin modificar configuraciones críticas.

## Contexto del laboratorio

Todo el curso utiliza los mismos nombres. No son marcadores: son los valores concretos del laboratorio.

| Recurso | Valor | Función |
|---|---|---|
| Administrador | `ubuntu` | Cuenta inicial de la EC2; ejecuta tareas con `sudo`. |
| Usuario operativo | `deploy` | Cuenta sin privilegios administrativos; se creará en el capítulo 2. |
| Grupo de trabajo | `ops` | Compartirá recursos del proyecto; se creará en el capítulo 2. |
| Proyecto | `/srv/consultor-linux` | Única raíz de los laboratorios del curso. |
| Sistema de referencia | Ubuntu Server 24.04 LTS | EC2 o máquina virtual local de respaldo. |

En este capítulo debes haber iniciado sesión como `ubuntu`:

```bash
whoami
```

Salida esperada en EC2:

```text
ubuntu
```

Si aparece otro nombre, no reemplaces propietarios a ciegas. En el fallback local crea una cuenta llamada `ubuntu` o adapta conscientemente los ejemplos parametrizados.

En las secciones de sintaxis, los nombres entre `< >` son marcadores que debes sustituir; no se escriben literalmente. Después de cada sintaxis encontrarás un ejemplo completo con los valores reales del curso.

## Modelo mental

```text
persona
  │ escribe en
  ▼
terminal ──► shell Bash ──► programas y utilidades
                    │
                    ▼
               kernel Linux
                    │
                    ▼
       CPU · memoria · red · almacenamiento
```

- **Terminal:** interfaz que recibe texto y muestra resultados. Una ventana gráfica y una sesión SSH pueden proporcionar una terminal.
- **Shell:** programa que interpreta los comandos. En el curso usaremos Bash.
- **Kernel:** núcleo que administra procesos, memoria, dispositivos, red y sistemas de archivos.
- **Distribución:** kernel más utilidades, bibliotecas, paquetes y decisiones de configuración.

La terminal no interpreta `cd`, variables o tuberías: lo hace el shell que se ejecuta dentro de ella.

## 1.1 Linux en servidores y nube

Una instancia EC2 es una máquina virtual que usa recursos físicos de AWS. Ubuntu es la distribución instalada y Linux es su kernel.

```text
centro de datos de AWS
└── host físico
    └── hipervisor
        └── EC2 Ubuntu
            ├── kernel Linux
            ├── servicios
            └── nuestra sesión SSH
```

La administración se hace principalmente por terminal porque es reproducible, consume pocos recursos y puede automatizarse. Una interfaz gráfica no es necesaria para que un servidor web, una base de datos o un contenedor funcionen.

### Comprobar distribución y kernel

Sintaxis general:

```bash
uname <opción>
cat <archivo_de_información>
```

Valores del laboratorio:

| Parámetro | Valor concreto | Significado |
|---|---|---|
| `<opción>` | `-r` | Muestra la versión (*release*) del kernel en ejecución. |
| `<archivo_de_información>` | `/etc/os-release` | Describe la distribución instalada. |

Comandos copiables:

```bash
uname -r
cat /etc/os-release
```

Salida representativa; el número exacto del kernel puede cambiar con las actualizaciones:

```text
6.8.0-xx-generic
PRETTY_NAME="Ubuntu 24.04.x LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
ID=ubuntu
```

`uname` y `/etc/os-release` responden preguntas distintas: el primero muestra el kernel activo; el segundo identifica la distribución.

## 1.2 Familias de distribuciones

| Familia | Distribuciones actuales | Gestor habitual | Uso frecuente |
|---|---|---|---|
| Debian | Debian, Ubuntu | `apt`/`dpkg` | nube, servidores y escritorio |
| Red Hat | Fedora, RHEL, Rocky Linux, CentOS Stream | `dnf`/`rpm` | empresa y plataformas híbridas |
| Arch | Arch Linux | `pacman` | sistemas altamente personalizados |

CentOS **Linux** ya no es la distribución comunitaria estable tradicional; CentOS **Stream** es el flujo previo a RHEL. El curso usa Ubuntu, pero los conceptos de usuarios, procesos, permisos, redes y servicios son transferibles.

## 1.3 Software libre y código abierto

El código abierto permite inspeccionar, modificar y redistribuir software bajo las condiciones de su licencia. No significa necesariamente “sin costo” ni “sin soporte comercial”.

Ejemplos del entorno:

```bash
apt-cache show bash | grep -E '^(Package|Version|Homepage):'
apt-cache show coreutils | grep -E '^(Package|Version|Homepage):'
```

Salida representativa:

```text
Package: bash
Version: 5.2...
Homepage: http://tiswww.case.edu/php/chet/bash/bashtop.html
```

`apt-cache show` consulta metadatos locales; no instala ni actualiza paquetes. `grep -E` conserva sólo los campos indicados.

## 1.4 Shell, terminal y sesión

Comandos copiables:

```bash
printf 'shell configurado: %s\n' "$SHELL"
ps -p "$$" -o pid=,comm=
tty
```

Salida representativa en una conexión SSH interactiva:

```text
shell configurado: /bin/bash
  1482 bash
/dev/pts/0
```

- `$SHELL` contiene el shell configurado para la cuenta.
- `$$` se expande al PID del shell actual.
- `ps -p` selecciona ese PID; `-o` define las columnas.
- `tty` muestra la terminal asociada. En una ejecución no interactiva puede responder `not a tty`.

## 1.5 Pedir ayuda sin adivinar

```bash
type uname
command -v uname
uname --help | head -n 8
man uname
```

- `type` indica si el nombre es un alias, una función, un builtin o un ejecutable.
- `command -v` muestra cómo resolverá el shell ese nombre.
- `--help` ofrece un resumen rápido.
- `man` abre el manual; busca con `/texto`, avanza con `n` y sal con `q`.
- `head -n 8` limita la salida a ocho líneas.

No copies una opción encontrada en Internet sin comprobar que existe en la versión instalada.

## Preparar la raíz del curso

`install -d` crea un directorio y define sus metadatos en una sola operación.

Sintaxis parametrizada:

```bash
sudo install -d -o <propietario> -g <grupo> -m <modo> <ruta>
```

Ejemplo completo para este capítulo:

```bash
sudo install -d -o ubuntu -g ubuntu -m 0750 /srv/consultor-linux
sudo install -d -o ubuntu -g ubuntu -m 0750 \
  /srv/consultor-linux/evidencias \
  /srv/consultor-linux/evidencias/01
ls -ld /srv/consultor-linux /srv/consultor-linux/evidencias/01
```

- `-d`: crea directorios, incluidos los padres necesarios.
- `-o ubuntu`: establece al propietario.
- `-g ubuntu`: establece al grupo inicial. En el capítulo 2 crearemos `ops`.
- `-m 0750`: propietario con acceso total, grupo con lectura y acceso, otros sin permisos.
- `sudo`: eleva únicamente este comando; `/srv` no es modificable por un usuario común.

Salida representativa:

```text
drwxr-x--- ... ubuntu ubuntu ... /srv/consultor-linux
drwxr-x--- ... ubuntu ubuntu ... /srv/consultor-linux/evidencias/01
```

## Práctica guiada resuelta — Inventario mínimo del servidor

La práctica escribe sólo un archivo de texto dentro de la ruta recién creada.

```bash
EVIDENCIA=/srv/consultor-linux/evidencias/01/inventario.txt

{
  printf 'usuario=%s\n' "$(whoami)"
  printf 'host=%s\n' "$(hostname)"
  printf 'kernel=%s\n' "$(uname -r)"
  printf 'sistema='
  . /etc/os-release
  printf '%s %s\n' "$NAME" "$VERSION_ID"
  VIRTUALIZACION=$(systemd-detect-virt 2>/dev/null) \
    || VIRTUALIZACION=no-detectada
  printf 'virtualizacion=%s\n' "$VIRTUALIZACION"
  free -h
  df -h /
} | tee "$EVIDENCIA"

test -s "$EVIDENCIA" && echo "Evidencia creada correctamente"
```

Qué ocurre:

1. `EVIDENCIA=...` asigna la ruta a una variable; no se escriben espacios alrededor de `=`.
2. `{ ...; }` agrupa varias salidas.
3. `. /etc/os-release` carga campos conocidos de ese archivo del sistema.
4. `2>/dev/null` oculta sólo el error de detección; el texto alternativo evita un campo vacío.
5. `tee` muestra y guarda el mismo contenido.
6. `test -s` confirma que el archivo existe y no está vacío.

Los valores de memoria, disco, host y kernel serán distintos en cada instancia.

## Fallo controlado — Una ruta mal escrita

Ejecuta deliberadamente:

```bash
cat /etc/os-releas
printf 'código de salida=%s\n' "$?"
```

Salida esperada:

```text
cat: /etc/os-releas: No such file or directory
código de salida=1
```

Diagnóstico y corrección:

```bash
ls -l /etc/*release*
cat /etc/os-release
```

El mensaje nombra el archivo que no existe. Antes de instalar algo o usar `sudo`, revisa ortografía y ruta. El estado `0` significa éxito; un valor diferente de cero comunica un fallo.

## Comprobación y reversión

Comprueba sin modificar:

```bash
stat -c 'tipo=%F modo=%a dueño=%U grupo=%G ruta=%n' \
  /srv/consultor-linux/evidencias/01/inventario.txt
```

No borres la evidencia: se reutilizará durante el curso. Si necesitas rehacer únicamente el archivo:

```bash
rm -i -- /srv/consultor-linux/evidencias/01/inventario.txt
```

`-i` pide confirmación y `--` marca el fin de las opciones. Verifica la ruta mostrada antes de responder `y`.

## Reto 1 — Ficha reproducible de la instancia

Crea `/srv/consultor-linux/evidencias/01/ficha-instancia.txt` usando comandos, no un editor. Debe incluir usuario, distribución, kernel, memoria total, espacio disponible en `/` y shell actual.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-1)

### Criterios de éxito

- El archivo contiene al menos seis campos con etiquetas comprensibles.
- Los valores proceden del sistema y no fueron escritos a mano.
- `test -s` confirma que el archivo no está vacío.
- No se modifica ningún archivo dentro de `/etc`, `/proc` o `/sys`.

## Checklist

- [ ] Distingo terminal, shell, distribución y kernel.
- [ ] Sé por qué un servidor no necesita escritorio gráfico.
- [ ] Identifico Ubuntu y el kernel sin confundirlos.
- [ ] Consulto `type`, `--help` y `man` antes de adivinar opciones.
- [ ] Interpreto un código de salida de éxito o error.
- [ ] Guardé una evidencia dentro de `/srv/consultor-linux`.
