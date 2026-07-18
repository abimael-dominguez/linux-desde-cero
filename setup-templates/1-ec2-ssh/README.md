# Template de práctica — Destino SSH/SCP

Este directorio contiene el template para crear el servidor destino de la práctica SSH Linux a Linux:

- [`ec2-ssh.yml`](ec2-ssh.yml)
- [Tutorial completo: SSH entre dos EC2](../../infraestructura-aws/02-practica-ssh/dos-ec2.md)

No necesitas AWS CLI. Se carga desde la consola web de CloudFormation cuando llegue la práctica de SSH.

## Antes de cargarlo

1. Desde la EC2 principal genera una pareja de claves exclusiva para la práctica.
2. Importa únicamente su clave pública como Key Pair de EC2.
3. Copia la IPv4 pública de la EC2 principal y agrega `/32`.
4. Elige una AMI Ubuntu Server LTS `x86_64` de Canonical o la imagen verificada por el instructor; la guía usa el usuario `ubuntu`.

## Parámetros que debes proporcionar

| Parámetro | Ejemplo | Significado |
|---|---|---|
| `ProjectName` | `linux-ssh-target` | Prefijo del servidor destino. |
| `AmiId` | `ami-0123456789abcdef0` | AMI Ubuntu elegida en la región. |
| `InstanceType` | `t3.micro` | Tipo pequeño para la práctica. |
| `KeyName` | `linux-client-to-target` | Clave pública importada desde la EC2 principal. |
| `AllowedCidr` | `198.51.100.25/32` | IPv4 pública de la EC2 principal. |

El template sólo permite `t3.micro`. Confirma en la consola que aparezca como Free Tier eligible para la cuenta y recuerda que dos instancias comparten el mismo beneficio o saldo de créditos.

## Qué crea

- una VPC separada `10.20.0.0/16`;
- subnet pública, Internet Gateway y ruta;
- Security Group que acepta SSH sólo desde `AllowedCidr`;
- una EC2 temporal con IMDSv2, créditos de CPU `standard` y el disco raíz definido por la AMI.

Al finalizar elimina el stack completo desde CloudFormation. La `.pem` del equipo del alumno no se copia a ningún servidor; `linux-course` genera una segunda llave exclusiva para este destino.
