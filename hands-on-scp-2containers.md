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
   # Elige una contraseña segura (ejemplo: 1234)
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
