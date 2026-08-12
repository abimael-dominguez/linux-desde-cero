# 03 — Ampliaciones opcionales

Estas actividades se realizan sólo después de completar la conexión básica. Ninguna es requisito para abrir la primera EC2 desde VS Code.

## Índice

- [Qué problema resuelve cada herramienta](#qué-problema-resuelve-cada-herramienta)
- [Comprobar o instalar Docker en la EC2](#comprobar-o-instalar-docker-en-la-ec2)
- [Instalar AWS CLI en la EC2](#instalar-aws-cli-en-la-ec2)

## Qué problema resuelve cada herramienta

| Herramienta y ubicación | Para qué sirve | ¿Necesaria para VS Code? |
|---|---|---:|
| OpenSSH en tu computadora | Conectarte a Ubuntu. | Sí |
| AWS CLI dentro de la EC2 | Aprender comandos AWS desde el servidor; necesita una identidad autorizada. | No |
| Docker dentro de la EC2 | Ejecutar contenedores Linux. | No |

Un entorno virtual de Python no es necesario para ninguna de estas herramientas. Sólo créalo cuando desarrolles un proyecto Python que lo requiera.

## Comprobar o instalar Docker en la EC2

Una AMI personalizada puede traer Docker; el template no lo agrega ni lo elimina. Conecta mediante VS Code o `ssh linux-course` y comprueba primero:

```bash
docker --version
sudo systemctl is-active docker
```

Si ambos comandos funcionan y el servicio aparece `active`, no reinstales nada. Continúa directamente con `docker run --rm hello-world`.

Si `docker` no existe, instala los paquetes de Ubuntu:

```bash
sudo apt update
sudo apt install -y docker.io

if apt-cache show docker-compose-v2 >/dev/null 2>&1; then
  sudo apt install -y docker-compose-v2
else
  sudo apt install -y docker-compose
fi

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Sal de la sesión y vuelve a entrar para actualizar los grupos:

Nota: 
teclear ```exit``` pudiera funcionar, pero algo probado que que funciona es dar ```sudo reboot```, y también reiniciar la instancia en la consola de AWS. Luego volver a reconectarse (veirficar que la DNS pública coincida). 

```bash
# Una vez reiniciada la EC2 comprobar
id
docker --version
docker compose version 2>/dev/null || docker-compose --version
docker run --rm hello-world
```

Ubuntu recientes ofrecen Compose v2 como `docker compose`; versiones anteriores pueden proporcionar `docker-compose`. Para el objetivo introductorio ambos permiten reconocer la herramienta, aunque el curso prioriza la sintaxis moderna cuando esté disponible.

Pertenecer al grupo `docker` concede privilegios elevados sobre el servidor. Hazlo únicamente en la EC2 personal de laboratorio.

## Instalar AWS CLI en la EC2

Instalar el programa `aws` no concede permisos. Para comprobar únicamente su instalación en una EC2 `x86_64`:

```bash
sudo apt update
sudo apt install -y curl unzip
workdir="$(mktemp -d)"
cd "$workdir"
curl -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -q awscliv2.zip
sudo ./aws/install --update
aws --version
cd - >/dev/null
```

No copies el CSV de access keys ni tu carpeta local `~/.aws` a la EC2. Cuando el curso necesite que una aplicación en EC2 consulte AWS, la opción profesional es asignar un **IAM Role** a la instancia con permisos mínimos.
