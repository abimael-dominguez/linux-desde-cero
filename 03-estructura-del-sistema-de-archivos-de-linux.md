# 3. Estructura del sistema de archivos de Linux

## Objetivos

- Reconocer tipos de archivos y rutas.
- Navegar la jerarquía principal de Linux.
- Crear enlaces y explicar su diferencia.
- inspeccionar montajes sin modificar discos.
- aplicar permisos y propietarios de forma consciente.

## Antes de empezar

Sitúate en la raíz del curso y crea el espacio de trabajo:

```bash
cd ~/linux-desde-cero
mkdir -p laboratorio/enlaces
```

En los ejemplos usaremos estos nombres concretos:

| Nombre | Qué representa |
|---|---|
| `config.ini` | archivo original |
| `config-duro.ini` | enlace duro al original |
| `config-actual.ini` | enlace simbólico al original |
| `deploy.sh` | archivo para practicar permisos |

## 3.1 Tipos de archivo

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

`file` inspecciona el contenido o metadatos; la extensión no decide el tipo en Linux.

## 3.2 Enlaces

Sintaxis general:

```bash
ln <archivo_existente> <nuevo_enlace_duro>
ln -s <ruta_objetivo> <nuevo_enlace_simbolico>
```

Ejemplo resuelto: `config.ini` será el archivo existente y los otros dos nombres serán los enlaces.

```bash
mkdir -p laboratorio/enlaces
printf 'version=1\n' > laboratorio/enlaces/config.ini
ln laboratorio/enlaces/config.ini laboratorio/enlaces/config-duro.ini
ln -s config.ini laboratorio/enlaces/config-actual.ini
ls -li laboratorio/enlaces
```

- `ln origen destino`: enlace duro al mismo inode.
- `ln -s objetivo enlace`: enlace simbólico que guarda una ruta.
- `ls -i`: muestra el inode; los enlaces duros comparten número.
- Un enlace simbólico puede cruzar sistemas de archivos, pero puede quedar roto.

## 3.3 Rutas o paths

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

## 3.4 Jerarquía principal

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
cat /proc/meminfo | head
```

## 3.5 Acceso a sistemas de archivos

En este curso se inspeccionan montajes; no se formatean discos.

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

- `lsblk -f`: dispositivos, sistema de archivos, etiquetas y montajes.
- `findmnt`: relación entre destino y origen.
- `df -hT`: espacio disponible y tipo; `-h` usa unidades legibles y `-T` agrega el tipo.
- ext4 es común en Ubuntu; XFS y Btrfs ofrecen decisiones diferentes, pero el usuario trabaja con la misma jerarquía.

## 3.6 Permisos

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
sudo chown "$USER":"$(id -gn)" laboratorio/enlaces/deploy.sh
ls -l laboratorio/enlaces/deploy.sh
```

En `chown`, `$USER` se sustituye automáticamente por tu usuario actual y `$(id -gn)` por tu grupo principal. Por ejemplo, si ambos se llaman `ubuntu`, el comando efectivo equivale a:

```bash
sudo chown ubuntu:ubuntu laboratorio/enlaces/deploy.sh
```

No copies `ubuntu:ubuntu` si tu cuenta tiene otro nombre; la versión con `$USER` se adapta sola.

- `chmod`: cambia bits de permiso.
- `chown usuario:grupo`: cambia dueño y grupo.
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
printf 'PORT=8080\n' > laboratorio/proyecto/config/app.env
printf '#!/usr/bin/env bash\necho "servicio listo"\n' > laboratorio/proyecto/bin/status.sh
chmod 640 laboratorio/proyecto/config/app.env
chmod 750 laboratorio/proyecto/bin/status.sh
ln -s ../config/app.env laboratorio/proyecto/bin/config-actual
laboratorio/proyecto/bin/status.sh
ls -l laboratorio/proyecto/config laboratorio/proyecto/bin
```

Salida principal:

```text
servicio listo
-rwxr-x--- ... status.sh
lrwxrwxrwx ... config-actual -> ../config/app.env
-rw-r----- ... app.env
```

El enlace muestra `rwx` por sí mismo; el acceso efectivo depende del objetivo y de los directorios de la ruta.

Si ves `Permission denied` al ejecutar `status.sh`, confirma primero `pwd` y luego ejecuta `ls -l laboratorio/proyecto/bin/status.sh`.

## Errores frecuentes

- Aplicar `chmod -R 777` para ocultar un problema.
- Confundir espacio de `df` con tamaño de archivos calculado por `du`.
- Crear un enlace simbólico relativo desde el directorio equivocado.
- Ejecutar `chown` o `rm` sin comprobar la ruta.

## Reto 3 — Directorio compartido

[Ver respuesta](instructor/soluciones.md#respuesta-reto-3)

Crea `laboratorio/compartido` para un equipo: dueño con control total, grupo con lectura/escritura/acceso y otros sin acceso. Dentro crea `app.env` como configuración no ejecutable, `check.sh` como script ejecutable y `check-actual` como enlace simbólico al script.

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
