# Consultor Linux desde cero v3

Curso práctico de administración Linux para perfiles junior que quieren avanzar hacia soporte, infraestructura, DevOps o SRE. En cuatro sesiones, el alumno convierte una instalación limpia de Ubuntu en un servidor observable, automatizado, respaldable y protegido.

La referencia es **Ubuntu Server 24.04 LTS x86-64**. El laboratorio recomendado usa una sola EC2; quien no tenga beneficios vigentes puede realizarlo en una VM local con VirtualBox.

> [!WARNING]
> **AWS Free Tier no significa que cualquier cuenta o recurso sea gratuito.** Antes de crear una EC2 confirma en Billing que tu cuenta es elegible, qué plan tiene, cuánto crédito conserva y cuándo vence. En este curso, las cuentas nuevas con Free account plan usan `t3.small` consumiendo créditos; el perfil `t3.micro` se reserva para cuentas anteriores que aún conserven ese beneficio. Si no puedes comprobarlo, utiliza [VirtualBox](extras/virtualbox-fallback.md). Un presupuesto genera alertas, pero no detiene recursos ni garantiza costo cero.

Consulta la [guía completa de prerrequisitos y control de costos](prerrequisitos.md) y las condiciones actuales en la documentación oficial de [AWS Free Tier](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-plans.html).

## Qué aprenderás

Al finalizar podrás:

- orientarte en Linux y administrar archivos con rutas verificables;
- trabajar con usuarios, grupos, permisos y políticas mínimas de `sudo`;
- observar procesos, servicios, recursos y logs;
- diagnosticar red, DNS y conexiones SSH;
- automatizar operaciones con Bash, estados de salida y cron;
- practicar montajes y LVM sin tocar el disco raíz;
- crear, comprobar y restaurar respaldos;
- desplegar WordPress, Nginx y MariaDB con Docker Compose;
- aplicar hardening inicial y documentar un procedimiento de recuperación;
- detener o eliminar correctamente los recursos del laboratorio en AWS.

No se evalúa memorizar flags. Se evalúa saber consultar ayuda, explicar el efecto de un comando, comprobar el resultado y revertirlo de manera segura.

## Entorno común del curso

Todos los capítulos reutilizan estas identidades y rutas:

| Elemento | Valor | Propósito |
|---|---|---|
| Administrador | `ubuntu` | Cuenta inicial de la AMI y tareas con `sudo` |
| Usuario operativo | `deploy` | Operación diaria sin privilegios administrativos generales |
| Grupo | `ops` | Acceso compartido con mínimo privilegio |
| Repositorio | `~/linux-desde-cero` | Material, scripts y fixtures originales |
| Laboratorio desechable | `~/linux-desde-cero/laboratorio` | Copia que puede regenerarse |
| Laboratorios por módulo | `~/consultor-linux-lab/modulo-NN` | Resultados progresivos de los capítulos 5–9 |
| Proyecto del sistema | `/srv/consultor-linux` | Evidencias y prácticas de administración |

`data/` se considera inmutable. El script de preparación copia esos fixtures a `laboratorio/`; las prácticas que transforman o eliminan datos trabajan sobre la copia.
Los capítulos 5–9 usan `~/consultor-linux-lab` para que sus procesos, scripts y
respaldos no desaparezcan al regenerar `laboratorio/`. Cada capítulo muestra
la ruta completa y su limpieza; no escribas literalmente `modulo-NN`.

## Inicio rápido

### 1. Completa el gate previo

Antes de la primera clase:

1. confirma Free Tier, créditos y fecha de vencimiento;
2. activa MFA, alertas de Free Tier y un presupuesto de USD 5;
3. crea una EC2 Ubuntu 24.04 elegible, o prepara VirtualBox;
4. limita el Security Group a SSH desde tu IP `/32`;
5. verifica 20 GiB `gp3`, CPU credits `standard` y `DeleteOnTermination=true`;
6. conéctate como `ubuntu` y clona el repositorio.

La configuración exacta, incluida la llave SSH y el perfil `t3.micro`, está en [prerrequisitos.md](prerrequisitos.md).

### 2. Prepara Ubuntu

Desde la raíz del repositorio:

```bash
cd ~/linux-desde-cero
test -f README.md && echo "Estoy en la raíz del curso"

bash scripts/programar-apagado.sh 360
bash scripts/bootstrap-ubuntu.sh
bash scripts/verificar-entorno.sh
bash scripts/preparar-lab.sh
```

- `360` programa un apagado preventivo dentro de seis horas.
- `bootstrap-ubuntu.sh` instala las herramientas del curso y Docker; ejecútalo una vez en la máquina desechable.
- `verificar-entorno.sh` comprueba la plataforma antes de practicar.
- `preparar-lab.sh` **reemplaza únicamente `laboratorio/`** y vuelve a copiar `data/`.

Para el perfil `t3.micro`, crea primero los 2 GiB de swap indicados por la guía:

```bash
sudo bash scripts/configurar-swap.sh 2
bash scripts/verificar-entorno.sh
```

Si clonaste el repositorio en otra ubicación, cambia `~/linux-desde-cero` por tu ruta real. No ejecutes los scripts como `root` salvo cuando el comando lo indique expresamente.

## Cómo leer los comandos

Cada operación importante sigue la misma secuencia didáctica.

### 1. Sintaxis general

Los textos entre `< >` son marcadores y **no se escriben literalmente**:

```bash
cp <archivo_origen> <archivo_destino>
```

### 2. Valores utilizados

El capítulo explica qué representa cada marcador, quién ejecuta el comando, desde qué directorio y qué recurso será modificado.

### 3. Ejemplo copiable

El ejemplo contiene valores concretos del laboratorio:

```bash
cp laboratorio/data/logs/servicio.log \
  laboratorio/backups/servicio.log
```

### 4. Comprobación y reversión

Después se muestra cómo verificar el resultado, interpretar una salida representativa y, cuando corresponde, deshacer únicamente el cambio realizado.

Los hostnames, IP, PID, UID, fechas, tamaños y versiones de kernel pueden variar. Una “salida esperada” describe su estructura y los campos relevantes, no una cadena que deba coincidir carácter por carácter.

## Mapa de los 13 capítulos

| # | Capítulo | Resultado práctico |
|---:|---|---|
| 1 | [Introducción a Linux y al entorno de trabajo](01-introduccion-entorno-linux.md) | Identificar distribución, kernel, shell, nube y recursos del servidor |
| 2 | [Instalación y configuración inicial](02-instalacion-configuracion-inicial.md) | Verificar EC2, crear `deploy`/`ops` y establecer `/srv/consultor-linux` |
| 3 | [Comandos y gestión de archivos](03-comandos-gestion-archivos.md) | Navegar, buscar, copiar, mover y enlazar archivos de forma segura |
| 4 | [Permisos, usuarios y grupos](04-permisos-usuarios-grupos.md) | Implementar acceso compartido con mínimo privilegio |
| 5 | [Procesos y gestión del sistema](05-procesos-gestion-sistema.md) | Controlar procesos, jobs, señales, servicios y logs |
| 6 | [Redes y conectividad](06-redes-conectividad.md) | Diagnosticar red/DNS y transferir evidencias mediante SSH/SCP |
| 7 | [Shell y automatización básica](07-shell-automatizacion-basica.md) | Componer comandos, redirecciones, tuberías y estados de salida |
| 8 | [Bash y automatización con cron](08-bash-cron.md) | Crear scripts validados y tareas programadas auditables |
| 9 | [Almacenamiento y respaldos](09-almacenamiento-respaldos.md) | Practicar loop/LVM aislado y demostrar backup/restore |
| 10 | [Servidores, servicios y paquetes](10-servidores-servicios.md) | Relacionar gestores de paquetes, servicios web, BD, DNS, DHCP y correo |
| 11 | [Virtualización, contenedores y Docker Compose](11-virtualizacion-contenedores.md) | Desplegar un stack con redes, volúmenes, secretos y health checks |
| 12 | [Seguridad y hardening inicial](12-seguridad-linux.md) | Reducir superficie, revisar UFW/SSH/AppArmor y proteger secretos |
| 13 | [Proyecto final: servidor administrable y recuperable](13-proyecto-final.md) | Integrar despliegue, diagnóstico, respaldo, restauración y runbook |

Cada capítulo incluye una práctica completamente resuelta y un reto. Las respuestas de los retos se mantienen aparte en [instructor/soluciones.md](instructor/soluciones.md).

## Distribución de las cuatro sesiones

Cada clase dura de **09:00 a 14:00**, hora de Ciudad de México, con receso de **11:00 a 11:30**. Son 4.5 horas efectivas por sesión y 18 horas efectivas dentro de las 20 horas anunciadas.

| Sesión | Capítulos | Recorrido | Evidencia principal |
|---:|---|---|---|
| 1 — Operar Linux con seguridad | 1–4 | Entorno, sistema de archivos, comandos, enlaces, identidades y permisos | `deploy`, `ops` y árbol de trabajo con acceso mínimo |
| 2 — Observar y conectar | 5, 6 y parte de 9 | Procesos, systemd, logs, red, DNS, SSH y LVM aislado | Reporte de diagnóstico y volumen desechable limpio |
| 3 — Automatizar y recuperar | 7, 8 y respaldo de 9 | I/O, pipelines, Bash, validación, cron, backup y restore | Respaldo con checksum restaurado y descargado por SCP |
| 4 — Desplegar y proteger | 10–13 | Servicios, Compose, hardening, incidente y recuperación | Stack funcional, runbook y cuenta AWS sin recursos del curso |

La agenda minuto a minuto, junto con qué recortar si el grupo se retrasa, está en el [plan docente del curso v3](instructor/plan-curso-consultor-linux-2026.md).

## Proyecto integrador con Docker Compose

El proyecto final se construye progresivamente durante las cuatro sesiones:

```text
navegador del alumno
        │ http://127.0.0.1:8080
        ▼
túnel SSH ──► 127.0.0.1:8080 en EC2
                    │
                    ▼
             Nginx (proxy)
                    │ red frontend
                    ▼
          WordPress sobre Apache
                    │ red backend interna
                    ▼
                 MariaDB
```

Características del stack:

- imágenes versionadas, nunca `latest`;
- Nginx publicado sólo en `127.0.0.1:8080`;
- MariaDB sin puerto publicado y dentro de una red interna;
- secretos locales ignorados por Git;
- volúmenes persistentes, límites de memoria y health checks;
- logs rotados y perfiles compatibles con 2 GiB o 1 GiB más swap;
- respaldo, checksum, eliminación controlada y restauración demostrada.

El laboratorio de almacenamiento incluye scripts con guardias en
`scripts/almacenamiento/`; se estudian después de ejecutar el flujo manual del
capítulo 9 y nunca aceptan un disco físico como objetivo.

No abras públicamente 80, 443 o 3306. El navegador accede mediante el túnel explicado en [prerrequisitos](prerrequisitos.md#9-túnel-del-proyecto-web).

Los artefactos y el punto de entrada están documentados en [proyecto-compose/README.md](proyecto-compose/README.md). La primera ejecución se realiza desde la raíz:

```bash
bash scripts/preparar-proyecto.sh
```

No uses `docker system prune`: puede eliminar recursos de proyectos ajenos.

## Preparación, evidencias y limpieza

### Antes de cada sesión

```bash
cd ~/linux-desde-cero
bash scripts/programar-apagado.sh 360
bash scripts/verificar-entorno.sh
```

Si reiniciaste una EC2 detenida, consulta su nueva IPv4 y actualiza la conexión SSH. Confirma también que la regla `/32` contiene tu IP pública actual.

### Para reiniciar los ejercicios de archivos

```bash
bash scripts/preparar-lab.sh
```

Este comando regenera `laboratorio/`; no lo ejecutes si todavía necesitas resultados que sólo existan allí. Los fixtures originales de `data/` no se modifican.

### Para detener el proyecto sin borrar datos

```bash
bash scripts/limpiar-proyecto.sh
```

El script elimina contenedores y red del proyecto, pero conserva volúmenes y secretos para continuar después.

### Cierre definitivo del proyecto

Después de crear y descargar el respaldo final:

```bash
bash scripts/limpiar-proyecto.sh --eliminar-datos --confirmar
```

La confirmación explícita limita la eliminación a los volúmenes y secretos de `consultor-linux`.

### Cierre definitivo de AWS

Detener una EC2 elimina el consumo de cómputo, pero **no** elimina el volumen EBS. Al concluir el curso:

1. descarga el respaldo y comprueba su checksum;
2. termina la instancia `consultor-linux`;
3. confirma que el volumen raíz fue eliminado;
4. verifica que no existan snapshots ni Elastic IP;
5. elimina el Security Group y el Key Pair del curso;
6. revisa EC2 Global View y Billing al día siguiente.

No abandones la limpieza basándote sólo en el estado `Stopped`.

## Anexos opcionales

Los anexos amplían el temario sin desplazar las prácticas esenciales:

- [VirtualBox como laboratorio alternativo](extras/virtualbox-fallback.md): ruta sin AWS o fallback ante una cuenta no elegible.
- [DNS con BIND](extras/dns-bind.md): validación aislada de una zona, sin publicar un DNS autoritativo.
- [DHCP con Kea](extras/dhcp-kea.md): validar configuración sin ejecutar un DHCP dentro de la VPC.
- [Correo en Linux](extras/correo-linux.md): arquitectura, puertos y registros sin desplegar un servidor público.

## Material para el instructor

- [Plan docente de cuatro sesiones](instructor/plan-curso-consultor-linux-2026.md)
- [Soluciones de los 13 retos](instructor/soluciones.md)
- [Validación segura de comandos y salidas](instructor/validacion-comandos.md)

El plan docente define tiempos, evidencias, contenido no recortable y alternativas cuando un laboratorio no puede ejecutarse en AWS. La validación distingue comandos probados localmente, pruebas que requieren una VM temporal y pasos que dependen de una cuenta AWS.

Para repetir la revisión estática desde la raíz:

```bash
bash tests/validar-repositorio.sh
```

Comprueba 13 capítulos/retos/soluciones, los 53 apartados del PDF, enlaces,
fences, sintaxis Bash, etiquetas de imágenes, secretos y configuración Compose.
