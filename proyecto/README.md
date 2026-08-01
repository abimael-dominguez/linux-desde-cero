# Eventos Cero

Práctica de Docker, Linux, Bash, AWS CLI y CloudFormation. La app permite crear, buscar, editar y borrar eventos.

## 1. Verificar requisitos

```bash
docker --version
docker compose version
python3 --version
node --version       # 20 o superior
npm --version
aws --version        # AWS CLI v2
curl --version
jq --version
```

Verifica tu perfil AWS; reemplaza `perfil-del-alumno` por su nombre:

```bash
aws configure list-profiles
aws sts get-caller-identity --profile perfil-del-alumno
aws configure get region --profile perfil-del-alumno
```

La región debe ser `us-east-1`. El perfil del instructor es `ibrcbg-developer`.

### Explorar `~/.aws` con comandos Linux

`~` representa la carpeta personal y los nombres que comienzan con `.` están ocultos:

```bash
echo "$HOME"                       # mostrar la carpeta personal
cd "$HOME"
pwd                                # confirmar la ubicación actual
ls                                 # no muestra archivos ocultos
ls -la                             # también muestra archivos ocultos
ls -la .aws                        # explorar la carpeta de AWS CLI
```

Observa los tipos y permisos sin imprimir el contenido de las credenciales:

```bash
file ~/.aws/config ~/.aws/credentials
stat ~/.aws
stat ~/.aws/config ~/.aws/credentials
aws configure list-profiles
aws configure get region --profile perfil-del-alumno
```

No ejecutes `cat ~/.aws/credentials`, no copies ese archivo al proyecto y nunca lo subas a Git.

La carpeta `proyecto/.aws` es diferente: sólo guarda estado local no secreto del laboratorio.

```bash
cd -                               # regresar a la carpeta anterior
cd proyecto
ls -la .aws
cat .aws/.gitignore

# deployment-id existe solamente entre deploy y destroy
if [[ -f .aws/deployment-id ]]; then
  cat .aws/deployment-id
else
  echo "Aún no hay un despliegue activo"
fi
```

## 2. Ejecutar la app local

Terminal 1:

```bash
cd proyecto
./scripts/local.sh backend
```

Este comando levanta DynamoDB Local, crea la tabla e inicia la API.

Terminal 2:

```bash
cd proyecto
npm --prefix frontend ci
npm --prefix frontend run dev
```

Abre `http://localhost:5173` y prueba el CRUD.

Comandos locales útiles:

```bash
docker compose ps                 # ver DynamoDB
docker compose logs dynamodb      # ver sus logs
./scripts/local.sh stop           # detener y conservar datos
./scripts/local.sh reset          # borrar datos; solicita RESET
./scripts/local.sh test           # pruebas automatizadas; opcional
```

`test` prueba backend, DynamoDB y React. No utiliza AWS.

### Comandos Docker para practicar

Ejecuta estos comandos desde `proyecto/`:

```bash
docker compose pull                 # descargar DynamoDB Local
docker images                       # listar imágenes locales
docker compose up -d dynamodb       # levantar en segundo plano
docker ps                           # listar contenedores activos
docker compose ps                   # estado de este proyecto
docker compose logs dynamodb        # consultar logs
docker compose logs -f dynamodb     # seguir logs; salir con Ctrl+C
docker compose port dynamodb 8000   # ver el puerto publicado
docker stats --no-stream            # observar CPU y memoria
```

Inspecciona la configuración generada y el contenedor:

```bash
docker compose config
docker inspect "$(docker compose ps -q dynamodb)"
```

Entra al contenedor y practica comandos Linux:

```bash
docker compose exec dynamodb sh
whoami
pwd
ls -lah
exit
```

Practica el ciclo de vida:

```bash
docker compose restart dynamodb     # reiniciar
docker compose stop dynamodb        # detener
docker compose start dynamodb       # volver a iniciar
docker compose down                 # borrar contenedor; conserva el volumen
docker volume ls                    # listar volúmenes
```

Este comando sí borra los datos locales y debe usarse con cuidado:

```bash
docker compose down --volumes
```

## 3. Desplegar en AWS

```bash
cd proyecto
AWS_PROFILE=perfil-del-alumno ./scripts/deploy.sh
```

El script crea todo automáticamente mediante CloudFormation:

- ECR y la imagen Docker de la API;
- DynamoDB;
- Lambda y API Gateway;
- buckets S3 privados;
- CloudFront y el frontend React.

La primera ejecución tarda varios minutos por CloudFront. Ejecuta el mismo comando otra vez para comprobar que el despliegue es idempotente:

```bash
AWS_PROFILE=perfil-del-alumno ./scripts/deploy.sh
```

Para observar los recursos con AWS CLI:

```bash
AWS_PROFILE=perfil-del-alumno aws cloudformation describe-stacks \
  --region us-east-1 --stack-name tecgurus-linux-events-lab-app

AWS_PROFILE=perfil-del-alumno aws ecr describe-repositories \
  --region us-east-1

AWS_PROFILE=perfil-del-alumno aws dynamodb list-tables \
  --region us-east-1

AWS_PROFILE=perfil-del-alumno aws s3 ls
```

DynamoDB Local sólo se ejecuta en la computadora. ECR recibe únicamente la imagen de la API Lambda.

## 4. Destruir el laboratorio

```bash
AWS_PROFILE=perfil-del-alumno ./scripts/destroy.sh
```

Revisa los recursos mostrados y escribe la confirmación solicitada, por ejemplo:

```text
DESTRUIR 123456789012 us-east-1 lab
```

El script elimina la aplicación, DynamoDB, buckets, CloudFront, logs, imágenes y repositorio ECR. Después realiza una auditoría automática.

También puedes auditar sin borrar:

```bash
AWS_PROFILE=perfil-del-alumno ./scripts/audit.sh
```

Una segunda ejecución de `destroy.sh` debe terminar correctamente aunque ya no existan recursos.

## `STAGE` opcional

Durante la práctica normal no lo definas: se utiliza `lab`.

Para crear un ambiente separado, repite el mismo `STAGE` en los tres scripts:

```bash
AWS_PROFILE=perfil-del-alumno STAGE=a01 ./scripts/deploy.sh
AWS_PROFILE=perfil-del-alumno STAGE=a01 ./scripts/audit.sh
AWS_PROFILE=perfil-del-alumno STAGE=a01 ./scripts/destroy.sh
```

Cada `STAGE` crea recursos independientes.

## Ayuda

```bash
./scripts/local.sh --help
./scripts/deploy.sh --help
./scripts/audit.sh --help
./scripts/destroy.sh --help
```

> El CRUD es público y es sólo para clase. Aunque DynamoDB usa `1 RCU / 1 WCU`, Free Tier no garantiza costo cero en todos los servicios. Ejecuta `destroy.sh` al terminar.
