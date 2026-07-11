# 7. El shell

## Objetivos

- Navegar y administrar archivos desde Bash.
- Consultar ayuda y verificar el efecto de cada comando.
- Buscar, medir, empaquetar y recuperar información.
- Aplicar opciones de seguridad antes de borrar o sobrescribir.

## Antes de empezar

Este capítulo forma una secuencia: cada apartado reutiliza archivos del anterior. Empieza desde la raíz del curso y prepara una copia limpia de los datos:

```bash
cd ~/linux-desde-cero
bash ejercicios-bash-scripting/preparar-lab.sh
mkdir -p laboratorio/shell/{entrada,salida,backup}
```

Trabajaremos con `modelo.txt` como archivo original, `backup-modelo.txt` como copia y `modelo-validado.txt` como nombre nuevo. No uses archivos personales para estas prácticas.

## 7.1–7.3 Shell, comandos y directorio personal

Bash interpreta palabras, expansiones, redirecciones y operadores. Un comando puede ser builtin del shell o un ejecutable externo.

```bash
type cd
type ls
echo "$HOME"
cd
pwd
```

Salida representativa:

```text
cd is a shell builtin
ls is /usr/bin/ls
/home/ubuntu
/home/ubuntu
```

`cd` debe cambiar el directorio del shell actual; por eso es builtin.

## 7.4 Listar: `ls`

```bash
ls -lah
ls -lt laboratorio | head
```

- `-l`: formato largo.
- `-a`: incluye nombres que comienzan con `.`.
- `-h`: tamaños legibles junto con `-l`.
- `-t`: ordena por modificación.

No analices `ls` en scripts complejos: nombres con espacios o saltos de línea requieren herramientas como `find`.

## 7.5–7.8 Directorios y navegación

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

## 7.9 Unidades y montajes

Linux presenta los sistemas de archivos dentro de una sola jerarquía:

```bash
lsblk -f
findmnt /
```

No accedas a “una unidad” por letra; identifica su punto de montaje.

## 7.10 Copiar: `cp`

Sintaxis general:

```bash
cp [opciones] <origen> <destino>
```

En el ejemplo resuelto, `modelo.txt` es el origen. El primer `printf` crea ese archivo; no necesitas crearlo antes.

```bash
printf 'accuracy=0.93\n' > laboratorio/shell/entrada/modelo.txt
cp -v laboratorio/shell/entrada/modelo.txt laboratorio/shell/backup-modelo.txt
cp -a laboratorio/shell/entrada laboratorio/shell/entrada-copia
```

- `-v`: informa operaciones.
- `-a`: copia recursivamente preservando metadatos apropiados.
- Para evitar sobrescritura accidental puede usarse `cp -i`.

## 7.11 Mover y renombrar: `mv`

Sintaxis general: `mv <origen> <destino>`. Aquí renombraremos la copia `backup-modelo.txt` como `modelo-validado.txt`; el archivo original `entrada/modelo.txt` permanece intacto.

```bash
mv -i laboratorio/shell/backup-modelo.txt laboratorio/shell/modelo-validado.txt
```

Dentro del mismo sistema de archivos, renombrar suele ser inmediato. Entre sistemas puede implicar copiar y eliminar.

## 7.12 Enlaces: `ln`

El objetivo se escribe como `entrada/modelo.txt` porque el enlace estará dentro de `laboratorio/shell`. Esa ruta se interpreta desde la ubicación del enlace, no desde tu terminal.

```bash
ln -s entrada/modelo.txt laboratorio/shell/modelo-actual
readlink laboratorio/shell/modelo-actual
```

`-s` crea un enlace simbólico; `readlink` muestra su objetivo almacenado.

## 7.13 Borrar: `rm`

```bash
rm -i laboratorio/shell/modelo-validado.txt
rm -rI laboratorio/shell/entrada-copia
```

- `-i`: pregunta por cada archivo.
- `-r`: recorre directorios.
- `-I`: una confirmación para una eliminación recursiva o numerosa.

Antes de un `rm -r`, ejecuta `ls` sobre la misma ruta. No uses `-f` como solución automática.

Ambos comandos pedirán confirmación. Responde `y` sólo después de comprobar que las rutas comienzan con `laboratorio/shell/`.

## 7.14 Identificar: `file` y `stat`

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

## 7.15 Permisos y propiedad

```bash
chmod 640 laboratorio/shell/entrada/modelo.txt
chgrp "$(id -gn)" laboratorio/shell/entrada/modelo.txt
sudo chown "$USER":"$(id -gn)" laboratorio/shell/entrada/modelo.txt
```

- `chmod`: modo.
- `chgrp`: grupo.
- `chown`: dueño y opcionalmente grupo.

`$USER` y `$(id -gn)` se resuelven automáticamente. Si el usuario y grupo son `ubuntu`, el último comando equivale a `sudo chown ubuntu:ubuntu ...`.

## 7.16 Espacio: `du` y `df`

```bash
du -sh laboratorio data
du -h --max-depth=1 data | sort -h
df -hT .
```

- `du`: suma bloques usados por archivos visibles desde una ruta.
- `df`: informa capacidad del sistema de archivos.
- `-s`: total resumido.
- `--max-depth=1`: desglose inmediato.

Los totales pueden diferir por archivos eliminados aún abiertos, metadatos y espacio reservado.

## 7.17–7.18 Visualizar: `cat`, `head`, `tail`, `less` y `pr`

```bash
cat data/dummy_logs.txt
head -n 3 data/dummy_logs.txt
tail -n 2 data/dummy_logs.txt
less data/dummy_logs.txt
```

- `cat`: salida completa; ideal para archivos pequeños o pipelines.
- `head`/`tail`: primeras/últimas líneas.
- `less`: navegación y búsqueda interactiva con `/patrón`; sal con `q`.
- `more` y `pr` se conservan por compatibilidad con el temario, pero `less` y formatos específicos suelen ser más útiles.

## 7.19 Buscar: `grep` y `find`

```bash
grep -n 'ERROR' data/dummy_logs.txt
grep -Ei 'warn|error' data/dummy_logs.txt
grep -F '[INFO]' data/specials.txt
find data -maxdepth 2 -type f -name '*.csv' -size +0c
```

- `-n`: número de línea.
- `-E`: expresiones regulares extendidas; sustituye al nombre histórico `egrep`.
- `-F`: búsqueda literal; sustituye al nombre histórico `fgrep`.
- `-i`: ignora mayúsculas/minúsculas.
- `find -type f`: sólo archivos; `-name`: patrón de nombre; `-size +0c`: no vacíos.

## 7.20 Empaquetar y comprimir: `tar`/`gzip`

```bash
tar -czf laboratorio/shell/datos.tar.gz data/dummy_logs.txt data/specials.txt
tar -tzf laboratorio/shell/datos.tar.gz
mkdir -p laboratorio/shell/restaurado
tar -xzf laboratorio/shell/datos.tar.gz -C laboratorio/shell/restaurado
```

- `-c`: crear; `-t`: listar; `-x`: extraer.
- `-z`: usar gzip.
- `-f`: el argumento siguiente es el archivo.
- `-C`: cambia el destino antes de extraer.

Verifica el contenido con `-t` antes de extraer archivos recibidos.

## 7.21 Impresión: `lpr`

El temario incluye impresión Unix. En un equipo configurado con CUPS:

```bash
lpstat -p
lpr documento.pdf
lpq
```

En servidores y EC2 normalmente no hay impresora; se presenta como referencia, no como laboratorio.

## Práctica guiada resuelta — Respaldo de logs

Esta práctica toma `data/dummy_logs.txt`, extrae las tres líneas `WARN`/`ERROR`, crea un paquete y lo restaura sin tocar el archivo original.

```bash
mkdir -p laboratorio/shell/reporte laboratorio/shell/restauracion
grep -En 'WARN|ERROR' data/dummy_logs.txt > laboratorio/shell/reporte/incidentes.txt
wc -l laboratorio/shell/reporte/incidentes.txt
tar -czf laboratorio/shell/incidentes.tar.gz -C laboratorio/shell reporte
tar -tzf laboratorio/shell/incidentes.tar.gz
tar -xzf laboratorio/shell/incidentes.tar.gz -C laboratorio/shell/restauracion
cmp laboratorio/shell/reporte/incidentes.txt \
    laboratorio/shell/restauracion/reporte/incidentes.txt
```

`cmp` no produce salida cuando ambos archivos son idénticos y termina con código 0.

Por eso, **no ver nada después de `cmp` significa éxito**. Para hacerlo visible:

```bash
cmp laboratorio/shell/reporte/incidentes.txt \
    laboratorio/shell/restauracion/reporte/incidentes.txt \
  && echo "Restauración verificada"
```

## Errores frecuentes

- Usar rutas relativas sin comprobar `pwd`.
- Omitir comillas alrededor de variables con rutas.
- Confundir glob del shell (`*.csv`) con regex.
- Empaquetar datos y asumir que existen sin listar el archivo resultante.
- Usar `rm -rf` o `chmod 777` para evitar diagnosticar.

## Reto 7 — Snapshot de evidencias

[Ver respuesta](instructor/soluciones.md#respuesta-reto-7)

Trabaja dentro de `laboratorio/reto7`. Busca en `data/` archivos de texto o CSV no vacíos, genera `inventario.txt` con ruta y tamaño, empaqueta el inventario junto con `data/dummy_logs.txt` y restaura el paquete dentro de `laboratorio/reto7/restaurado`.

### Criterios de comprobación

- El inventario se genera con comandos, no manualmente.
- El paquete puede listarse sin extraerse.
- La restauración no sobrescribe los originales.
- Se demuestra que el inventario restaurado coincide con el original.

## Checklist

- [ ] Navego con rutas absolutas y relativas.
- [ ] Copio, muevo, enlazo y borro con verificación.
- [ ] Consulto tipo, permisos, propietario y espacio.
- [ ] Busco por contenido y por metadatos.
- [ ] Creo, inspecciono y restauro un `tar.gz`.
