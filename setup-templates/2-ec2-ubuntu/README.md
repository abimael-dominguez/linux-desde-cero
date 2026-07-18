# Template principal — EC2 Ubuntu del curso

Este directorio contiene el template usado para crear el entorno Linux principal:

- [`ec2-ubuntu-ssh.yml`](ec2-ubuntu-ssh.yml)
- [Tutorial completo: EC2 y VS Code](../../infraestructura-aws/01-ec2-y-vscode/README.md)

No necesitas AWS CLI. El archivo se carga desde la consola web de CloudFormation.

## Antes de cargarlo

En la misma región de AWS:

1. Crea un Key Pair y descarga su `.pem`.
2. Elige una AMI Ubuntu Server LTS `x86_64` de Canonical o la imagen verificada por el instructor, y copia su AMI ID.
3. Identifica la IPv4 pública de tu computadora y agrega `/32`.

## Parámetros que debes proporcionar

| Parámetro | Ejemplo | Significado |
|---|---|---|
| `ProjectName` | `linux-course` | Prefijo visible de los recursos. |
| `UbuntuAmiId` | `ami-0123456789abcdef0` | AMI de Ubuntu elegida en esa región. |
| `UbuntuInstanceType` | `t3.micro` | Tipo de instancia del laboratorio. |
| `UbuntuKeyName` | `linux-course-key` | Key Pair creado antes del stack. |
| `SshAllowedCidr` | `203.0.113.10/32` | Única IPv4 autorizada para SSH. |

Los CIDR privados de VPC y subnet ya tienen valores seguros para el laboratorio; no necesitas modificarlos.

El template sólo permite `t3.micro`. AWS lo incluye entre los tipos marcados como Free Tier elegibles en los programas anterior y actual, pero la consola de cada alumno debe confirmar cobertura, créditos y vigencia antes de crear el stack.

## Qué crea

- VPC `10.10.0.0/16` y subnet pública;
- Internet Gateway y ruta de salida;
- Security Group con SSH sólo desde `SshAllowedCidr`;
- una EC2 Ubuntu con IMDSv2 y créditos de CPU en modo `standard`;
- el disco raíz definido por la AMI elegida.

El template no fuerza el nombre, tamaño ni tipo del disco raíz. Así evita depender de `/dev/sda1` y funciona también con una AMI verificada del instructor. Antes de crear, revisa el tamaño y que **Delete on termination** esté activo en el block device mapping de la AMI.

## Resultado

Cuando el stack muestre `CREATE_COMPLETE`, consulta **Outputs**. Allí encontrarás `PublicIp`, `PublicDnsName`, `RemoteUser` y un `SshCommand` de referencia.

Para eliminar todo lo creado por este template usa **CloudFormation → Stacks → Delete**. No elimines únicamente la EC2, porque dejarías la red administrada por el stack.
