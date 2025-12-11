# 13. Hands-on SSH and SCP

Este módulo cubre conceptos prácticos de SSH (Secure Shell) y SCP (Secure Copy). Aprenderemos a conectarnos a servidores remotos de forma segura, configurar autenticación sin contraseña y copiar archivos entre sistemas.

## Índice

- [1. Introducción a SSH](#1-introducción-a-ssh)
- [2. Conectando con SSH](#2-conectando-con-ssh)
- [3. Autenticación sin contraseña con claves SSH](#3-autenticación-sin-contraseña-con-claves-ssh)
- [4. Copiando archivos con SCP](#4-copiando-archivos-con-scp)

## Recursos Útiles

- Documentación oficial de OpenSSH: [OpenSSH Manual](https://man.openbsd.org/ssh)
- Guía de SCP: [SCP Command](https://man.openbsd.org/scp)

## 1. Introducción a SSH

SSH es un protocolo que permite el acceso seguro a sistemas remotos. Se utiliza para ejecutar comandos en servidores remotos como si estuviéramos físicamente allí.

### Sintaxis básica de SSH

```bash
ssh [usuario@]host
```

- `usuario`: El nombre de usuario en el servidor remoto (opcional, por defecto usa el usuario actual).
- `host`: La dirección IP o nombre de host del servidor remoto.

### Requisitos

- El servidor remoto debe tener el servicio SSH corriendo en el puerto 22.
- Debes tener credenciales válidas (usuario/contraseña o clave SSH).

## 2. Conectando con SSH

Vamos a practicar conectándonos a un servidor remoto llamado `server`.

### Ejemplo: Conexión básica con SSH

```bash
ssh server
```

Si no especificas un usuario, SSH intentará conectarse con el usuario actual de tu sistema local.

**Salida esperada:**

```
The authenticity of host 'server (192.168.1.100)' can't be established.
ECDSA key fingerprint is SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'server' (ECDSA) to the list of known hosts.
user@server's password: 
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.4.0-74-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

Last login: Mon Dec 13 10:30:45 2021 from 192.168.1.50
user@server:~$
```

Después de ingresar la contraseña correcta, estarás en el shell del servidor remoto.

### Conexión especificando usuario

```bash
ssh user@server
```

O usando la opción `-l`:

```bash
ssh -l user server
```

## 3. Autenticación sin contraseña con claves SSH

Para evitar ingresar la contraseña cada vez, podemos configurar autenticación basada en claves SSH.

### Paso 1: Generar un par de claves

En tu máquina local (cliente), genera un par de claves:

```bash
ssh-keygen
```

**Salida esperada:**

```
Generating public/private rsa key pair.
Enter file in which to save the key (/home/user/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/user/.ssh/id_rsa.
Your public key has been saved in /home/user/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX user@laptop
The key's randomart image is:
+---[RSA 3072]----+
|                 |
|                 |
|                 |
+----[SHA256]-----+
```

- Clave privada: `~/.ssh/id_rsa` (no compartir)
- Clave pública: `~/.ssh/id_rsa.pub` (se comparte)

### Paso 2: Copiar la clave pública al servidor remoto

Usa `ssh-copy-id` para copiar la clave pública al servidor:

```bash
ssh-copy-id user@server
```

**Salida esperada:**

```
user@server's password: 
Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'user@server'"
and check to make sure that only the key(s) you wanted were added.
```

### Paso 3: Verificar la conexión sin contraseña

Ahora puedes conectarte sin ingresar contraseña:

```bash
ssh user@server
```

Deberías conectarte directamente al shell remoto.

### Ubicación de la clave en el servidor

La clave pública se almacena en `~/.ssh/authorized_keys` en el servidor remoto.

Puedes verificar:

```bash
cat ~/.ssh/authorized_keys
```

## 4. Copiando archivos con SCP

SCP permite copiar archivos y directorios de forma segura entre sistemas usando SSH.

### Sintaxis básica de SCP

```bash
scp [opciones] origen destino
```

### Ejemplo: Copiar un archivo al servidor remoto

```bash
scp my-code.tgz user@server:~/
```

**Salida esperada:**

```
my-code.tgz                              100% 1024KB  10.2MB/s   00:00
```

### Ejemplo: Copiar un archivo al servidor remoto usando una clave privada específica

```bash
scp -i /path/to/private/key.pem <archivo a enviar>.txt user@remote-server:~/
```

**Nota:** Reemplaza `/path/to/private/key.pem` con la ruta a tu clave privada, `<archivo a enviar>.txt` con el nombre del archivo a copiar, `user@remote-server` con el usuario y host remoto, y `~/` con el directorio destino.

La opción `-i` especifica el archivo de clave privada a usar para la autenticación SSH. Esto es útil cuando tienes múltiples claves o cuando la clave no está en la ubicación predeterminada (`~/.ssh/id_rsa`). Asegúrate de que el archivo de clave tenga permisos restrictivos (ej. `chmod 600 key.pem`) para seguridad.

### Copiar directorios

Para copiar directorios, usa la opción `-r`:

```bash
scp -r mi_directorio user@server:~/
```

### Preservar permisos y timestamps

Usa la opción `-p`:

```bash
scp -p archivo.txt user@server:~/
```

### Copiar desde el servidor remoto a local

```bash
scp user@server:~/archivo_remoto.txt ./
```

### Ejemplo práctico: Migrar un proyecto

Imagina que quieres migrar tu proyecto Django desde tu laptop al servidor de desarrollo:

```bash
scp -r django-project user@server:/var/www/
```

Asegúrate de tener permisos de escritura en el directorio destino.

## Conclusión

SSH y SCP son herramientas esenciales para trabajar con servidores remotos. La configuración de claves SSH facilita el acceso automatizado y seguro. Practica estos comandos en un entorno de prueba antes de usarlos en producción.
