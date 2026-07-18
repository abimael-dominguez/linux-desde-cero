# 01 — Crear una EC2 Ubuntu y conectarla con VS Code

Al terminar tendrás una EC2 Ubuntu funcionando y podrás editar sus archivos, abrir una terminal y ejecutar comandos desde VS Code. Esta es la única preparación obligatoria al inicio.

## Índice

- [Resultado esperado](#resultado-esperado)
- [Antes de empezar](#antes-de-empezar)
- [1. Comprueba OpenSSH Client](#1-comprueba-openssh-client)
- [2. Prepara VS Code](#2-prepara-vs-code)
- [3. Crea la EC2 con el template del curso](#3-crea-la-ec2-con-el-template-del-curso)
- [4. Protege la llave privada](#4-protege-la-llave-privada)
- [5. Prueba SSH desde tu computadora](#5-prueba-ssh-desde-tu-computadora)
- [6. Crea el alias linux-course](#6-crea-el-alias-linux-course)
- [7. Conecta VS Code](#7-conecta-vs-code)
- [8. Prepara el repositorio del curso](#8-prepara-el-repositorio-del-curso)
- [Pausa, reanudación y limpieza](#pausa-reanudación-y-limpieza)
- [Problemas frecuentes](#problemas-frecuentes)

## Resultado esperado

La práctica está terminada cuando puedas mostrar estas cuatro evidencias:

- el stack aparece como **CREATE_COMPLETE** y la instancia pasa sus checks `2/2`;
- `ssh linux-course` abre una terminal con el usuario `ubuntu`;
- VS Code muestra `SSH: linux-course` en la esquina inferior izquierda;
- una terminal de VS Code responde `ubuntu` al ejecutar `whoami`.

## Antes de empezar

Necesitas:

- acceso autorizado a la consola web de AWS;
- una computadora con Linux o Windows 10/11;
- VS Code;
- aproximadamente 20 minutos.

No instales AWS CLI ni crees access keys para esta ruta. La consola web basta. Si la cuenta es tuya, activa MFA; para trabajo cotidiano AWS recomienda una identidad administrativa distinta del usuario root. Nunca crees access keys para root. [Buenas prácticas oficiales de AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html).

Usaremos estos nombres durante toda la guía:

| Elemento | Nombre |
|---|---|
| Stack de CloudFormation | `linux-course-main` |
| EC2 | `linux-course` |
| Key Pair | `linux-course-key` |
| Llave local | `linux-course-key.pem` |
| Alias SSH | `linux-course` |
| Usuario de Ubuntu | `ubuntu` |

## 1. Comprueba OpenSSH Client

VS Code Remote-SSH necesita un cliente OpenSSH en tu computadora. La extensión no lo reemplaza.

### Si tu computadora usa Linux

Abre una terminal local y ejecuta:

```bash
ssh -V
```

Si aparece `command not found`, instálalo en Ubuntu o Debian:

```bash
sudo apt update
sudo apt install -y openssh-client
```

### Si tu computadora usa Windows

Abre **PowerShell** y ejecuta:

```powershell
ssh -V
```

Si el comando no existe, abre PowerShell **como administrador** e instala sólo el cliente:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

Cierra esa ventana, abre una PowerShell normal y repite `ssh -V`. No necesitas instalar OpenSSH Server en Windows: la EC2 será el servidor. [Instalación oficial de OpenSSH en Windows](https://learn.microsoft.com/windows-server/administration/openssh/openssh_install_firstuse).

## 2. Prepara VS Code

Instala [Visual Studio Code](https://code.visualstudio.com/download). Después abre **Extensions** con `Ctrl+Shift+X`, busca **Remote - SSH** de Microsoft e instálala.

Si el comando `code` está disponible en tu terminal, la alternativa es:

```bash
code --install-extension ms-vscode-remote.remote-ssh
```

Todavía no intentes conectarte: primero necesitamos una EC2 y una llave.

## 3. Crea la EC2 con el template del curso

Este paso usa [`setup-templates/2-ec2-ubuntu/ec2-ubuntu-ssh.yml`](../../setup-templates/2-ec2-ubuntu/ec2-ubuntu-ssh.yml). El template crea la EC2 y su red; tú sólo proporcionas el Key Pair, la AMI y la IP autorizada. No necesitas comprender CloudFormation ni instalar AWS CLI para completar el curso.

Entra a la [consola de AWS](https://console.aws.amazon.com/) y sigue el orden indicado.

### 3.1 Elige una región

En la esquina superior derecha selecciona una región y no la cambies durante la práctica. El ejemplo del curso usa **US East (N. Virginia) — `us-east-1`**.

La región importa: una AMI, un Key Pair y una EC2 pertenecen a una región concreta.

### 3.2 Crea primero el Key Pair

Abre **EC2 → Network & Security → Key Pairs → Create key pair**:

- nombre: `linux-course-key`;
- tipo: **RSA**;
- formato: **.pem**.

Selecciona **Create key pair**. El navegador descargará `linux-course-key.pem` una sola vez. Déjalo por ahora en Downloads; lo protegeremos en el paso 4.

El nombre del Key Pair existe dentro de una región. Si cambias de región, el template no podrá encontrarlo.

### 3.3 Copia la AMI de Ubuntu

Abre **EC2 → Instances → Launch instances**, pero no lances una instancia. Usa el selector sólo para consultar la imagen:

1. En **Application and OS Images** elige **Ubuntu**.
2. Confirma **Ubuntu Server LTS**, publicador **Canonical** y arquitectura **64-bit (x86)**.
3. Confirma que AWS la marque **Free tier eligible**.
4. Copia el **AMI ID**, con forma `ami-0123456789abcdef0`.
5. Cierra el asistente sin seleccionar **Launch instance**.

Si el instructor proporciona una AMI propia basada en Ubuntu, puede usarse aunque su propietario ya no aparezca como Canonical. El instructor debe haber verificado arquitectura `x86_64`, usuario `ubuntu`, `cloud-init`, OpenSSH Server, ausencia de cargos de Marketplace y **Delete on termination** para el disco raíz. No copies el ID de una captura antigua: los AMI ID cambian entre regiones y versiones.

### 3.4 Obtén la IP autorizada

Desde la computadora que usará VS Code abre [checkip.amazonaws.com](https://checkip.amazonaws.com/). Verás una IPv4, por ejemplo:

```text
203.0.113.10
```

Para el parámetro de CloudFormation agrega `/32`:

```text
203.0.113.10/32
```

No uses `0.0.0.0/0`: permitiría intentos de SSH desde cualquier dirección de Internet.

### 3.5 Carga el template en CloudFormation

Descarga o localiza el archivo [`ec2-ubuntu-ssh.yml`](../../setup-templates/2-ec2-ubuntu/ec2-ubuntu-ssh.yml). En AWS abre **CloudFormation → Stacks → Create stack → With new resources (standard)**:

1. En **Prepare template** elige **Choose an existing template**.
2. En **Specify template** elige **Upload a template file**.
3. Selecciona `setup-templates/2-ec2-ubuntu/ec2-ubuntu-ssh.yml`.
4. Selecciona **Next**.
5. Stack name: `linux-course-main`.

Completa los parámetros:

| Parámetro | Valor del curso |
|---|---|
| `ProjectName` | `linux-course` |
| `UbuntuAmiId` | el `ami-...` copiado en 3.3 |
| `UbuntuInstanceType` | `t3.micro` |
| `UbuntuKeyName` | `linux-course-key` |
| `SshAllowedCidr` | tu IPv4 con `/32` |
| `VpcCidr` | conserva `10.10.0.0/16` |
| `PublicSubnetCidr` | conserva `10.10.1.0/24` |

Selecciona **Next**, conserva las opciones predeterminadas, vuelve a seleccionar **Next** y finalmente **Submit**. El template no solicita capabilities IAM.

> **Free Tier.** El template fija `t3.micro` porque AWS lo incluye entre los tipos marcados como elegibles tanto en el programa anterior como en el actual. Aun así, antes de enviar confirma en tu consola que `t3.micro` y la AMI aparecen como **Free tier eligible**: la plantilla no puede conocer la antigüedad, el plan, los créditos ni el consumo de tu cuenta. Consulta [la tabla vigente de AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html).

### 3.6 Espera y lee los Outputs

En **CloudFormation → Stacks → linux-course-main**, observa **Events** hasta que el estado sea:

```text
CREATE_COMPLETE
```

Abre la pestaña **Outputs** y copia `PublicIp`, `PublicDnsName` y `InstanceId`. Luego abre **EC2 → Instances**, selecciona ese `InstanceId` y espera **2/2 status checks passed**.

La red, el Security Group y la EC2 se administran desde el stack. El disco raíz nace con la instancia y se elimina con ella si la AMI tiene activo **Delete on termination**, condición que debes revisar al elegir la imagen.

## 4. Protege la llave privada

La llave permite entrar a la EC2. Debe quedarse únicamente en tu computadora.

### Linux

```bash
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
mv "$HOME/Downloads/linux-course-key.pem" "$HOME/.ssh/linux-course-key.pem"
chmod 400 "$HOME/.ssh/linux-course-key.pem"
ls -l "$HOME/.ssh/linux-course-key.pem"
```

Si el navegador cambió el nombre o la carpeta de descarga, ajusta sólo la ruta de origen del comando `mv`.

### Windows

Abre PowerShell normal:

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\.ssh" | Out-Null
Move-Item "$HOME\Downloads\linux-course-key.pem" "$HOME\.ssh\linux-course-key.pem"
icacls "$HOME\.ssh\linux-course-key.pem" /inheritance:r
icacls "$HOME\.ssh\linux-course-key.pem" /grant:r "${env:USERNAME}:(R)"
```

Si el archivo se descargó con otro nombre, ajusta la primera ruta de `Move-Item`.

## 5. Prueba SSH desde tu computadora

Selecciona la instancia en AWS y abre **Connect → SSH client**. Esa pestaña y los Outputs del stack muestran el usuario, DNS e IP de la instancia. Después haz la conexión desde una terminal **local**, no desde la terminal del navegador.

### Linux

```bash
PUBLIC_IP="203.0.113.10"  # Sustituye por la Public IPv4 real
ssh -i "$HOME/.ssh/linux-course-key.pem" "ubuntu@$PUBLIC_IP"
```

### Windows PowerShell

```powershell
$PUBLIC_IP="203.0.113.10"  # Sustituye por la Public IPv4 real
ssh -i "$HOME\.ssh\linux-course-key.pem" "ubuntu@$PUBLIC_IP"
```

En la primera conexión aparecerá un mensaje sobre la autenticidad del host. Confirma primero que la IP del mensaje sea la misma que copiaste de AWS; después escribe `yes`.

Ya dentro de Ubuntu ejecuta:

```bash
whoami
hostname
pwd
cat /etc/os-release
```

Salida representativa:

```text
ubuntu
ip-10-0-...
/home/ubuntu
PRETTY_NAME="Ubuntu ..."
```

Los valores exactos pueden variar. Escribe `exit` para volver a tu computadora.

## 6. Crea el alias linux-course

El alias evita repetir IP, usuario y ruta de la llave. En VS Code abre el archivo local correspondiente:

- Linux: `~/.ssh/config`
- Windows: `C:\Users\TU_USUARIO\.ssh\config`

No confundas las dos direcciones utilizadas durante el despliegue:

- `SshAllowedCidr`: IP pública de **tu computadora**, terminada en `/32`; autoriza desde dónde puedes conectarte.
- `HostName`: IP pública o DNS público de la **EC2 remota** `linux-course`, sin `/32`; indica a qué servidor debe conectarse SSH.

Si el archivo no existe, créalo como texto **sin extensión**. En el siguiente bloque, `203.0.113.10` es una dirección ficticia reservada para documentación:

```text
Host linux-course
  HostName 203.0.113.10
  User ubuntu
  IdentityFile ~/.ssh/linux-course-key.pem
  IdentitiesOnly yes
  ServerAliveInterval 30
```

Sustituye `203.0.113.10` por la **Public IPv4 address actual de la EC2** que aparece en **EC2 → Instances → linux-course**. No uses la IP de tu computadora ni agregues `/32`. En Linux protege el archivo:

```bash
chmod 600 "$HOME/.ssh/config"
```

Prueba el alias desde la terminal local:

```bash
ssh linux-course
```

Si funciona, escribe `exit`. A partir de ahora la terminal y VS Code usarán la misma configuración.

## 7. Conecta VS Code

1. Abre VS Code en tu computadora.
2. Abre la paleta con `Ctrl+Shift+P`.
3. Selecciona **Remote-SSH: Connect to Host...**.
4. Elige `linux-course`.
5. Si pregunta por el sistema remoto, selecciona **Linux**.
6. Espera la primera instalación de VS Code Server.
7. Selecciona **File → Open Folder...** y abre `/home/ubuntu`.
8. Abre **Terminal → New Terminal**.

Comprueba el contexto:

```bash
whoami
pwd
hostname
```

Debes ver `ubuntu` y una ruta remota. La esquina inferior izquierda debe mostrar `SSH: linux-course`.

> **Local o remoto.** Cuando la ventana muestra `SSH: linux-course`, sus terminales nuevas se ejecutan dentro de la EC2. Para comandos sobre archivos de tu computadora, abre otra ventana local de VS Code, una terminal Linux local o PowerShell.

## 8. Prepara el repositorio del curso

Desde la terminal **remota** de VS Code:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/abimael-dominguez/linux-desde-cero.git
cd linux-desde-cero
```

Después selecciona **File → Open Folder...** y abre `/home/ubuntu/linux-desde-cero`.

Si la carpeta ya existe, no vuelvas a clonarla ni la borres. Entra con `cd /home/ubuntu/linux-desde-cero`, ejecuta `git status` y abre esa misma ruta en VS Code.

Docker y AWS CLI pueden instalarse más adelante desde [03 — Opcionales](../03-opcionales/README.md). No son requisitos para completar esta conexión.

## Pausa, reanudación y limpieza

Cerrar VS Code o ejecutar `exit` sólo cierra la conexión; la EC2 sigue encendida.

- **Stop instance**: conserva la EC2 y su disco para otra clase. El disco puede seguir generando costo y la IP pública normalmente cambiará al volver a iniciarla.
- **Start instance**: inicia una EC2 detenida. Copia la nueva Public IPv4 desde EC2 y actualiza `HostName` en `~/.ssh/config`.
- **Delete stack**: elimina la EC2 y la red administradas por el template; el disco raíz se elimina si su mapping tiene activo **Delete on termination**.

Para terminar definitivamente: **CloudFormation → Stacks → linux-course-main → Delete**. Confirma y espera `DELETE_COMPLETE`. No termines sólo la instancia desde EC2: el stack conservaría otros recursos y quedaría inconsistente. Después revisa **EC2 → Volumes** y confirma que no haya un volumen `available` del laboratorio. El Key Pair se creó fuera del stack; elimínalo manualmente sólo cuando ya no se utilizará.

## Problemas frecuentes

| Síntoma | Qué revisar |
|---|---|
| `Permission denied (publickey)` | Usuario `ubuntu`, llave correcta y Key Pair usado al crear la EC2. |
| `UNPROTECTED PRIVATE KEY FILE` | Linux: `chmod 400 ~/.ssh/linux-course-key.pem`. Windows: repite los dos comandos `icacls`. |
| Timeout | Estado `Running`, checks `2/2`, IP correcta y regla SSH desde tu IP actual. |
| Cambió tu red | Actualiza el stack `linux-course-main` y cambia únicamente `SshAllowedCidr` por tu nueva IPv4 `/32`. |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | Confirma que la EC2 fue reemplazada o cambió la IP; elimina únicamente esa entrada con `ssh-keygen -R <IP>`. |
| VS Code no conecta | Primero logra que `ssh linux-course` funcione; después revisa **View → Output → Remote - SSH**. |
| Perdiste la `.pem` | AWS no permite descargarla otra vez. Elimina el stack, crea otro Key Pair y vuelve a desplegarlo. |
| `CREATE_FAILED` | Abre **Events** y lee el primer error. Revisa que AMI y Key Pair pertenezcan a la misma región del stack. |

VS Code documenta que Remote-SSH requiere un cliente OpenSSH local y que instala VS Code Server automáticamente en el host remoto. [Documentación oficial](https://code.visualstudio.com/docs/remote/ssh).
