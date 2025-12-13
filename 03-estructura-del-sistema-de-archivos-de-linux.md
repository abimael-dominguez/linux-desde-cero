# 3. Estructura del sistema de archivos de Linux

Este capítulo cubre la estructura básica del sistema de archivos en Linux, enfocándose en conceptos esenciales para desarrolladores: tipos de archivos, enlaces, rutas y permisos. Se incluye una visión general de los directorios raíz para facilitar la navegación y el desarrollo de proyectos.

## Índice

- [3. Estructura del sistema de archivos de Linux](#3-estructura-del-sistema-de-archivos-de-linux)
  - [3.1 Archivos: tipos](#31-archivos-tipos)
    - [Actividad práctica](#actividad-práctica)
  - [3.2 Enlaces](#32-enlaces)
    - [Actividad práctica](#actividad-práctica-1)
  - [3.3 El camino o path](#33-el-camino-o-path)
    - [Actividad práctica](#actividad-práctica-2)
  - [3.4 Estructura del sistema de archivos de Linux](#34-estructura-del-sistema-de-archivos-de-linux)
    - [Actividad práctica](#actividad-práctica-3)
  - [3.5 Acceso a los diferentes sistemas de archivos](#35-acceso-a-los-diferentes-sistemas-de-archivos)
    - [Sistemas de Archivos en Linux](#sistemas-de-archivos-en-linux)
      - [¿Por qué elegir un sistema de archivos específico?](#por-qué-elegir-un-sistema-de-archivos-específico)
      - [EXT (Extended File System)](#ext-extended-file-system)
      - [XFS (Extents File System)](#xfs-extents-file-system)
      - [BTRFS (B-Tree File System)](#btrfs-b-tree-file-system)
      - [Tabla comparativa de sistemas de archivos](#tabla-comparativa-de-sistemas-de-archivos)
      - [Unidades de medida: Terabytes vs Tebibytes](#unidades-de-medida-terabytes-vs-tebibytes)
      - [Conclusión](#conclusión)
    - [Creando Sistemas de archivos](#creando-sistemas-de-archivos)
      - [Pasos para preparar un disco](#pasos-para-preparar-un-disco)
      - [Herramientas para crear FS](#herramientas-para-crear-fs)
      - [Casos especiales: Swap](#casos-especiales-swap)
      - [Modificaciones post-creación](#modificaciones-post-creación)
      - [Conclusión](#conclusión-1)
  - [3.6 Permisos](#36-permisos)
    - [Actividad práctica](#actividad-práctica-5)

## 3.1 Archivos: tipos

En Linux, todo se trata como archivos, pero existen diferentes tipos según su función:

- **Archivos regulares**: Contienen datos (texto, binarios, etc.). Ejemplo: `script.py`.
- **Directorios**: Contienen otros archivos o directorios. Ejemplo: `/home/user`.
- **Enlaces simbólicos**: Punteros a otros archivos (como atajos en Windows).
- **Dispositivos**: Representan hardware, como `/dev/sda` para discos.
- **Sockets y pipes**: Para comunicación entre procesos.

### Actividad práctica
```bash
# Verificar tipo de archivo
file /etc/passwd
# Salida: /etc/passwd: ASCII text

file /dev/sda
# Salida: /dev/sda: block special
```

**Explicación**: El comando `file` identifica el tipo basado en el contenido o metadatos.

## 3.2 Enlaces

Los enlaces permiten acceder a un archivo desde múltiples ubicaciones sin duplicar datos.

- **Enlaces duros**: Apuntan directamente al inode del archivo. Si el original se borra, el enlace sigue funcionando.
- **Enlaces simbólicos (soft)**: Como atajos; si el original se borra, el enlace queda roto.

### Actividad práctica
```bash
# Crear enlace simbólico
ln -s /home/user/documento.txt enlace.txt

# Verificar
ls -l enlace.txt
# Salida: lrwxrwxrwx 1 user user ... enlace.txt -> /home/user/documento.txt

# Crear enlace duro
ln /home/user/documento.txt copia_duro.txt
```

**Explicación**: Útil para bibliotecas compartidas en proyectos, evitando copias innecesarias.

## 3.3 El camino o path

Las rutas especifican la ubicación de archivos.

- **Absolutas**: Empiezan con `/`, desde la raíz. Ej: `/home/user/proyecto/main.py`.
- **Relativas**: Desde el directorio actual. Ej: `../scripts/run.sh`.

### Actividad práctica
```bash
# Mostrar directorio actual
pwd
# Salida: /home/user

# Cambiar a absoluto
cd /usr/bin

# Cambiar relativo
cd ../lib
```

**Explicación**: Crucial para scripts y builds; evita errores de path en entornos de desarrollo.

## 3.4 Estructura del sistema de archivos de Linux

Linux usa una jerarquía unificada desde `/` (raíz). Para desarrolladores, conoce estos directorios clave:

- `/bin`: Ejecutables esenciales (ls, cp).
- `/usr/bin`: Más ejecutables, incluyendo herramientas de desarrollo (gcc, python).
- `/home`: Directorios de usuarios; aquí van tus proyectos.
- `/etc`: Configuraciones del sistema (no edites sin cuidado).
- `/tmp`: Archivos temporales; se borran al reiniciar.
- `/var`: Datos variables (logs, bases de datos).
- `/dev`: Dispositivos (no relevante para dev cotidiano).

### Actividad práctica
```bash
# Explorar raíz
ls -l /
# Salida: drwxr-xr-x 2 root root ... bin
#        drwxr-xr-x 3 root root ... home
#        ...

# Ver contenido de /usr/bin
ls /usr/bin | head -10
```

**Explicación**: Facilita encontrar herramientas y organizar proyectos en `/home`.

## 3.5 Acceso a los diferentes sistemas de archivos

### Sistemas de Archivos en Linux (EXT, XFS, BTRFS)

¿Con tantas opciones de sistemas de archivos en Linux, cuál es el adecuado para ti? Quédate para aprender algunos atributos comunes de los sistemas de archivos de Linux.

#### ¿Por qué elegir un sistema de archivos específico?

Cuando instalas Linux, cada distribución tiene un sistema de archivos predeterminado. Por ejemplo, Ubuntu usa EXT4 (aunque experimentó con BTRFS), mientras que Red Hat usa XFS. Si sigues el predeterminado, estarás bien, pero elegir el correcto desde el inicio puede mejorar el rendimiento o proporcionar características útiles. Cambiar después es complicado: requiere respaldar datos, reformatear y restaurar.

#### EXT (Extended File System)

EXT es el más común, evolucionando de EXT2 a EXT4. EXT2, 3 y 4 comparten la misma base, con características añadidas como journaling en EXT3 y extents en EXT4.

**Características principales:**
- **Tamaño de volumen:** Hasta 1 exabyte (EXT4).
- **Tamaño de archivo:** Hasta 16 terabytes (EXT4).
- **Subdirectorios ilimitados.**
- **Journaling:** Protege contra corrupción por interrupciones (escribe en un journal primero).
- **Compatibilidad:** Ampliamente soportado, incluso en Windows/Mac con drivers.

**Comando para verificar el sistema de archivos:**
```bash
df -T
# Salida esperada: Muestra el tipo de FS, ej. ext4 para /dev/sda1
```

**Explicación:** `df -T` muestra el uso del disco y el tipo de sistema de archivos (`-T` añade la columna Type).

**Cuándo usar EXT4:**
- General purpose, máxima compatibilidad.
- Si no sabes cuál elegir, EXT4 es seguro.

#### XFS (Extents File System)

Desarrollado por Silicon Graphics (SGI) para manejar archivos grandes eficientemente. Usa "extents" (rangos de bloques) en lugar de punteros individuales, mejorando el rendimiento con archivos grandes.

**Características principales:**
- **Tamaño de volumen:** Hasta 8 exabytes.
- **Tamaño de archivo:** Hasta 1 petabyte.
- **Journaling completo.**
- **Optimizado para archivos grandes:** Ideal para gráficos, bases de datos, renderizado 3D.

**Comando para montar un volumen XFS:**
```bash
sudo mount -t xfs /dev/sdb1 /mnt
# Salida: Ninguna si es exitoso; verifica con df -T
```

**Explicación:** `mount -t xfs` especifica el tipo de FS (`-t` indica type). Útil para discos externos o servidores.

**Cuándo usar XFS:**
- Alto rendimiento con archivos grandes (gráficos, DB).
- Predeterminado en Red Hat.

#### BTRFS (B-Tree File System)

Diseñado con todas las características modernas: snapshots, LVM integrado, redimensionamiento dinámico. Es "cutting-edge" pero con más bugs y mantenimiento.

**Características principales:**
- **Tamaño de volumen:** Hasta 8 exabytes.
- **Tamaño de archivo:** Hasta 8 exabytes.
- **Snapshots, journaling, LVM integrado.**
- **Características avanzadas:** Clones, compresión, RAID integrado.

**Comando para crear un snapshot en BTRFS:**
```bash
sudo btrfs subvolume snapshot /mnt /mnt/snapshot
# Salida: Ninguna; verifica con ls /mnt
```

**Explicación:** `btrfs subvolume snapshot` crea una instantánea (`subvolume` maneja subvolúmenes, `snapshot` crea la copia). Requiere FS BTRFS.

**Cuándo usar BTRFS:**
- Necesitas características avanzadas como snapshots o redimensionamiento sin LVM.
- Almacenamiento en red (NAS, NFS).
- Cuidado: Puede ser inestable; no es predeterminado en la mayoría de distros.

#### Tabla comparativa de sistemas de archivos

| Característica          | EXT4                  | XFS                   | BTRFS                 |
|-------------------------|-----------------------|-----------------------|-----------------------|
| **Tamaño máximo volumen** | 1 EB                 | 8 EB                 | 8 EB                 |
| **Tamaño máximo archivo** | 16 TB                | 1 PB                 | 8 EB                 |
| **Journaling**          | Sí                   | Sí                   | Sí                   |
| **Extents**             | Sí (añadido)         | Sí (nativo)          | Sí                   |
| **Snapshots**           | No                   | No                   | Sí                   |
| **LVM integrado**       | No                   | No                   | Sí                   |
| **Compatibilidad**      | Alta                 | Media                | Baja (nuevo)         |
| **Uso recomendado**     | General             | Archivos grandes     | Avanzado/Red         |
| **Estabilidad**         | Alta                 | Alta                 | Media (bugs)         |

#### Unidades de medida: Terabytes vs Tebibytes

En el mundo real, "terabyte" es base 10 (1 TB = 1000^4 bytes), pero discos usan base 2 (1 TiB = 1024^4 bytes). EXT4 soporta 16 TB (terabytes), pero en práctica, verifica con herramientas.

**Comando para verificar tamaño real:**
```bash
lsblk -b
# Salida: Muestra tamaños en bytes
```

**Explicación:** `lsblk -b` muestra bloques en bytes (`-b` para bytes). Útil para confirmar capacidades.

#### Conclusión

- **Workstation:** Usa el predeterminado de tu distro.
- **Servidor específico:** Elige basado en necesidades (EXT4 general, XFS archivos grandes, BTRFS avanzado).
- Recuerda: Elegir bien evita dolores de cabeza futuros.

**Actividad práctica (opcional)**
1. Verifica el FS de tu raíz: `df -T /`
2. Monta un USB y nota el FS: `mount | grep /mnt`
3. Experimenta con snapshots si tienes BTRFS.

**Explicación:** Practica comandos para familiarizarte con FS en entornos reales.

### Creando Sistemas de archivos

Has particionado tu disco duro, pero es inútil sin un sistema de archivos. Quédate para aprender cómo aplicarlo a tu disco duro.

### Pasos para preparar un disco

Después de particionar (o crear volúmenes), necesitas formatear aplicando un sistema de archivos. Esto crea tablas para rastrear archivos y bloques de datos. Sin FS, la partición está vacía.

Pasos básicos:
1. **Tener una partición/volumen listo** (de episodios anteriores).
2. **Formatear:** Aplicar FS (ej. EXT4, XFS).
3. **Montar:** Hacerlo accesible.

### Herramientas para crear FS

Usa `mkfs` (make file system). Varía por distro; Ubuntu incluye EXT, Red Hat añade XFS.

**Ver utilidades mkfs disponibles:**
```bash
ls /usr/sbin/mkfs*
# Salida: mkfs.ext2, mkfs.ext3, mkfs.ext4, mkfs.xfs (si instalado), etc.
```

**Explicación:** Lista herramientas mkfs; instala paquetes si faltan (ej. `sudo apt install xfsprogs` para XFS).

**Ver dispositivos y FS existentes:**
```bash
lsblk -f
# Salida: Lista dispositivos con FS, UUID, labels (ej. sda1 ext4, sdb1 vacío)
```

**Explicación:** `lsblk -f` muestra FS y detalles; `-f` para formato completo.

**Crear EXT4:**
```bash
sudo mkfs.ext4 /dev/sdb1
# Salida: Progreso de creación (grupos, superbloques); confirma con lsblk -f
```

**Explicación:** Aplica EXT4; si no vacío, advierte. Usa `sudo` para permisos.

**Alternativa con mkfs genérico:**
```bash
sudo mkfs -t ext4 /dev/sdc1
# Salida: Similar, crea FS especificado por -t (type)
```

**Explicación:** `-t` especifica tipo; útil para cualquier FS soportado.

**Crear XFS (en distros con soporte):**
```bash
sudo mkfs.xfs /dev/nvme0n1p1
# Salida: Diferente (usa xfs_admin); asigna UUID
```

**Explicación:** Requiere paquete xfsprogs; instala si falta (`sudo apt install xfsprogs` en Ubuntu).

### Casos especiales: Swap

Swap no tiene FS tradicional; el kernel maneja tablas en RAM.

**Crear swap:**
```bash
sudo mkswap /dev/sdd1
# Salida: "Setting up swapspace version 1"; asigna UUID
```

**Activar swap:**
```bash
sudo swapon /dev/sdd1
# Salida: Ninguna; verifica con free -h
```

**Verificar swap:**
```bash
free -h
# Salida: Muestra swap total/usado (ej. 150G swap disponible)
```

**Desactivar swap:**
```bash
sudo swapoff /dev/sdd1
# Salida: Ninguna; swap regresa a original
```

**Explicación:** Swap se activa/desactiva sin montar; útil para memoria virtual.

### Modificaciones post-creación

Después de crear FS, puedes modificar propiedades (sin destruir datos).

**Cambiar label (EXT):**
```bash
sudo e2label /dev/sdb1 backup
# Salida: Ninguna; verifica con lsblk -f (muestra label)
```

**Explicación:** Labels identifican discos para montaje; `e2label` para EXT (compatible con EXT2-4).

**Cambiar label (XFS):**
```bash
sudo xfs_admin -L backup /dev/nvme0n1p1
# Salida: "writing all SBs"; new label = backup
```

**Explicación:** `-L` para label; usa `xfs_admin` para XFS.

**Redimensionar (riesgos altos):**
- EXT: `sudo resize2fs /dev/sdb1` (crecer; shrinking limitado).
- XFS: `sudo xfs_growfs /mnt` (solo crecer; monta primero).
- Riesgo: Posible pérdida de datos; respalda siempre. Vendors como Red Hat no lo soportan. Usa LVM para evitar.

**Cambiar FS:** Imposible sin destruir datos (excepto EXT2→3→4). Respaldar, reformatear, restaurar.

### Conclusión

Crea FS para hacer particiones usables. Usa `mkfs` para formatear, `lsblk` para verificar. Modificaciones son posibles pero riesgosas; prefiere planificación inicial.

**Actividad práctica (opcional)**
1. Lista dispositivos: `lsblk -f`
2. Crea EXT4 en partición vacía: `sudo mkfs.ext4 /dev/sdX1` (reemplaza sdX)
3. Cambia label: `sudo e2label /dev/sdX1 mi_label`
4. Verifica: `lsblk -f`

**Explicación:** Practica en VM o disco externo; evita discos con datos.

## 3.6 Permisos

Los permisos controlan quién puede leer (r), escribir (w) o ejecutar (x) archivos.

- **Propietario**: Usuario que creó el archivo.
- **Grupo**: Grupo del usuario.
- **Otros**: Todos los demás.

### Actividad práctica
```bash
# Ver permisos
ls -l script.sh
# Salida: -rw-r--r-- 1 user dev 1024 ... script.sh

# Cambiar permisos (ejecutable para todos)
chmod +x script.sh

# Cambiar propietario
sudo chown user:dev script.sh
```

**Explicación**: Esencial para compartir código; asegura que scripts sean ejecutables y archivos sensibles protegidos.