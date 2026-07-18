# Linux desde cero

Curso práctico de Linux para perfiles junior que necesitan una base sólida antes de avanzar hacia administración de sistemas, DevOps, desarrollo o Machine Learning Engineering.

La referencia del laboratorio es **Ubuntu LTS**. Cuando aporta valor se indican equivalencias para distribuciones de la familia RHEL, sin duplicar todo el curso. La guía de infraestructura permite elegir una AMI Ubuntu Server LTS de Canonical o una imagen basada en Ubuntu que el instructor haya verificado para el curso.

## Índice

- [Objetivos](#objetivos)
- [Cómo usar este repositorio](#cómo-usar-este-repositorio)
- [Temario](#temario)
- [Distribución de las cuatro sesiones](#distribución-de-las-cuatro-sesiones)
- [Preparación rápida](#preparación-rápida)
- [Infraestructura AWS](#infraestructura-aws)
- [Convenciones didácticas](#convenciones-didácticas)
- [Material para el instructor](#material-para-el-instructor)

## Objetivos

Al finalizar, el alumno podrá:

- conectarse por SSH a una máquina Linux real;
- orientarse en el sistema de archivos y administrar archivos y directorios;
- trabajar con usuarios, grupos, permisos y `sudo`;
- instalar y consultar paquetes;
- combinar comandos mediante redirecciones y tuberías;
- inspeccionar procesos, servicios y logs;
- crear scripts Bash pequeños y verificables;
- diagnosticar conectividad básica y transferir archivos con SCP/SFTP.

## Cómo usar este repositorio

Los capítulos `01` a `11` siguen el temario oficial. Cada uno contiene teoría mínima, ejemplos resueltos, salida esperada, explicación, errores frecuentes y un reto. Los ejemplos se ejecutan desde la raíz del repositorio salvo que se indique lo contrario.

Los ejercicios están resueltos en cada capítulo. Las soluciones de los **retos** se encuentran en [instructor/soluciones.md](instructor/soluciones.md).

El [taller ampliado de Bash](12-hands-on-bash-scripting.md) conserva material adicional para que el instructor seleccione ejercicios según el avance del grupo.

### Punto de partida para todas las prácticas

Los ejemplos suponen que el repositorio está dentro de tu directorio personal con el nombre `linux-desde-cero`. Antes de practicar abre una terminal y ejecuta:

```bash
cd ~/linux-desde-cero
pwd
test -f README.md && echo "Estoy en la raíz del curso"
```

Salida esperada:

```text
/home/tu_usuario/linux-desde-cero
Estoy en la raíz del curso
```

Si clonaste el repositorio en otra ubicación, sustituye `~/linux-desde-cero` por tu ruta. La **raíz del curso** es la carpeta que contiene `README.md`, `01-introduccion-a-linux.md`, `data/` y `ejercicios-bash-scripting/`.

### Cómo leer comandos con parámetros

Cuando un comando necesita valores propios, el material muestra dos formas:

1. **Sintaxis general**, con marcadores entre `< >`:

   ```bash
   comando <origen> <destino>
   ```

2. **Ejemplo resuelto**, con valores concretos que sí puedes copiar:

   ```bash
   cp data/dummy_logs.txt laboratorio/dummy_logs-copia.txt
   ```

No escribas literalmente `<origen>` o `<IP_PUBLICA>`. Los marcadores indican qué dato debes sustituir. Debajo de cada ejemplo se explica qué representa cada valor.

## Temario

1. [Introducción a Linux](01-introduccion-a-linux.md)
2. [Entrada y salida del sistema](02-un-enfoque-a-linux.md)
3. [Estructura del sistema de archivos](03-estructura-del-sistema-de-archivos-de-linux.md)
4. [X Window y Wayland](04-x-window.md)
5. [GNOME](05-gnome.md)
6. [KDE Plasma](06-kde.md)
7. [El shell](07-el-shell.md)
8. [Redirecciones y tuberías](08-redirecciones-y-tuberias.md)
9. [Ejecución de programas, procesos y servicios](09-ejecucion-de-programas.md)
10. [Programas de comandos con Bash](10-programas-de-comandos.md)
11. [Compilación, regex, red y copias remotas](11-scp-copias-remotas.md)
12. [Hands-on Bash Scripting](12-hands-on-bash-scripting.md)

## Distribución de las cuatro sesiones

Cada sesión dura de 09:00 a 14:00, con receso de 11:00 a 11:30: **4.5 horas efectivas**, 18 horas efectivas dentro de las 20 horas anunciadas.

| Sesión | Fecha | Capítulos y resultado principal |
|---|---|---|
| 1 | 4 de julio de 2026 | Capítulos 1, 3 y 7.1–7.15 de 7. Crear una estructura de trabajo con permisos correctos. |
| 2 | 11 de julio de 2026 | Resto de 7, inspección de sistemas de archivos y 4–6. Buscar, respaldar y relacionar CLI con GUI. |
| 3 | 18 de julio de 2026 | 2, 8, 9 y 10; ejercicios seleccionados de 12. Construir pipelines, controlar procesos y generar un reporte. |
| 4 | 25 de julio de 2026 | 11. Analizar logs, empaquetar resultados y transferirlos de forma segura. |

La agenda minuto a minuto está en [instructor/plan-curso-linux-desde-cero-2026.md](instructor/plan-curso-linux-desde-cero-2026.md).

## Preparación rápida

1. Completar [prerrequisitos.md](prerrequisitos.md) antes de la primera sesión.
2. Confirmar que el repositorio existe en Ubuntu; clonarlo sólo si todavía falta.
3. Preparar una copia desechable de los datos:

```bash
bash ejercicios-bash-scripting/preparar-lab.sh
```

4. Trabajar dentro de `laboratorio/`. Para reiniciar los ejercicios, volver a ejecutar el script.

## Infraestructura AWS

La preparación inicial se limita a cargar el template Ubuntu del curso en CloudFormation y conectarse con VS Code Remote-SSH. Sigue [infraestructura-aws/](infraestructura-aws/README.md). La segunda EC2 se crea con otro template sólo al practicar SSH entre dos hosts Linux; AWS CLI local no es requisito.

## Convenciones didácticas

> **Salida esperada:** muestra la forma de la salida, no valores inmutables. Usuario, PID, fecha, IP, tamaño y hostname pueden variar.

> **Precaución:** no ejecutes como `root` un comando que todavía no comprendes. Antes de usar `rm`, `chmod`, `chown` o `kill`, verifica el objetivo.

- `comando`: elemento que se escribe literalmente.
- `<valor>`: marcador que debe sustituirse.
- **Sintaxis general:** forma reutilizable del comando.
- **Ejemplo resuelto:** comando completo con los valores usados en el curso.
- `# comentario`: explicación; no es necesario copiarla.
- Las prácticas usan datos ficticios y no contienen credenciales reales.

## Material para el instructor

- [Plan de cuatro sesiones](instructor/plan-curso-linux-desde-cero-2026.md)
- [Soluciones de los retos](instructor/soluciones.md)
- [Validación segura de comandos y salidas](instructor/validacion-comandos.md)
