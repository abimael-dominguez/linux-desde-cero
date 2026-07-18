# Prerrequisitos — EC2 y VS Code

Antes de la primera clase completa únicamente [Crear una EC2 Ubuntu y conectarla con VS Code](infraestructura-aws/01-ec2-y-vscode/README.md).

## Índice

- [Qué debes instalar](#qué-debes-instalar)
- [Qué no necesitas todavía](#qué-no-necesitas-todavía)
- [Comprobación mínima](#comprobación-mínima)
- [Si no puedes usar AWS](#si-no-puedes-usar-aws)

## Qué debes instalar

- VS Code.
- Extensión **Remote - SSH**.
- OpenSSH Client en tu computadora Linux o Windows.
- El template `setup-templates/2-ec2-ubuntu/ec2-ubuntu-ssh.yml` cargado desde la consola web de CloudFormation.

## Qué no necesitas todavía

- AWS CLI local ni perfil `~/.aws`.
- Access keys o CSV de credenciales.
- Conocimientos previos de CloudFormation; sólo cargarás el template proporcionado.
- Docker.
- Entorno virtual de Python.
- Una segunda EC2.
- Practicar SCP o SFTP antes de que el curso llegue a ese tema.

## Comprobación mínima

Desde una terminal local debe funcionar:

```bash
ssh linux-course 'whoami && cat /etc/os-release'
```

La salida debe mostrar `ubuntu` y una versión de Ubuntu. Después abre VS Code mediante **Remote-SSH: Connect to Host... → linux-course** y comprueba que la esquina inferior izquierda muestre `SSH: linux-course`.

Eso es suficiente para comenzar. La ruta de SSH/SCP y la automatización se incorporan después desde [infraestructura-aws/](infraestructura-aws/README.md).

## Si no puedes usar AWS

El curso puede continuar en una VM local, WSL o Multipass. Avísalo al instructor antes de la Clase 1 para adaptar la práctica remota sin compartir cuentas, llaves ni contraseñas.
