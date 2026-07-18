# Prerrequisitos — Ubuntu 24.04 en AWS EC2

Esta preparación debe completarse **antes** de la primera clase. En clase se usarán Linux y SSH; no se dedicará tiempo a crear cuentas, configurar AWS CLI o diseñar una VPC.

## Índice

- [Objetivo de verificación](#objetivo-de-verificación)
- [1. Cliente SSH](#1-cliente-ssh)
- [2. Crear la instancia](#2-crear-la-instancia)
- [3. Proteger la clave y conectar](#3-proteger-la-clave-y-conectar)
- [4. Comprobación resuelta](#4-comprobación-resuelta)
- [5. Problemas frecuentes](#5-problemas-frecuentes)
- [6. Costos y limpieza](#6-costos-y-limpieza)
- [Checklist](#checklist)

## Objetivo de verificación

La conexión necesita tres datos:

| Dato | Ejemplo | Significado |
|---|---|---|
| Clave privada | `~/.ssh/curso-linux.pem` | archivo `.pem` descargado al crear la instancia |
| Usuario remoto | `ubuntu` | usuario predeterminado de Ubuntu Server en EC2 |
| IP pública | diferente para cada instancia | valor “Public IPv4 address” de la consola EC2 |

Sintaxis general:

```bash
ssh -i <ruta_clave> <usuario>@<IP_PUBLICA>
```

No escribas los marcadores `<...>` literalmente. Antes del curso debes poder ejecutar el equivalente con tus datos reales.

Y, dentro de la instancia:

```bash
whoami
cat /etc/os-release
uname -r
```

## 1. Cliente SSH

### Windows 10/11

Abre PowerShell y verifica:

```powershell
ssh -V
```

Si el comando no existe, abre PowerShell como administrador:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

WSL 2 con Ubuntu también es una alternativa válida.

### macOS o Linux

SSH normalmente ya está instalado:

```bash
ssh -V
```

## 2. Crear la instancia

En la consola de EC2:

1. Crea una instancia con **Ubuntu Server 24.04 LTS**.
2. Selecciona un tipo pequeño apto para laboratorio.
3. Usa entre 8 y 10 GiB de almacenamiento.
4. Crea un par de claves y descarga el archivo `.pem` una sola vez.
5. Permite tráfico SSH al puerto 22 únicamente desde tu IP pública.
6. Anota la IP pública y el usuario `ubuntu`.

En el selector de origen de la regla SSH elige **My IP**. No uses `0.0.0.0/0`, porque permitiría intentos de conexión desde cualquier dirección de Internet.

En la vista de la instancia busca **Public IPv4 address**. No uses la IP privada `10.x.x.x`, porque normalmente no es alcanzable directamente desde tu computadora.

No subas la clave privada al repositorio, correo, chat o almacenamiento público.

## 3. Proteger la clave y conectar

En macOS, Linux o WSL:

1. Primero localiza el nombre exacto descargado:

   ```bash
   ls -l ~/Downloads/*.pem
   ```

2. En el ejemplo suponemos que se llama `curso-linux.pem`. Si tiene otro nombre, sustitúyelo en los comandos.

```bash
mkdir -p ~/.ssh
mv ~/Downloads/curso-linux.pem ~/.ssh/
chmod 400 ~/.ssh/curso-linux.pem
```

3. Guarda tus valores en variables. Sustituye la IP de documentación por la IP pública real:

```bash
CLAVE="$HOME/.ssh/curso-linux.pem"
USUARIO_REMOTO="ubuntu"
IP_PUBLICA="203.0.113.10"  # Sustituye este valor

ssh -i "$CLAVE" "${USUARIO_REMOTO}@${IP_PUBLICA}"
```

`203.0.113.10` no es una instancia real; es una dirección reservada para ejemplos. Si dejas ese valor, la conexión no funcionará.

En PowerShell nativo, conserva la clave en una ruta conocida y usa el mismo usuario/IP:

```powershell
$Key = "$HOME\Downloads\curso-linux.pem"
$Ip = "203.0.113.10" # Sustituye por la IP real
ssh -i $Key "ubuntu@$Ip"
```

La primera conexión muestra una huella parecida a esta:

```text
The authenticity of host '...' can't be established.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Verifica que el host y la IP sean los esperados antes de responder `yes`.

## 4. Comprobación resuelta

Ejecuta en la instancia:

```bash
whoami
hostname
cat /etc/os-release
pwd
sudo -v
```

Salida representativa:

```text
ubuntu
ip-10-0-1-25
PRETTY_NAME="Ubuntu 24.04.x LTS"
/home/ubuntu
```

- `ubuntu` es el usuario de la AMI.
- El hostname depende de la dirección privada asignada.
- `sudo -v` valida privilegios administrativos sin abrir una sesión de `root`.

## 5. Problemas frecuentes

| Problema | Revisión |
|---|---|
| `Permission denied (publickey)` | Usuario, ruta de la clave y par asociado a la instancia. |
| `UNPROTECTED PRIVATE KEY FILE` | Ejecuta `chmod 400 ~/.ssh/curso-linux.pem`. |
| Timeout | Estado de EC2, IP pública, regla del puerto 22 e IP de origen. |
| La huella cambió | No la aceptes automáticamente; confirma si la instancia fue reemplazada. |

Para ver más detalle:

```bash
ssh -vv -i "$CLAVE" "${USUARIO_REMOTO}@${IP_PUBLICA}"
```

Este comando presupone que definiste las tres variables en la misma terminal. `-vv` muestra decisiones de conexión y autenticación, pero no imprime el contenido de la clave privada.

## 6. Costos y limpieza

- Usa la instancia sólo durante las prácticas.
- Detener una instancia no elimina necesariamente su almacenamiento.
- Al terminar el curso, descarga lo necesario y **termina** la instancia.
- Revisa que no queden volúmenes, snapshots o direcciones reservadas que no necesitas.

## Checklist

- [ ] `ssh -V` funciona en mi computadora.
- [ ] Guardé la clave fuera del repositorio.
- [ ] El puerto 22 está limitado a mi IP.
- [ ] Puedo entrar como `ubuntu`.
- [ ] Confirmé Ubuntu 24.04 LTS.
- [ ] Sé cómo detener y terminar la instancia.
