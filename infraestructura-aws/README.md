# Laboratorio remoto en AWS

El objetivo inicial es sencillo: cargar el template Ubuntu del curso desde la consola de CloudFormation y abrir la EC2 resultante con VS Code. No necesitas AWS CLI, access keys, Python ni una segunda EC2.

## Índice

- [Ruta del curso](#ruta-del-curso)
- [Modelo mental](#modelo-mental)
- [Qué necesitas ahora](#qué-necesitas-ahora)
- [Una EC2 o dos](#una-ec2-o-dos)
- [Seguridad y costo](#seguridad-y-costo)

## Ruta del curso

Sigue sólo el material que corresponda al momento del curso:

| Momento | Material | Resultado |
|---|---|---|
| Preparación inicial | [01 — Crear una EC2 y conectarla con VS Code](01-ec2-y-vscode/README.md) | Una terminal y una carpeta de Ubuntu abiertas desde VS Code. |
| Clase de SSH/SCP | [02 — Práctica SSH, SCP y SFTP](02-practica-ssh/README.md) | Practicar desde tu computadora y, si el repositorio vive en EC2, preparar el destino `linux-target`. |
| Cuando el temario lo requiera | [03 — Opcionales](03-opcionales/README.md) | Instalar Docker o AWS CLI dentro de Ubuntu. |

La única ruta obligatoria antes de comenzar el curso es la **01**. No adelantes las demás si todavía no puedes conectarte con VS Code.

## Modelo mental

```text
Tu computadora                         AWS
┌─────────────────────────┐           ┌────────────────────┐
│ VS Code                 │           │ EC2 Ubuntu         │
│ OpenSSH Client          │── SSH ──► │ OpenSSH Server     │
│ llave privada A (.pem)  │           │ usuario: ubuntu    │
└─────────────────────────┘           └────────────────────┘
```

Tu computadora es el **cliente**. La EC2 es el **servidor Linux**. Remote-SSH usa el cliente OpenSSH instalado en tu computadora y coloca automáticamente VS Code Server en Ubuntu durante la primera conexión.

## Qué necesitas ahora

| Componente | ¿Ahora? | Motivo |
|---|---:|---|
| Acceso a la consola de AWS | Sí | Crear, consultar y terminar la EC2. |
| VS Code y extensión Remote - SSH | Sí | Trabajar sobre Ubuntu desde tu editor local. |
| OpenSSH Client local | Sí | Es la conexión que usa tanto la terminal como VS Code. |
| AWS CLI local | No | Sólo hace falta para automatizar AWS posteriormente. |
| Access keys y perfil `~/.aws` | No | La ruta inicial usa la consola web. |
| Estudiar CloudFormation | No | Sólo cargas el template proporcionado y completas sus parámetros. |
| Entorno virtual de Python | No | No participa en EC2, SSH ni Remote-SSH. |
| Docker y AWS CLI dentro de Ubuntu | Después | Se instalan cuando el curso realmente los necesite. |

## Una EC2 o dos

Para aprender la conexión básica basta una EC2: tu computadora ya cumple el papel de cliente SSH. Esto también funciona si tu computadora usa Windows, porque Windows 10/11 ofrece OpenSSH Client y sus comandos `ssh`, `scp` y `sftp`.

Si todo el repositorio del curso vive dentro de la primera EC2, una segunda sirve como destino real para practicar transferencias Linux a Linux. Agrega otro stack, una llave y limpieza, así que se prepara sólo al llegar a esa práctica mediante [SSH entre dos EC2](02-practica-ssh/dos-ec2.md), nunca al inicio.

## Seguridad y costo

- Activa MFA en la cuenta AWS y no crees access keys para el usuario root.
- Antes de crear el stack selecciona una Ubuntu Server LTS de Canonical marcada como **Free tier eligible**, o la AMI basada en Ubuntu que el instructor haya verificado para el curso.
- El parámetro de SSH debe ser una sola IPv4 con `/32`, nunca `0.0.0.0/0`.
- La llave A (`.pem`) permanece en tu computadora; nunca se sube al repositorio ni se copia a la EC2. En la práctica entre dos EC2 se genera otra pareja, B, dentro del cliente Linux.
- Cerrar VS Code no detiene la instancia. Al terminar definitivamente, elimina el stack desde CloudFormation.
- Después de borrar un stack, revisa **EC2 → Volumes** para confirmar que la AMI no haya conservado un disco raíz sin uso.
- Free Tier depende del plan, créditos y consumo de cada cuenta. Fuera de la cobertura puede existir un cargo pequeño incluso por pocos minutos.

Referencias oficiales: [crear un stack de CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html), [VS Code Remote-SSH](https://code.visualstudio.com/docs/remote/ssh) y [OpenSSH para Windows](https://learn.microsoft.com/windows-server/administration/openssh/openssh-overview).
