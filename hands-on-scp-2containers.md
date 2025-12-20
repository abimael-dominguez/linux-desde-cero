# Práctica SCP entre dos contenedores Ubuntu (100% portable)


## Requisitos

- Docker Desktop instalado y funcionando (Windows, Mac o Linux)
- No necesitas OpenSSH en el host, todo se hace dentro de los contenedores Ubuntu

---

# Comandos útiles de Docker

- **Listar contenedores activos:**
   ```bash
   docker ps
   ```
- **Listar todos los contenedores:**
   ```bash
   docker ps -a
   ```
- **Entrar al bash de un contenedor:**
   ```bash
   docker exec -it <nombre_contenedor> bash
   ```
- **Apagar un contenedor:**
   ```bash
   docker stop <nombre_contenedor>
   ```
- **Iniciar un contenedor detenido:**
   ```bash
   docker start <nombre_contenedor>
   ```
- **Eliminar un contenedor:**
   ```bash
   docker rm <nombre_contenedor>
   ```
- **Eliminar todos los contenedores detenidos:**
   ```bash
   docker container prune
   ```

---

## 1. Descargar la imagen de Ubuntu

```bash
docker pull ubuntu:latest
```

---

## 2. Crear y nombrar los contenedores

```bash
# Contenedor cliente
# (No expone puertos, solo se conecta a otros)
docker run -dit --name ubuntu-client ubuntu:latest

# Contenedor servidor (no expone puertos, solo usará la red interna de Docker)
docker run -dit --name ubuntu-remote-server ubuntu:latest
```

---

## 3. Entrar al bash de cada contenedor

```bash
docker exec -it ubuntu-client bash
docker exec -it ubuntu-remote-server bash
```

---

## 4. Instalación de librerías en cada contenedor

### En ambos contenedores (cliente y servidor):

```bash
apt-get update
apt-get install -y openssh-client sshpass telnet ftp
```

### En el servidor (ubuntu-remote-server) instala además el servidor SSH:

```bash
apt-get install -y openssh-server
```

---

## 5. Configuración del servidor SSH

1. **Establece una contraseña para root:**
   ```bash
   passwd
   # Elige una contraseña segura (ejemplo: admin)
   ```

2. **Edita `/etc/ssh/sshd_config` para permitir acceso por contraseña y root:**
   - Descomenta y pon en `yes`:
     ```
     PermitRootLogin yes
     PasswordAuthentication yes
     ```
   - Guarda y cierra el archivo.

3. **Reinicia el servicio SSH:**
   ```bash
   service ssh restart
   ```

4. **Verifica que el servicio esté corriendo:**
   ```bash
   ps aux | grep sshd
   netstat -tuln | grep :22
   ```

---

## 6. Obtener la IP interna del servidor


Puedes obtener la IP interna del servidor de dos formas:

- **Desde el host:**
   ```bash
   docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ubuntu-remote-server
   ```
- **Desde el propio contenedor servidor:**
   ```bash
   hostname -I
   ```

Guarda esa IP, la usarás en el cliente.

---

## 7. Generar y copiar la clave RSA desde el cliente

### En el cliente:

```bash
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
```

### Copia la clave pública al servidor:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub root@<IP_DEL_SERVIDOR>
```
- Ingresa la contraseña de root cuando la pida.

---

## 8. Transferir archivos con SCP (entre contenedores)

### Ejemplo de envío de archivo:

```bash
scp /ruta/al/archivo.txt root@<IP_DEL_SERVIDOR>:/ruta/destino/
```
- `/ruta/al/archivo.txt`: archivo local en el cliente.
- `/ruta/destino/`: ruta en el servidor.

---

## 9. Solución de problemas comunes

- **Permiso denegado:** Asegúrate de que root tiene contraseña y que `sshd_config` permite login por contraseña y root.
- **No se conecta:** Verifica que el servicio SSH esté corriendo y que la IP sea la correcta.
- **Borrar contenedores:**
  ```bash
  docker stop ubuntu-client ubuntu-remote-server
  docker rm ubuntu-client ubuntu-remote-server
  ```

---

## 10. Notas y buenas prácticas

- El puerto 22 no causa conflictos entre contenedores, cada uno tiene su propio espacio de red.
- No necesitas exponer puertos al host para esta práctica.
- Puedes crear archivos de prueba con:
  ```bash
  echo "Hola mundo" > /tmp/archivo.txt
  ```
- Todo el flujo es idéntico en Windows, Mac o Linux si tienes Docker.

---

¡Listo! Así tienes una práctica SCP/SSH 100% portable y sin depender del sistema operativo del host.

---

## Ejercicios extra: FTP y Telnet


### 1. FTP: Transferencia de archivos
**Si tienes problemas de permisos o cambios de usuario, reinicia el servicio FTP:**
```bash
service vsftpd restart
```

**Crea un archivo como usuario admin (no como root):**
```bash
su - admin
echo "Contenido de prueba" > /home/admin/archivo_admin.txt
exit
```

FTP (File Transfer Protocol) es un protocolo clásico para transferir archivos, pero no cifra la información. Aún se encuentra en sistemas antiguos.

**Instala el servidor FTP en el contenedor servidor:**
```bash
apt-get install -y ftp vsftpd
service vsftpd start
```

**Importante:** Por seguridad, vsftpd no permite acceso FTP con el usuario root por defecto.

**Crea un usuario normal para FTP (ejemplo: admin):**
```bash
adduser admin
# Elige una contraseña (ejemplo: admin)
```

**Conéctate desde el cliente:**
```bash
ftp <IP_DEL_SERVIDOR>
```
Cuando te pida usuario y contraseña, usa el usuario normal (ejemplo: admin) y su contraseña.

Comandos útiles dentro de la sesión FTP:
- `ls` — lista archivos
- `get archivo.txt` — descarga archivo
- `put archivo.txt` — sube archivo
- `bye` — salir

> Nota: El usuario y contraseña suelen ser los del sistema (ejemplo: admin y su contraseña). FTP no cifra datos ni credenciales.
> No uses root para FTP, usa siempre un usuario normal.

---

### Ejercicios básicos de FTP: subir y descargar archivos

> Si tienes problemas de permisos, asegúrate de que el archivo fue creado por el usuario admin y que el servicio FTP fue reiniciado tras cualquier cambio de usuario o permisos.


#### Subir un archivo al servidor FTP

Sube el archivo al directorio actual del usuario en el servidor, o especifica la ruta destino:
```
put /ruta/origen/archivo.txt [ruta/destino/archivo.txt]
```
Ejemplo solo origen:
```
put /tmp/archivo.txt
```
Ejemplo origen y destino:
```
put /tmp/archivo.txt archivo_remoto.txt
put /tmp/archivo.txt /home/admin/archivo_remoto.txt
```


#### Descargar (bajar) un archivo del servidor FTP

Descarga el archivo del servidor a una ruta local específica (en una sola línea):
```
get archivo_remoto ruta_local/archivo_local
```
Ejemplo:
```
get /home/admin/archivo_admin.txt /tmp/archivo_admin.txt
```

#### Notas sobre la sintaxis de FTP

- Los comandos `put` y `get` usan la sintaxis:
  ```
  put archivo_local [archivo_remoto]
  get archivo_remoto [archivo_local]
  ```
- El comando `ls` dentro de FTP **muestra archivos en el servidor remoto**.
- Para ver archivos en tu máquina local, sal de FTP y usa `ls` en la terminal, o usa `!ls` si tu cliente FTP lo permite.

---

### 2. Telnet: Acceso remoto a puertos

Telnet permite conectarse a un puerto TCP de un servidor. Es útil para pruebas, pero no cifra nada.

**Ejemplo: Conectarse al puerto SSH del servidor:**
```bash
telnet <IP_DEL_SERVIDOR> 22
```
Verás la respuesta del servicio SSH (banner). Puedes probar otros puertos si tienes servicios corriendo.

**Comando básico:**
- `telnet <host> <puerto>`

> Nota: Telnet no debe usarse para acceso remoto real, solo para pruebas o diagnóstico de puertos.

---

### Ejercicio práctico de Telnet

1. Conéctate al puerto SSH del servidor (22):
   ```
   telnet <IP_DEL_SERVIDOR> 22
   ```
   Deberías ver un mensaje como:
   ```
   Trying <IP_DEL_SERVIDOR>...
   Connected to <IP_DEL_SERVIDOR>.
   Escape character is '^]'.
   SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.10
   ```
   Esto indica que el puerto está abierto y el servicio SSH responde.

2. Puedes probar otros puertos (por ejemplo, 21 para FTP):
   ```
   telnet <IP_DEL_SERVIDOR> 21
   ```
   Si el servicio está activo, verás el banner de FTP.

3. Para salir de telnet, presiona:
   ```
   Ctrl + ]
   quit
   ```

**Notas sobre Telnet:**
- Telnet solo sirve para probar si un puerto está abierto y responde.
- No cifra la información, no se recomienda para acceso real.

---
