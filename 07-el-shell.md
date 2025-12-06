# 7. El Shell

## 7.1 Introducción

El shell es la interfaz de línea de comandos para interactuar con Linux. En la industria se usa para automatización (scripts), administración de servidores, despliegues y análisis de logs.

- Comprobar tu shell actual: `echo $SHELL`
- Cambiar temporalmente: `bash` o `zsh`
- Ver shells disponibles: `cat /etc/shells`

Resultado esperado:
- `echo $SHELL` -> `/bin/bash` o `/bin/zsh`

## 7.2 Algunos comandos sencillos de LINUX

Comandos básicos útiles en cualquier entorno.

- Fecha y hora: `date`
	- Uso: Timestamps en scripts y auditoría.
	- Recomendación: `date +"%F %T"` para formato estándar ISO.
	- Comprobación: Comparar con reloj del sistema.
	- Resultado esperado: `2025-12-05 14:30:00`

- Usuarios conectados: `who`
	- Uso: Ver sesiones en servidores multiusuario.
	- Recomendación: `who | wc -l` para contar sesiones.
	- Comprobación: Ver TTYs activos.
	- Resultado esperado: `user tty0 2025-12-05 14:30`

- Tiempo encendido: `uptime`
	- Uso: Salud del servidor y carga.
	- Recomendación: Vigilar `load average`.
	- Comprobación: Cruzar con logs de reinicio.
	- Resultado esperado: `14:30 up 5 days, 2 users, load average: 0.05, 0.10, 0.08`

## 7.3 Directorio personal

Tu directorio home es tu espacio de trabajo.

- Ir al home: `cd ~` o `cd`
- Ver ruta actual: `pwd`
- Usar variable: `echo $HOME`

Casos de uso: configuración de herramientas, claves SSH.
Comprobación: `pwd` debe mostrar tu home.
Resultado esperado: `/home/usuario` o `/Users/usuario`

## 7.4 Listado del contenido de directorios: comando ls

Lista archivos y directorios con opciones clave.

- Formato largo y ocultos: `ls -lah`
- Ordenar por fecha: `ls -lt`
- Filtrar por patrón: `ls -l *.log`

Casos de uso: inspección de releases, permisos, tamaños.
Recomendación: usar `-h` para tamaños legibles.
Comprobación: validar permisos en primera columna.
Resultado esperado: `-rw-r--r-- 1 user user 1.2K Dec  5 14:30 app.log`

## 7.5 Creación de subdirectorios. Comando mkdir

Crear estructuras de proyecto.

- Crear anidados: `mkdir -p proyecto/src/tests`
- Verificar creación: `ls -d proyecto/src`

Casos de uso: scaffolding de repos, pipelines.
Recomendación: siempre `-p` en scripts.
Resultado esperado: `proyecto/src`

## 7.6 Borrado de subdirectorios. Comando rmdir

Eliminar directorios vacíos.

- Borrar vacío: `rmdir carpeta_vacia`
- Comprobar vacío: `ls -A carpeta_vacia` (sin salida)

Recomendación: usar `rm -r` si contiene archivos y estás seguro.
Resultado esperado: `rmdir: failed to remove 'carpeta_vacia': No such file or directory` si ya no existe.

## 7.7 Cambio de directorio. Comando cd

Navegar por el sistema de archivos.

- Subir nivel: `cd ..`
- Volver anterior: `cd -`
- Ir absoluto: `cd /var/log`

Casos de uso: revisar logs, configuraciones.
Comprobación: `pwd` tras moverte.
Resultado esperado: ruta actual cambia, e.g., `/var/log`

## 7.8 Ruta actual. Comando pwd

Mostrar la ruta actual.

- Ver ruta: `pwd`

Casos de uso: evitar operaciones en rutas equivocadas.
Recomendación: usar en scripts antes de acciones destructivas.
Resultado esperado: `/home/usuario/proyecto`

## 7.9 Acceso a unidades de disco

Montar y acceder a dispositivos.

- Listar discos: `lsblk` (Linux) o `diskutil list` (macOS)
- Montar (Linux): `sudo mount /dev/sdb1 /mnt`
- Ver uso: `df -h`

Casos de uso: adjuntar volúmenes de datos, backups.
Comprobación: `ls /mnt` muestra archivos.
Resultado esperado: `Filesystem Size Used Avail Use% Mounted on ... /mnt`

Buenas prácticas:

En Linux ha dos lugares "estandar" para montar cosas:

- /media
    - Generalmente lo usa el sistema para cosas automáticas (USBs, CDs)
- /mnt
    - Es la carpeta clásica de montajes manuales.
    - Ejemplos:
        - /mnt/respaldos
        - /mnt/fotos
        - /mnt/disco_externo


## 7.10 Copia de ficheros. Comando cp

Copiar archivos y directorios.

- Copia simple: `cp origen.txt destino.txt`
- Preservar atributos: `cp -a dir1 dir2`
- Recursivo: `cp -r carpeta destino/`

Casos de uso: respaldos de configuración, duplicar assets.
Recomendación: `-i` para evitar sobrescribir.
Comprobación: `ls destino.txt` existe.
Resultado esperado: `destino.txt` copiado.

## 7.11 Traslado y cambio de nombre de ficheros. Comando mv

Mover o renombrar.

- Renombrar: `mv archivo.log archivo-2025-12-05.log`
- Mover: `mv build/* releases/`

Casos de uso: versionado de logs, reorganizar builds.
Recomendación: `-i` para evitar sobrescrituras.
Comprobación: `ls` en origen y destino.
Resultado esperado: archivos ubicados/renombrados correctamente.

## 7.12 Enlaces a ficheros. Comando ln

Crear enlaces simbólicos y duros.

- Enlace simbólico: `ln -s /opt/app/config.yml ~/.config/app.yml`
- Enlace duro: `ln archivo.dat enlace.dat`

Casos de uso: apuntar a versiones, dotfiles.
Recomendación: preferir simbólicos para flexibilidad.
Comprobación: `ls -l` muestra `->` en simbólicos.
Resultado esperado: `app.yml -> /opt/app/config.yml`

## 7.13 Borrado de ficheros. Comando rm

Eliminar archivos y árboles.

- Borrar archivo: `rm archivo.tmp`
- Recursivo y forzado: `rm -rf carpeta_tmp/`

Casos de uso: limpiar temporales, artefactos.
Recomendación: extrema cautela con `rm -rf` (nunca con rutas expansivas como `/`).
Comprobación: `ls` no debe mostrar el archivo.
Resultado esperado: archivo/directorio eliminado.

## 7.14 Características de un fichero. Comando file

Detectar tipo de contenido real.

- Analizar: `file paquete.bin`

Casos de uso: validar uploads, binarios, scripts.
Comprobación: coincide con lo esperado.
Resultado esperado: `paquete.bin: ELF 64-bit LSB executable`

## 7.15 Cambio de modo de los ficheros comandos chmod, chown y chgrp

Gestionar permisos y propiedad.

Una calculadora octal es tu mejor amiga para entender chmod.

En el mundo de Linux, los permisos no se calculan con matemáticas complejas, sino con una suma muy simple basada en el sistema octal (base 8). Tu calculadora te servirá para sumar los "puntos" que vale cada permiso.

Aquí tienes la guía definitiva para usar tu calculadora con chmod.

1. La Tabla de Puntos (El Código Secreto)
Imagina que cada permiso tiene un precio o un valor en puntos. Solo hay 3 números que debes memorizar:

| Valor | Permiso | Letra | Significado |
|---|---|---|---|
| 4 | Lectura | r (Read) | Ver el archivo (abrir el libro). |
| 2 | Escritura | w (Write) | Modificar el archivo (arrancar o escribir hojas). |
| 1 | Ejecución | x (Execute) | Correr el programa (si es un script o app). |
| 0 | Nada | - | Prohibido el paso. |

2. Cómo usar tu calculadora
Para saber qué número poner en el chmod, solo tienes que sumar lo que quieres permitir.
 * Quiero leer y escribir: 4 + 2 = 6
 * Quiero leer y ejecutar: 4 + 1 = 5
 * Quiero todo (Full access): 4 + 2 + 1 = 7
 * Solo quiero leer: 4 + 0 + 0 = 4
¡Por eso el número máximo es 7! (Es un sistema octal porque los dígitos van del 0 al 7).

3. Los Tres Dígitos del chmod
Cuando ves un comando como chmod 755 archivo.txt, en realidad son tres sumas separadas una al lado de la otra.
Tu calculadora octal te ayuda a desglosar esto:
 * Primer dígito (El Dueño/Tú): ¿Qué permisos tienes tú?
 * Segundo dígito (El Grupo): ¿Qué permisos tienen tus colegas de equipo?
 * Tercer dígito (El Resto del Mundo): ¿Qué permiso tiene cualquier extraño?

Ejemplo: El famoso 755

Desglosemos qué significa usando tu suma:
 * 7 (Tú): 4+2+1 -> Tienes control total (Lees, Escribes, Ejecutas).
 * 5 (Grupo): 4+1 -> Ellos pueden Leer y Ejecutar, pero no Escribir (el 2 no está en la suma).
 * 5 (Otros): 4+1 -> Los extraños igual: miran pero no tocan.

4. Advertencia de Seguridad
Seguro verás en internet gente recomendando chmod 777.
 * ¿Qué significa? 4+2+1 para TI, para el GRUPO y para TODOS.
 * Traducción: Dejas la puerta de tu casa abierta, sin llave, y con un cartel que dice "Entren y hagan lo que quieran". ¡Evítalo a menos que sea estrictamente necesario!

Resumen para tu calculadora

No necesitas hacer multiplicaciones ni divisiones.

Tu calculadora octal te sirve para verificar: "Si sumo Lectura (4) + Escritura (2), ¿el resultado es 6?".

¿Quieres hacer una prueba rápida?
Dime qué permisos le darías a un archivo que es top secret: Solo tú puedes leerlo y escribirlo, y nadie más (ni grupo ni otros) puede ver nada. ¿Qué número (código de 3 dígitos) usarías?

- Respuesta: 600

### Resumen:

Explicación de permisos (octal y simbólico):

- Lectura (`r`=4), escritura (`w`=2), ejecución (`x`=1). Octal combina por posición: propietario/grupo/otros.
- Ejemplo `chmod 750 script.sh` equivale a `u=rwx,g=rx,o=---`.

Tabla descriptiva rápida:

- Permiso: `r` — Descripción: leer contenido — Afecta: archivos y directorios (listar).
- Permiso: `w` — Descripción: modificar — Afecta: escribir archivo; crear/borrar en directorio.
- Permiso: `x` — Descripción: ejecutar — Afecta: ejecutar binario/script; entrar a directorio.
- Modo: `u,g,o` — Usuario, grupo, otros.
- Símbolos: `+` añade, `-` quita, `=` asigna exacto.

Comandos comunes y casos de uso:

- Cambiar permisos (octal): `chmod 640 README.md`
	- Caso: restringir lectura a grupo, negar a otros.
	- Comprobación: `ls -l README.md`
	- Resultado esperado: `-rw-r-----`

- Cambiar permisos (simbólico): `chmod u+x scripts/deploy.sh`
	- Caso: permitir ejecución al propietario.
	- Comprobación: `ls -l scripts/deploy.sh`
	- Resultado esperado: `-rwx------` o similar, según estado previo.

- Cambiar dueño y grupo: `sudo chown root:dev /opt/app/config.yml`
	- Caso: propiedad correcta para servicios.
	- Comprobación: `ls -l /opt/app/config.yml`
	- Resultado esperado: dueño `root`, grupo `dev`.

- Cambiar grupo: `sudo chgrp dev /opt/app/config.yml`
	- Caso: ajustar acceso compartido.
	- Comprobación: `ls -l /opt/app/config.yml`
	- Resultado esperado: grupo `dev` aplicado.

Tabla descriptiva (resumen de comandos):

- Comando: `chmod` — Acción: permisos — Ejemplos: `chmod 755 archivo`, `chmod g-w,o-r archivo` — Resultado: actualización de bits de permiso.
- Comando: `chown` — Acción: dueño/grupo — Ejemplos: `chown user archivo`, `chown user:group archivo` — Resultado: cambio de propietario.
- Comando: `chgrp` — Acción: grupo — Ejemplos: `chgrp dev archivo` — Resultado: cambio de grupo.

## 7.16 Espacio ocupado en el disco comandos DU y DF

Medir uso y disponibilidad.

- Uso por directorio: `du -h -d 1 /var/log`
    - Verificar el espacio ocupado por cada usuario
        - `du -h -d 1 /home/`

- Espacio libre: `df -h`

Casos de uso: monitoreo de disco, evitar incidentes.
Comprobación: comparar suma de `du` con `df`.
Resultado esperado: tamaños legibles por directorio y total disponible.

## 7.17 Visualización sin formato de un fichero comando CAT y con formato comando PR

Ver contenido de archivos.

- Sin formato: `cat README.md`
- Con paginado/encabezado (impresión): `pr -h "Reporte" archivo.txt`

Casos de uso: revisión rápida de configs/logs.
Recomendación: usar `cat` en pipelines.
Comprobación: contenido visible en terminal.
Resultado esperado: líneas del archivo impresas.

## 7.18 Visualización de ficheros pantalla a pantalla comandos MORE y LESS

Navegar archivos largos.

- Paginado: `less /var/log/syslog`
- Búsqueda: dentro de `less` usar `/error`.

Casos de uso: análisis de logs extensos.
Recomendación: preferir `less` a `more`.
Comprobación: moverse con flechas y encontrar patrones.
Resultado esperado: visualización página a página.

## 7.19 Busqueda en ficheros comandos GREP, FGREP y EGREP

Buscar patrones en textos. `grep` significa Global Regular Expressions Print y  en términos simples funciona como un filtro.

Tabla descriptiva rápida:

- Comando: `grep` — Patrones básicos (BRE) — Ejemplo: `grep -n ERROR archivo.log`
- Comando: `egrep` o `grep -E` — Patrones extendidos (ERE) — Ejemplo: `grep -E "(ERROR|FAIL)" archivo.log`
    - Equivale a ejecutar grep -E. Su función principal es permitir el uso de Expresiones Regulares Extendidas sin necesidad de "escapar" caracteres especiales ( como  +, ?, |, etc.), lo que hace que los comandos sean más legibles.

- Ejemplos:
    - Encontrar líneas que comiencen con una o más letras mayúsculas seguidas de dos puntos (:), ejemplo: "NOMBRE: Juan".
        - `egrep "^[A-Z]+:" README.md ` (si no funciona quitar ^)
    - Validación de formato de URLs
        - Imagina que quieres buscar URLs en un archivo, pero algunas son http y otras https. Quieres capturar ambas con un solo patrón.
            - `egrep "https?://www\.google\.com" enlaces.txt`
                - |: O lógico 
                - +: Significa que el anterior se repite 1 o más veces.
                - ?: Significa que el anterior se repite 0 o 1 vez (opcional)
                - .: Cualquier caracter
                - ^: Inicio de línea
                - $: Fin de la línea
        
- Comando: `fgrep` o `grep -F` — Búsqueda literal — Ejemplo: `grep -F "[INFO]" archivo.log`

Opciones útiles:
- `-n` (número de línea), `-i` (insensible a mayúsculas), `-r` (recursivo), `--color=auto` (resaltar), `-H` (mostrar nombre archivo).

Ejemplos usando este repositorio (`*.md`):

- Buscar “Linux” en todos los temas: `grep -nH "Linux" *.md`
	- Caso: verificar menciones en documentación.
	- Resultado esperado: líneas con `Linux` y archivos como `README.md:1: Temario de Linux`.

- Buscar títulos de sección “El Shell” en todo: `grep -nH "El Shell" *.md`
	- Caso: localizar sección rápidamente.
	- Resultado esperado: coincidencias en `README.md` y `07-el-shell.md`.

- Recursivo por carpetas (si las hubiera): `grep -rnH "Permisos" .`
	- Caso: auditar documentación de permisos.
	- Resultado esperado: rutas y líneas con “Permisos”.

- Literal exacto con corchetes: `grep -F "[INFO]" app.log`
	- Caso: logs con etiquetas.
	- Resultado esperado: líneas con `[INFO]` sin interpretar regex.

- Regex extendido con alternación: `grep -E "(GNOME|KDE)" README.md`
	- Caso: buscar tecnologías de entornos gráficos.
	- Resultado esperado: líneas que contienen GNOME o KDE.

Ejercicios prácticos (usa los archivos del repo):

- Contar cuántas veces aparece “Introducción” en todos los `.md`: `grep -o "Introducción" *.md | wc -l`
	- Comprobación: número total impreso.
	- Resultado esperado: un entero, por ejemplo `5`.

- Listar archivos que mencionan “permisos” ignorando mayúsculas: `grep -li "permisos" *.md`
	- Comprobación: nombres de archivos mostrados.
	- Resultado esperado: `03-estructura...`, `07-el-shell.md`, etc.

- Mostrar líneas y archivo donde aparece “GREP”: `grep -nH "GREP" 07-el-shell.md`
	- Comprobación: ver el número de línea.
	- Resultado esperado: coincidencias en la sección 7.19.

- Extraer encabezados (líneas que empiezan con `#`) del README: `grep -n "^#" README.md`
	- Comprobación: todas las cabeceras con número de línea.
	- Resultado esperado: líneas que comienzan con `#`.

## 7.20 Comandos TAR y GZIP

Empaquetar y comprimir.

Tabla descriptiva rápida:

- Comando: `tar` — Empaquetar múltiples archivos en un único tarball.
- Comando: `gzip` — Comprimir un archivo (incluido un tarball) usando DEFLATE.

Opciones comunes de `tar`:
- `-c` crear, `-x` extraer, `-t` listar, `-z` gzip, `-v` verbose, `-f` archivo, `-C` directorio destino.

Ejemplos prácticos:

- Crear un paquete del repositorio actual: `tar -czf linux-desde-cero_$(date +%F).tar.gz *.md`
	- Caso: snapshot de documentación.
	- Comprobación: `tar -tzf linux-desde-cero_$(date +%F).tar.gz | head`
	- Resultado esperado: lista de `.md` dentro del tar.gz.

- Listar contenido detallado: `tar -tvzf linux-desde-cero_2025-12-05.tar.gz`
	- Caso: inspeccionar permisos y fechas dentro del tar.
	- Resultado esperado: líneas con permisos/tamaño/fecha/nombre.

- Extraer a carpeta específica: `mkdir -p dist && tar -xzf linux-desde-cero_2025-12-05.tar.gz -C dist`
	- Comprobación: `ls dist`
	- Resultado esperado: archivos `.md` presentes en `dist`.

- Comprimir un archivo suelto con gzip: `gzip README.md`
	- Caso: reducir tamaño para transferencia.
	- Comprobación: `ls README.md.gz`
	- Resultado esperado: `README.md.gz` creado.

- Descomprimir: `gunzip README.md.gz`
	- Comprobación: `ls README.md`
	- Resultado esperado: archivo restaurado.

- Ver tamaño antes/después: `ls -lh README.md README.md.gz`
	- Resultado esperado: tamaños distintos (gz más pequeño).

Ejercicios:

- Empaqueta todos los temas y verifica: `tar -czf temas.tar.gz 0*.md 1*.md`
	- Comprobación: `tar -tzf temas.tar.gz | wc -l`
	- Resultado esperado: conteo de archivos incluidos.

- Crea un tar sin compresión y luego comprímelo: `tar -cf docs.tar *.md && gzip docs.tar`
	- Comprobación: `ls docs.tar.gz`
	- Resultado esperado: `docs.tar.gz` existente.

## 7.21 Comandos de impresion lpr

Enviar trabajos a impresión.

- Imprimir: `lpr documento.pdf`
- Ver cola: `lpq`
- Cancelar: `lprm <job_id>`

Casos de uso: oficinas, reportes.
Recomendación: verificar impresora con `lpstat -p`.
Comprobación: `lpq` muestra el trabajo en cola.
Resultado esperado: trabajo en cola y salida impresa.