# 3. Estructura del sistema de archivos de Linux

Este capítulo cubre la estructura básica del sistema de archivos en Linux, enfocándose en conceptos esenciales para desarrolladores: tipos de archivos, enlaces, rutas y permisos. Se incluye una visión general de los directorios raíz para facilitar la navegación y el desarrollo de proyectos.

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

Puedes montar sistemas de archivos externos (USB, redes) en directorios existentes.

### Actividad práctica
```bash
# Montar USB (asumiendo /dev/sdb1)
sudo mount /dev/sdb1 /mnt

# Desmontar
sudo umount /mnt
```

**Explicación**: Útil para acceder a datos externos en desarrollo, pero evita modificaciones en producción.

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