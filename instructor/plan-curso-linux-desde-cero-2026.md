# Plan docente — Linux desde cero (2026)

## Índice

- [Datos](#datos)
- [Reglas de conducción](#reglas-de-conducción)
- [Clase 1](#clase-1--fundamentos-archivos-y-permisos)
- [Clase 2](#clase-2--shell-útil-y-escritorios)
- [Clase 3](#clase-3--io-procesos-y-bash)
- [Clase 4](#clase-4--regex-red-y-copias-remotas)
- [Evidencias](#evidencias)
- [Cobertura del temario comercial](#cobertura-del-temario-comercial)

## Datos

- Sábados 4, 11, 18 y 25 de julio de 2026.
- 09:00–14:00, hora de Ciudad de México.
- Receso 11:00–11:30.
- 20 horas anunciadas; 18 horas efectivas.
- Ubuntu 24.04 LTS en EC2 para CLI y VM del instructor para GNOME/KDE.

## Reglas de conducción

- Máximo 20 minutos seguidos de explicación.
- Después de cada bloque, ejecutar una tarea verificable.
- Antes de un comando, nombrar explícitamente qué usuario, grupo, archivo, proceso o servidor se va a crear o modificar.
- Cuando existan parámetros, presentar primero la sintaxis general y después el ejemplo resuelto con los valores del curso.
- Pedir al alumno que identifique origen, destino y resultado esperado antes de copiar un bloque.
- Usar el PDF como guía de consulta, no como una presentación que deba recorrerse linealmente.
- Aplicar microciclos: contexto, demostración breve, práctica del alumno y comprobación visible.
- Hacer un semáforo de ritmo después de cada microciclo; si más de 20 % sigue en amarillo o rojo, repetir y recortar un tema opcional.
- Los ejercicios se resuelven en el capítulo; los retos se intentan antes de consultar [soluciones.md](soluciones.md).
- Si falla AWS, continuar en WSL/VM/Multipass o contenedor; no gastar la clase creando infraestructura.
- Antes de cada sesión, verificar la raíz del curso y los archivos de entrada requeridos. Ejecutar `bash ejercicios-bash-scripting/preparar-lab.sh` sólo cuando se busque un laboratorio limpio: el script elimina y recrea `laboratorio/`, por lo que puede borrar evidencia de clases anteriores.

## Clase 1 — Fundamentos, archivos y permisos

**Material de trabajo:**

- [01-introduccion-a-linux.md](../01-introduccion-a-linux.md#11-qué-es-linux) — capítulo 1: Linux, distribuciones, terminal, usuarios, grupos y `sudo`.
- [03-estructura-del-sistema-de-archivos-de-linux.md](../03-estructura-del-sistema-de-archivos-de-linux.md#31-tipos-de-archivo) — capítulo 3: tipos de archivo, rutas, jerarquía, enlaces y permisos.
- [07-el-shell.md](../07-el-shell.md#71-73-shell-comandos-y-directorio-personal) — secciones 7.1–7.15: navegación y administración segura de archivos desde Bash.

**Conducción detallada:** [planeacion-clase-1.md](planeacion-clase-1.md).

| Hora | Actividad |
|---|---|
| 09:00–09:20 | Verificar el entorno con `whoami`, `hostname`, `pwd` y `/etc/os-release`. |
| 09:20–10:00 | Kernel, distribución, shell, terminal y escritorio. |
| 10:00–10:40 | Usuarios, grupos y `sudo`; práctica controlada. |
| 10:40–11:00 | Flujo mínimo de `apt`. |
| 11:00–11:30 | **Receso**. |
| 11:30–12:15 | Jerarquía, rutas y tipos de archivo. |
| 12:15–13:05 | `pwd`, `ls`, `cd`, `mkdir`, `touch`, `cp`, `mv`, `rm` y `file`. |
| 13:05–13:40 | Enlaces, permisos, propietario y grupo. |
| 13:40–13:55 | Reto 3: directorio compartido. |
| 13:55–14:00 | Evidencia y cierre. |

**No recortar:** navegación, operaciones y permisos.  
**Recortar primero:** comparación de distribuciones y detalles de cuentas.

## Clase 2 — Shell útil y escritorios

**Material de trabajo:**

- [07-el-shell.md](../07-el-shell.md#716-espacio-du-y-df) — secciones 7.16–7.21: espacio, lectura, búsqueda, respaldos e impresión.
- [03-estructura-del-sistema-de-archivos-de-linux.md](../03-estructura-del-sistema-de-archivos-de-linux.md#35-acceso-a-sistemas-de-archivos) — sección 3.5: dispositivos, puntos de montaje y espacio disponible; sólo consulta, sin formatear discos.
- [04-x-window.md](../04-x-window.md#41-de-un-clic-a-una-ventana) — capítulo 4: X Window, Wayland y la diferencia entre servidor y escritorio.
- [05-gnome.md](../05-gnome.md#51-mapa-de-gnome) — recorrido visual de GNOME, Actividades, Files, herramientas y espacios de trabajo.
- [06-kde.md](../06-kde.md#61-partes-de-la-pantalla) — recorrido visual de KDE Plasma, Dolphin y herramientas esenciales.

**Conducción detallada:** [planeacion-clase-2.md](planeacion-clase-2.md).

| Hora | Actividad |
|---|---|
| 09:00–09:30 | Acordar el ritmo y recuperar navegación y permisos con un diagnóstico sin calificación. |
| 09:30–10:10 | Microciclos de consulta y búsqueda literal: `head`, `tail`, `less` y `grep`. |
| 10:10–10:45 | Buscar archivos con `find`; comparar `du` y `df`. |
| 10:45–11:00 | Checkpoint, preguntas y repetición; sin contenido nuevo. |
| 11:00–11:30 | **Receso**. |
| 11:30–12:30 | Modelo y práctica: crear, listar, restaurar y verificar un `tar.gz`, una línea a la vez. |
| 12:30–12:45 | Checkpoint y clínica de errores del respaldo. |
| 12:45–13:05 | `lsblk`, `findmnt`, `df -T`; sólo inspección, sin formatear discos. |
| 13:05–13:40 | Capas gráficas y recorridos visuales breves de GNOME y KDE Plasma. |
| 13:40–13:52 | Práctica de búsqueda/restauración y preguntas de cierre sobre KDE. |
| 13:52–14:00 | Exit ticket, semáforo final y cierre. |

**No recortar:** búsqueda, respaldo y restauración.  
**Recortar primero:** personalización, recorrido detallado de KDE, `pr`/`lpr` y opciones avanzadas de búsqueda.

## Clase 3 — I/O, procesos y Bash

**Material de trabajo:**

- [02-un-enfoque-a-linux.md](../02-un-enfoque-a-linux.md#21-entrada-y-salida) — entrada, salida, errores, terminal y el modelo mental de composición.
- [08-redirecciones-y-tuberias.md](../08-redirecciones-y-tuberias.md#81-redirecciones) — redirecciones, pipes, `tee` y reportes que conservan diagnósticos.
- [09-ejecucion-de-programas.md](../09-ejecucion-de-programas.md#inspección-con-ps-pgrep-y-top) — procesos, jobs, señales, prioridad, servicios y journal.
- [10-programas-de-comandos.md](../10-programas-de-comandos.md#101-comentarios-y-shebang) — scripts Bash, variables, argumentos, validación y estados de salida.
- [12-hands-on-bash-scripting.md](../12-hands-on-bash-scripting.md#preparación) — ejercicios seleccionados: práctica guiada de scripting sobre datos del laboratorio.

| Hora | Actividad |
|---|---|
| 09:00–09:15 | Buscar un patrón y guardar resultado. |
| 09:15–10:05 | `stdin`, `stdout`, `stderr` y redirecciones. |
| 10:05–11:00 | Pipes, `tee`, filtros y CSV. |
| 11:00–11:30 | **Receso**. |
| 11:30–12:25 | Procesos, jobs, señales, `nohup`, `time`, servicios y journal. |
| 12:25–13:10 | Shebang, variables, argumentos y estados. |
| 13:10–13:50 | Crear y probar el resumen de logs. |
| 13:50–14:00 | Evidencia y cierre. |

**No recortar:** descriptores, pipes, `kill`, argumentos y validación.  
**Recortar primero:** prioridad y detalles de systemd.

## Clase 4 — Regex, red y copias remotas

**Material de trabajo:**

- [11-scp-copias-remotas.md](../11-scp-copias-remotas.md#111-compilación-en-linux) — compilación, regex, red, SSH, SCP/SFTP y verificación de una entrega remota.

| Hora | Actividad |
|---|---|
| 09:00–09:15 | Verificar datos, scripts y acceso remoto. |
| 09:15–09:50 | Regex sobre logs. |
| 09:50–10:20 | IP, rutas, puertos y DNS. |
| 10:20–11:00 | SSH, claves y huellas. |
| 11:00–11:30 | **Receso**. |
| 11:30–12:15 | SCP/SFTP en ambos sentidos y hashes. |
| 12:15–12:45 | Compilación, linkado y Makefile de Pac-Man. |
| 12:45–13:40 | Reto 11: entrega DevOps. |
| 13:40–13:55 | Diagnóstico, seguridad y Telnet/FTP como contexto. |
| 13:55–14:00 | Limpieza de recursos y cierre. |

**No recortar:** regex básica, SSH, SCP y verificación.  
**Recortar primero:** ejecución del juego y detalles avanzados de DNS.

## Evidencias

1. Inventario y estructura con permisos.
2. Respaldo listado y restaurado.
3. Script de reporte con prueba de éxito y error.
4. Paquete transferido y hash verificado remotamente.

## Cobertura del temario comercial

| Apartados | Material | Sesión |
|---|---|---:|
| 1.1–1.4 | `01-introduccion-a-linux.md` | 1 |
| 2.1 | `02-un-enfoque-a-linux.md` | 3 |
| 3.1–3.6 | `03-estructura-del-sistema-de-archivos-de-linux.md` | 1–2 |
| 4.1 | `04-x-window.md` | 2 |
| 5.1–5.5 | `05-gnome.md` | 2 |
| 6.1–6.7 | `06-kde.md` | 2 |
| 7.1–7.21 | `07-el-shell.md` | 1–2 |
| 8.1–8.4 | `08-redirecciones-y-tuberias.md` | 3 |
| 9.1–9.3 | `09-ejecucion-de-programas.md` | 3 |
| 10.1–10.4 | `10-programas-de-comandos.md` | 3 |
| 11.1–11.11 | `11-scp-copias-remotas.md` | 4 |

Los nombres obsoletos del PDF —KFM, KDE Control Center, `egrep`, `fgrep`, Telnet y FTP— se explican en contexto y se relacionan con sus alternativas actuales; no se convierten en prácticas principales.
