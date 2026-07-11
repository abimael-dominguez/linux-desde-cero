# 3. Comandos y gestión de archivos

## Objetivos

Al terminar este capítulo podrás:

- navegar con rutas absolutas y relativas;
- crear, copiar, mover y eliminar archivos dentro de un laboratorio acotado;
- leer archivos completos o por secciones;
- buscar texto literal y patrones con expresiones regulares;
- distinguir enlaces duros y simbólicos;
- diagnosticar una ruta o un enlace incorrectos sin recurrir a permisos inseguros.

## Contexto del laboratorio

Continuamos como administrador `ubuntu`; `deploy` y `ops` ya existen. Todas las operaciones de este capítulo se limitan a:

```text
/srv/consultor-linux/laboratorios/03-archivos
```

No practiques `mv`, `rm` o enlaces sobre `/etc`, `/home` ni archivos personales.

Los elementos entre `< >` de una sintaxis son marcadores, no texto literal. Cada sintaxis se acompaña de un ejemplo copiable limitado al laboratorio.

## Modelo mental

```text
/srv/consultor-linux/laboratorios/03-archivos
├── datos/       archivos originales
├── copias/      copias y nombres nuevos
├── enlaces/     referencias a archivos
└── reportes/    resultados de búsquedas

ruta absoluta: /srv/consultor-linux/laboratorios/03-archivos/datos/app.conf
ruta relativa:  datos/app.conf       (desde 03-archivos)
```

Un archivo no “vive dentro” del comando: el shell resuelve su ruta respecto del directorio actual.

## Preparar un laboratorio repetible

Sintaxis parametrizada:

```bash
mkdir -p <directorio>/{<subdirectorio_1>,<subdirectorio_2>}
```

Ejemplo completo:

```bash
LAB=/srv/consultor-linux/laboratorios/03-archivos
mkdir -p "$LAB"/{datos,copias,enlaces,reportes}
printf 'APP=portal\nPORT=8080\nENV=dev\n' > "$LAB/datos/app.conf"
printf '%s\n' \
  '2026-07-04T09:05:00Z INFO inicio correcto' \
  '2026-07-04T09:08:13Z WARN memoria al 78%' \
  '2026-07-04T09:10:42Z ERROR conexión rechazada' \
  '2026-07-04T09:11:07Z INFO reintento correcto' \
  '2026-07-04T09:14:25Z ERROR tiempo agotado' \
  > "$LAB/datos/app.log"
```

- `LAB=...` da un único nombre a la ruta; las comillas protegen su expansión.
- `mkdir -p` crea padres faltantes y no falla si ya existen.
- `{datos,copias,...}` es una expansión de Bash que produce cuatro rutas.
- `printf` es predecible y permite crear fixtures pequeños.
- `>` crea o reemplaza el archivo indicado; comprueba siempre la ruta antes de usarlo.

Si ya habías hecho la práctica y quieres conservarla, no la borres: renómbrala antes de repetir:

```bash
mv -i "$LAB" "${LAB}.anterior.$(date +%Y%m%d-%H%M%S)"
```

`LAB` es una variable del shell actual, no una configuración permanente. Si abres otra terminal o vuelves otro día, ejecuta de nuevo `LAB=/srv/consultor-linux/laboratorios/03-archivos` antes de copiar cualquier bloque que contenga `"$LAB"`.

## 3.1 Navegación: `pwd`, `cd` y `ls`

```bash
cd "$LAB"
pwd
ls -lah
ls -l datos
cd datos
pwd
cd ..
```

Salida representativa:

```text
/srv/consultor-linux/laboratorios/03-archivos
drwxr-xr-x ... copias
drwxr-xr-x ... datos
...
/srv/consultor-linux/laboratorios/03-archivos/datos
```

- `pwd`: imprime la ruta actual.
- `cd <ruta>`: cambia el directorio del shell actual.
- `..`: directorio padre; `.` significa directorio actual.
- `ls -l`: formato largo; `-a`: incluye nombres ocultos; `-h`: tamaños legibles.

Antes de una operación destructiva confirma `pwd` y lista el objetivo exacto.

## 3.2 Crear, copiar, mover y eliminar

### Sintaxis parametrizada

```bash
touch <archivo>
cp [opciones] <origen> <destino>
mv [opciones] <origen> <destino>
rm [opciones] -- <archivo>
rmdir <directorio_vacío>
```

### Ejemplo completo y comprobable

```bash
touch "$LAB/datos/notas.txt"
cp -v "$LAB/datos/app.conf" "$LAB/copias/app.conf.bak"
mkdir -p "$LAB/copias/datos-snapshot"
cp -av "$LAB/datos/." "$LAB/copias/datos-snapshot/"
mv -iv "$LAB/datos/notas.txt" "$LAB/reportes/notas-operacion.txt"

stat -c '%F | %s bytes | %a | %n' \
  "$LAB/datos/app.conf" \
  "$LAB/copias/app.conf.bak" \
  "$LAB/reportes/notas-operacion.txt"
```

- `touch`: crea un archivo vacío o actualiza su fecha de modificación.
- `cp -v`: muestra qué copia; `-a` copia directorios preservando metadatos útiles.
- `mv -v`: mueve o renombra e informa la operación.
- `stat -c`: elige un formato: `%F` tipo, `%s` bytes, `%a` modo y `%n` nombre.

`cp` crea otro archivo; modificar la copia no cambia el original:

```bash
printf 'BACKUP=true\n' >> "$LAB/copias/app.conf.bak"
cmp "$LAB/datos/app.conf" "$LAB/copias/app.conf.bak" \
  || echo "Correcto: ahora los archivos son diferentes"
```

Para practicar eliminación crea primero un objeto desechable:

```bash
touch "$LAB/reportes/descartar.tmp"
ls -l "$LAB/reportes/descartar.tmp"
rm -i -- "$LAB/reportes/descartar.tmp"
```

- `-i` pide confirmación. Responde `y` sólo después de leer la ruta.
- `--` impide interpretar como opción un nombre que comience con `-`.
- `rmdir` es preferible para aprender porque sólo elimina directorios vacíos.
- No se necesita `rm -rf` en este curso.

## 3.3 Leer archivos: `cat`, `less`, `head` y `tail`

```bash
cat "$LAB/datos/app.conf"
head -n 2 "$LAB/datos/app.log"
tail -n 2 "$LAB/datos/app.log"
less "$LAB/datos/app.log"
```

Salida de `head -n 2`:

```text
2026-07-04T09:05:00Z INFO inicio correcto
2026-07-04T09:08:13Z WARN memoria al 78%
```

| Comando | Úsalo cuando... |
|---|---|
| `cat` | el archivo es pequeño y quieres toda la salida |
| `head -n N` | necesitas las primeras `N` líneas |
| `tail -n N` | necesitas las últimas `N` líneas |
| `less` | quieres navegar un archivo grande sin cargarlo en un editor |

Dentro de `less`, busca con `/ERROR`, avanza con `n` y sal con `q`. `less` no modifica el archivo.

## 3.4 Buscar con `grep` y expresiones regulares

Sintaxis parametrizada:

```bash
grep [opciones] '<patrón>' <archivo>
```

Ejemplos copiables:

```bash
grep -nF 'ERROR' "$LAB/datos/app.log"
grep -nE 'WARN|ERROR' "$LAB/datos/app.log"
grep -nE '^2026-07-04T09:1[0-4]:' "$LAB/datos/app.log"
grep -cF 'ERROR' "$LAB/datos/app.log"
```

Salidas representativas:

```text
3:2026-07-04T09:10:42Z ERROR conexión rechazada
5:2026-07-04T09:14:25Z ERROR tiempo agotado
2
```

- `-n`: agrega número de línea.
- `-F`: trata el patrón como texto literal.
- `-E`: habilita expresiones regulares extendidas.
- `-c`: muestra cuántas líneas coinciden.
- `^`: inicio de línea; `|`: alternativa; `[0-4]`: un carácter dentro del rango.

Un glob del shell como `*.log` selecciona **nombres de archivo**. Una regex como `WARN|ERROR` describe **texto dentro del archivo**. No son la misma sintaxis.

Para localizar archivos por metadatos usa `find`:

```bash
find "$LAB" -maxdepth 2 -type f -name '*.log' -size +0c
```

- `-maxdepth 2`: limita la profundidad.
- `-type f`: sólo archivos regulares.
- `-name '*.log'`: el patrón va entre comillas para que lo procese `find`.
- `-size +0c`: tamaño mayor que cero bytes.

## 3.5 Enlaces duros y simbólicos

```text
nombre original ─┐
                 ├──► inode y datos       enlace duro
segundo nombre ──┘

enlace simbólico ───► texto con otra ruta ───► archivo objetivo
```

Sintaxis:

```bash
ln <archivo_existente> <nuevo_enlace_duro>
ln -s <ruta_objetivo> <nuevo_enlace_simbolico>
```

Ejemplo desde cualquier directorio:

```bash
ln -f "$LAB/datos/app.conf" "$LAB/enlaces/app.conf.hard"
ln -sfn ../datos/app.conf "$LAB/enlaces/app.conf.current"
ls -li "$LAB/datos/app.conf" "$LAB/enlaces/app.conf.hard"
ls -l "$LAB/enlaces/app.conf.current"
readlink "$LAB/enlaces/app.conf.current"
```

Salida representativa:

```text
10501 -rw-r--r-- 2 ubuntu ... app.conf
10501 -rw-r--r-- 2 ubuntu ... app.conf.hard
... app.conf.current -> ../datos/app.conf
../datos/app.conf
```

- Los enlaces duros comparten inode y no cruzan sistemas de archivos.
- El enlace simbólico guarda una ruta y puede apuntar a otro sistema de archivos.
- `-s` crea el simbólico; `-f` reemplaza sólo el destino indicado; `-n` evita seguir un enlace existente al reemplazarlo.
- La ruta relativa `../datos/app.conf` se interpreta desde el directorio `enlaces`, no desde tu terminal.

Comprueba el contenido y el destino resuelto:

```bash
cat "$LAB/enlaces/app.conf.current"
readlink -f "$LAB/enlaces/app.conf.current"
```

## Práctica guiada resuelta — Reporte de incidentes

La práctica conserva el log original, produce un reporte y verifica su número de líneas.

```bash
grep -nE 'WARN|ERROR' "$LAB/datos/app.log" \
  > "$LAB/reportes/incidentes.txt"

printf 'incidentes=' > "$LAB/reportes/resumen.txt"
wc -l < "$LAB/reportes/incidentes.txt" \
  >> "$LAB/reportes/resumen.txt"

cat "$LAB/reportes/incidentes.txt"
cat "$LAB/reportes/resumen.txt"
test "$(wc -l < "$LAB/reportes/incidentes.txt")" -eq 3 \
  && echo "Reporte verificado"
```

Salida final esperada:

```text
incidentes=3
Reporte verificado
```

`>` reemplaza el reporte y permite repetir la práctica; `>>` agrega el conteo a la etiqueta ya escrita. El log de entrada permanece intacto.

## Fallo controlado — Enlace simbólico roto

Crea deliberadamente un enlace con un objetivo relativo incorrecto:

```bash
ln -sfn app.conf "$LAB/enlaces/app.conf.roto"
cat "$LAB/enlaces/app.conf.roto"
printf 'código=%s\n' "$?"
```

Salida esperada:

```text
cat: .../app.conf.roto: No such file or directory
código=1
```

Diagnóstico:

```bash
readlink "$LAB/enlaces/app.conf.roto"
ls -l "$LAB/enlaces/app.conf.roto"
ls -l "$LAB/enlaces/app.conf"
```

El enlace contiene `app.conf`, así que busca `enlaces/app.conf`, que no existe. Corrígelo y verifica:

```bash
ln -sfn ../datos/app.conf "$LAB/enlaces/app.conf.roto"
readlink -f "$LAB/enlaces/app.conf.roto"
cat "$LAB/enlaces/app.conf.roto"
```

No era un problema de permisos; `chmod 777` no habría corregido la ruta.

## Reversión segura

Conserva el laboratorio como evidencia. Para revertir operaciones individuales:

```bash
rm -i -- "$LAB/enlaces/app.conf.roto"
rm -i -- "$LAB/enlaces/app.conf.current"
rm -i -- "$LAB/enlaces/app.conf.hard"
```

`rm` aplicado a un enlace simbólico elimina el enlace, no el archivo objetivo. No se incluye un borrado recursivo: la limpieza final listará y respaldará el árbol antes de retirarlo.

## Reto 3 — Inventario de configuraciones

Dentro de `$LAB/reto`, crea tres archivos `.conf`, al menos uno con `ENABLED=true`. Genera un inventario con ruta y tamaño, un reporte de coincidencias con número de línea y un enlace simbólico `config-activa` hacia uno de los archivos. Conserva los originales.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-3)

### Criterios de éxito

- `find` localiza solamente archivos `.conf` no vacíos.
- `grep -F` encuentra `ENABLED=true` sin editar archivos a mano.
- `readlink -f` resuelve `config-activa` hacia un archivo existente.
- El reporte puede regenerarse y no modifica los fixtures.
- No se usa `rm -rf`, `chmod 777` ni una ruta fuera de `$LAB`.

## Checklist

- [ ] Compruebo `pwd` antes de mover o eliminar.
- [ ] Distingo ruta absoluta, relativa, `.` y `..`.
- [ ] Uso `cp`, `mv` y `rm -i` sobre objetivos explícitos.
- [ ] Elijo entre `cat`, `head`, `tail` y `less`.
- [ ] Distingo búsqueda literal, regex y glob.
- [ ] Explico la diferencia entre enlace duro y simbólico.
- [ ] Diagnostico una ruta antes de cambiar permisos.
