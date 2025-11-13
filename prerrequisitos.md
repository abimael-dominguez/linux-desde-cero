# Prerrequisitos para el Curso de Linux

Este documento contiene los prerrequisitos que deben instalar y configurar los alumnos antes del inicio del curso. El objetivo es poder probar comandos de Linux en diferentes sistemas operativos utilizando Docker y AWS.

## 1. Instalación de Docker

Docker nos permitirá ejecutar contenedores Linux en cualquier sistema operativo, facilitando la práctica de comandos Linux. Asegúrate de poder ejecutar un contenedor de prueba antes del curso.

### Instalación en Windows (10 y 11)

1. **Requisitos del sistema:**
   - Windows 10 64-bit (versión 2004 o superior) o Windows 11.
   - Ediciones: Home, Pro, Enterprise o Education.
   - Virtualización habilitada en BIOS (Intel VT-x / AMD-V).
   - Habilitar WSL 2 y la característica "Virtual Machine Platform".

2. **Habilitar WSL 2 (método rápido Windows 11 / builds recientes):**
   Abrir PowerShell como administrador:
   ```powershell
   wsl --install
   ```
   Esto instala WSL y una distro Ubuntu por defecto. Reinicia si lo solicita.

   **Si el comando anterior falla (build antigua):**
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   wsl --set-default-version 2
   ```
   Luego instala Ubuntu desde Microsoft Store.

3. **Descargar Docker Desktop:**
   - [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Descargar instalador para Windows.

4. **Instalar Docker Desktop:**
   - Ejecutar instalador.
   - Aceptar uso de WSL 2 (marcar "Use WSL 2 instead of Hyper-V" si aparece).
   - Finalizar y abrir Docker Desktop (esperar a que diga "Docker is running").

5. **Verificar versión y probar contenedor:**
   Abrir PowerShell:
   ```powershell
   docker --version
   docker run --rm hello-world
   ```
   Debes ver el mensaje de bienvenida de Docker.

6. **(Opcional) Comprobar distro WSL:**
   ```powershell
   wsl -l -v
   ```
   Asegura que la distro usada (Ubuntu) esté en versión 2.

### Instalación en Linux (Ubuntu)
1. Seguir el siguiente tutorial
    - https://www.datacamp.com/tutorial/install-docker-on-ubuntu

### Instalación en macOS (Solo si algún alumno usa Mac)
1. Descargar Docker Desktop para macOS (Apple Silicon o Intel según modelo).
2. Instalar y abrir la aplicación.
3. Probar:
   ```bash
   docker run --rm hello-world
   ```

### Comandos básicos para validar entorno Docker
```bash
docker ps               # Contenedores en ejecución
docker images           # Imágenes locales
docker pull alpine      # Descarga imagen ligera
docker run -it --rm alpine sh   # Abre shell busybox/alpine
```

## 2. Creación de Cuenta AWS

AWS (Amazon Web Services) nos permitirá crear instancias virtuales Linux en la nube para practicar comandos en entornos reales.

1. **Ir al sitio web de AWS:**
   - Visitar [https://aws.amazon.com](https://aws.amazon.com).

2. **Crear una cuenta gratuita:**
   - Hacer clic en "Crear una cuenta AWS".
   - Seleccionar "Cuenta personal".
   - Ingresar información personal: nombre, email, contraseña.

3. **Verificar la cuenta:**
   - AWS enviará un código de verificación al email proporcionado.
   - Ingresar el código para verificar.

4. **Configurar método de pago:**
   - Ingresar información de tarjeta de crédito o débito (requerida, pero no se cobrará si se usa solo el nivel gratuito).

5. **Verificar identidad:**
   - Confirmar número de teléfono mediante llamada o SMS.

6. **Seleccionar plan:**
   - Elegir el plan gratuito (Free Tier) que incluye 750 horas de EC2 al mes durante 12 meses.

7. **Acceder a la consola:**
   - Una vez creada la cuenta, iniciar sesión en la consola de AWS en [https://console.aws.amazon.com](https://console.aws.amazon.com).

**Nota:** AWS ofrece un nivel gratuito generoso, pero asegúrate de monitorear el uso para evitar cargos inesperados.

## 3. Instalación y Configuración de AWS CLI

Instalar la AWS CLI permite gestionar instancias y otros servicios desde la terminal.

### Windows (PowerShell)
```powershell
winget install -e --id Amazon.AWSCLI
aws --version
```

### Linux (x86_64)
```bash
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install
aws --version
```
(Para ARM64 sustituir URL por `linux-aarch64`.)

### Configurar credenciales
Tras crear la cuenta y generar un usuario IAM (recomendado en vez de usar root):
1. En la consola AWS: IAM > Usuarios > Agregar usuario (Acceso programático + consola si requiere). 
2. Adjuntar política inicial: `AdministratorAccess` (solo durante aprendizaje) o una más restringida.
3. Guardar Access Key ID y Secret Access Key.
4. Configurar:
   ```bash
   aws configure
   ```
   Ingresa: Access Key, Secret, Región (ej: `us-east-1`), Formato salida (`json`).

### Verificar conexión API
```bash
aws sts get-caller-identity
```
Debe devolver ARN del usuario.

## 4. Inicialización de Terminal en Instancias AWS

Una vez creada la cuenta AWS, podremos lanzar instancias EC2 (máquinas virtuales) con diferentes distribuciones Linux y conectar a ellas vía terminal SSH.

### Crear una Instancia EC2

1. **Acceder a la consola EC2:**
   - En la consola AWS, buscar "EC2" y hacer clic en "Instancias".

2. **Lanzar instancia:**
   - Hacer clic en "Launch instance".
   - Asignar un Nombre (Tag) ej: `linux-practica-ubuntu`.
   - Elegir una AMI (Amazon Machine Image):
     - Ubuntu Server (última versión LTS)
     - Amazon Linux 2
     - CentOS, etc.

3. **Seleccionar tipo de instancia:**
   - Elegir `t2.micro` o `t3.micro` (ambos suelen estar en Free Tier según región).

4. **Configurar detalles:**
   - Dejar configuraciones por defecto.

5. **Agregar almacenamiento:**
   - 8 GB es suficiente para pruebas.

6. **Configurar grupo de seguridad:**
   - Regla SSH puerto 22 (Origen: "My IP" preferido). Evita 0.0.0.0/0 salvo pruebas controladas.
   - (Opcional) Agregar ICMP (ping) solo desde tu IP si deseas probar conectividad.

7. **Revisar y lanzar:**
   - Hacer clic en "Launch instance".
   - Crear o seleccionar un par de claves (Key pair) tipo RSA.
   - Descargar el archivo `.pem` y guardarlo con nombre claro: `curso-linux-ubuntu.pem`.

### (Opcional) Listar instancias vía AWS CLI
```bash
aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`]|[0].Value,State:State.Name,PublicIP:PublicIpAddress}' --output table
```

### Conectar a la Instancia vía SSH

1. **Cambiar permisos de la clave:**
   ```
   chmod 400 ruta/a/tu/clave.pem
   ```

2. **Conectar usando SSH:**
    Obtener la IP pública desde la consola (o con AWS CLI). Ejemplos:
    ```bash
    ssh -i ruta/a/curso-linux-ubuntu.pem ubuntu@IP_PUBLICA
    ssh -i ruta/a/curso-linux-amazon.pem ec2-user@IP_PUBLICA
    ssh -i ruta/a/curso-linux-centos.pem centos@IP_PUBLICA
    ```
    Si aparece advertencia de permisos inseguros, confirma que el archivo está con `chmod 400`.

    **(Opcional) Archivo de configuración `~/.ssh/config`:**
    ```bash
    Host curso-ubuntu
       HostName IP_PUBLICA
       User ubuntu
       IdentityFile ~/ruta/a/curso-linux-ubuntu.pem
    Host curso-amazon
       HostName IP_PUBLICA
       User ec2-user
       IdentityFile ~/ruta/a/curso-linux-amazon.pem
    ```
    Luego simplemente: `ssh curso-ubuntu`.

3. **Inicializar la terminal (pruebas básicas):**
   ```bash
   whoami
   uname -a
   cat /etc/os-release
   ls -al
   pwd
   ```
   Verifica distro, usuario y permisos.

4. **Actualización inicial (Ubuntu/Debian):**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
   Para Amazon Linux:
   ```bash
   sudo dnf update -y   # En Amazon Linux 2023
   ```
   Para Amazon Linux 2:
   ```bash
   sudo yum update -y
   ```

### Pruebas en Diferentes Distribuciones

- Repite el proceso de lanzamiento de instancia para diferentes AMIs (Ubuntu, Amazon Linux, CentOS, etc.).
- Conecta a cada una y practica comandos Linux específicos de cada distribución.

**Importante:** Detén (Stop) o termina (Terminate) las instancias cuando acabes. Instancias detenidas aún conservan volúmenes (EBS) y pueden generar coste mínimo por almacenamiento. Terminar elimina el volumen.

### Limpieza de recursos (AWS CLI ejemplar)
Detener una instancia:
```bash
aws ec2 stop-instances --instance-ids i-XXXXXXXXXXXX
```
Terminar una instancia:
```bash
aws ec2 terminate-instances --instance-ids i-XXXXXXXXXXXX
```
Ver estados hasta que quede `stopped` o `terminated`:
```bash
aws ec2 describe-instances --instance-ids i-XXXXXXXXXXXX --query 'Reservations[].Instances[].State.Name' --output text
```

## 5. Resumen Rápido de Verificación Antes del Curso
Cada alumno debe poder ejecutar sin error:
```bash
docker run --rm hello-world
aws sts get-caller-identity
ssh -V
``` 
Y conectarse a al menos una instancia EC2 Ubuntu y ejecutar `cat /etc/os-release`.

## 6. Checklist de Problemas Comunes
- Docker no inicia en Windows: verificar que WSL versión sea 2 (`wsl -l -v`) y Virtualización habilitada.
- Permisos clave SSH: usar `chmod 400 archivo.pem`.
- AWS CLI sin credenciales: ejecutar `aws configure` o revisar `~/.aws/credentials`.
- Conexión rechazada (SSH): revisar grupo de seguridad puerto 22 y IP de origen.
- Docker sin permisos en Linux: usuario no pertenece al grupo `docker`.

Si tienes problemas durante la instalación o configuración, por favor contacta al instructor antes del inicio del curso.

Si tienes problemas durante la instalación o configuración, por favor contacta al instructor antes del inicio del curso.