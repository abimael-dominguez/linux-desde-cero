
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

# Contenedor servidor (expone el puerto 22 para SSH)
docker run -dit --name ubuntu-remote-server -p 2222:22 ubuntu:latest
```
- `-dit`: modo interactivo, terminal y en background.
- `--name`: nombre del contenedor.
- `-p 2222:22`: mapea el puerto 22 del contenedor al 2222 del host (evita conflictos si el puerto 22 ya está ocupado).

---

## 3. Comandos útiles de Docker

- **Listar contenedores activos:**  
  `docker ps`
- **Listar todos los contenedores:**  
  `docker ps -a`
- **Entrar al bash de un contenedor:**  
  `docker exec -it <nombre_contenedor> bash`
- **Apagar un contenedor:**  
  `docker stop <nombre_contenedor>`
- **Iniciar un contenedor detenido:**  
  `docker start <nombre_contenedor>`
- **Eliminar un contenedor:**  
  `docker rm <nombre_contenedor>`
- **Eliminar todos los contenedores detenidos:**  
  `docker container prune`

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

## 6. Generar y copiar la clave RSA desde el cliente

### En el cliente:

```bash
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
```

### Copia la clave pública al servidor:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub "-p 2222 root@localhost"
```
- Ingresa la contraseña de root cuando la pida.

---

## 7. Transferir archivos con SCP

### Ejemplo de envío de archivo:

```bash
scp -P 2222 /ruta/al/archivo.txt root@localhost:/ruta/destino/
```
- `-P 2222`: especifica el puerto si usaste mapeo.
- `/ruta/al/archivo.txt`: archivo local.
- `/ruta/destino/`: ruta en el servidor.

---

## 8. Solución de problemas comunes

- **Puerto 22 ocupado:** Usa el flag `-p <otro_puerto>:22` al crear el contenedor servidor y el flag `-P <otro_puerto>` en los comandos SSH/SCP.
- **Permiso denegado:** Asegúrate de que root tiene contraseña y que `sshd_config` permite login por contraseña y root.
- **No se conecta:** Verifica que el servicio SSH esté corriendo y que el puerto esté mapeado correctamente.
- **Borrar contenedores:**
  ```bash
  docker stop ubuntu-client ubuntu-remote-server
  docker rm ubuntu-client ubuntu-remote-server
  ```

---

## 9. Resumen de librerías instaladas

- **En ambos:**
  - openssh-client
  - sshpass
  - telnet
  - ftp
- **Solo en el servidor:**
  - openssh-server

---

## 10. Comprobaciones y buenas prácticas

- Verifica la IP del servidor con `hostname -I` o usando `docker inspect`.
- Comprueba que el archivo `/root/.ssh/authorized_keys` existe en el servidor tras copiar la clave.
- Usa usuarios distintos a root para mayor seguridad en entornos reales.
- Puedes crear archivos de prueba con:
  ```bash
  echo "Hola mundo" > /tmp/archivo.txt
  ```

---


---

## Conexión SCP/SSH: ¿localhost y -P o IP interna?

Dependiendo de dónde ejecutes el comando SCP/SSH, cambia la forma de conectarte:

| Escenario                        | Comando ejemplo                                                    |
|-----------------------------------|--------------------------------------------------------------------|
| **Desde el host (con mapeo -p)** | `scp -P 2222 archivo.txt root@localhost:/ruta/destino/`            |
| **Entre dos contenedores**        | `scp archivo.txt root@<IP_DEL_SERVIDOR>:/ruta/destino/`            |

**Notas:**
- El flag `-P` solo es necesario si el puerto SSH es diferente a 22 (por ejemplo, si usas `-p 2222:22` en Docker).
- Entre contenedores en la misma red bridge, usa la IP interna del servidor y el puerto 22 por defecto.
- Puedes obtener la IP del servidor con:
  ```bash
  docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ubuntu-remote-server
  ```
- Si cambias el puerto SSH en el servidor, usa `-P <puerto>` también entre contenedores.

Así, el tutorial es válido para ambos casos: desde el host (localhost y -P) y entre contenedores (IP interna, sin -P).

¡Listo! Ahora tienes un laboratorio funcional para practicar SCP, SSH y gestión de contenedores Docker en tu curso.
