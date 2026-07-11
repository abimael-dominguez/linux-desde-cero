# Plan docente — Consultor Linux desde cero v3

## Datos del curso

- Cuatro sesiones consecutivas de 09:00 a 14:00, hora de Ciudad de México.
- Receso de 11:00 a 11:30.
- 20 horas anunciadas; 18 horas efectivas.
- Referencia: Ubuntu Server 24.04 LTS x86-64.
- Laboratorio recomendado: una EC2 `t3.small`, 20 GiB `gp3`, Free account plan vigente.
- Compatibilidad: `t3.micro` con 2 GiB de swap y límites de memoria.
- Fallback: VM local Ubuntu 24.04 mediante VirtualBox.

Las fechas no se codifican en los capítulos para poder reutilizar el material. El instructor debe añadirlas al calendario del grupo antes de publicar el curso.

## Reglas de conducción

- Máximo 20 minutos seguidos de explicación sin una acción verificable.
- Antes de cada comando, nombrar usuario, host, directorio y recurso afectado.
- Presentar primero la sintaxis con marcadores y después el ejemplo copiable.
- No pedir al alumno que copie bloques que todavía no puede explicar.
- Toda acción privilegiada incluye comprobación previa y reversión.
- Los ejercicios se resuelven en el capítulo; los retos enlazan a `soluciones.md`.
- Los fixtures en `data/` son inmutables; las prácticas modifican `laboratorio/`.
- Si un alumno no confirma Free Tier vigente, cambia a VirtualBox antes de crear recursos.
- Programar el apagado de seguridad al comenzar cada sesión.

## Antes de la primera sesión

El instructor debe comprobar al menos tres días antes:

1. Los alumnos completaron [prerrequisitos](../prerrequisitos.md).
2. El Security Group permite únicamente SSH desde la IP del alumno.
3. La EC2 usa créditos de CPU `standard`.
4. El volumen raíz es `gp3`, 20 GiB y `DeleteOnTermination=true`.
5. `bash scripts/verificar-entorno.sh` no reporta errores.
6. El perfil `t3.micro` muestra 2 GiB de swap.
7. Existe un presupuesto y los avisos llegan al correo correcto.

No se dedicará la primera hora a recuperar cuentas, tarjetas o claves perdidas. Quien no complete el gate utiliza la VM local.

## Clase 1 — Operar Linux con seguridad

**Capítulos:** [1](../01-introduccion-entorno-linux.md), [2](../02-instalacion-configuracion-inicial.md), [3](../03-comandos-gestion-archivos.md) y [4](../04-permisos-usuarios-grupos.md).

| Hora | Actividad | Evidencia inmediata |
|---|---|---|
| 09:00–09:15 | Confirmar Free Tier, programar apagado y verificar Ubuntu | Perfil sin errores |
| 09:15–09:40 | Kernel, distribución, Open Source, nube y servidor | Modelo de capas explicado |
| 09:40–10:05 | Terminal, shell, GUI, EC2 y VirtualBox | Diferencias verbalizadas |
| 10:05–11:00 | FHS, rutas, `pwd`, `ls`, `cd`, `mkdir`, `touch`, `cp`, `mv`, `rm` seguro | Árbol dentro de `laboratorio/` |
| 11:00–11:30 | **Receso** | — |
| 11:30–12:10 | `cat`, `less`, `head`, `tail`, `file`, `stat`, `find`, `grep -E` | Incidente localizado en logs |
| 12:10–12:35 | Enlaces duros y simbólicos | Inodos comparados |
| 12:35–13:25 | Usuarios, grupos, UID/GID, `getent`, propietarios y permisos | Matriz `rwx` explicada |
| 13:25–13:45 | `sudo`, mínimo privilegio y validación de políticas | `sudo -l` interpretado |
| 13:45–13:55 | Hito: `deploy`, `ops`, `/srv/consultor-linux` | Permisos correctos |
| 13:55–14:00 | Evidencia, apagado y confirmación de estado | EC2 `Stopped` |

**No recortar:** navegación, búsquedas, permisos y diferencia usuario/grupo.
**Recortar primero:** comparación extensa de distribuciones e instalación gráfica.

## Clase 2 — Observar, conectar y administrar almacenamiento

**Capítulos:** [5](../05-procesos-gestion-sistema.md), [6](../06-redes-conectividad.md) y [9](../09-almacenamiento-respaldos.md).

| Hora | Actividad | Evidencia inmediata |
|---|---|---|
| 09:00–09:15 | Actualizar IP, programar apagado y recuperación activa | SSH restablecido |
| 09:15–09:55 | Procesos, PID/PPID, `ps`, `pgrep`, jobs y señales | Proceso controlado |
| 09:55–10:20 | Prioridad, memoria, CPU, `top`/`htop` | Consumo interpretado |
| 10:20–11:00 | systemd, `systemctl`, `journalctl` y fallo controlado | Causa encontrada en logs |
| 11:00–11:30 | **Receso** | — |
| 11:30–12:15 | `ip`, rutas, `ss`, `ping`, `tracepath`, `curl` | Diagnóstico por capas |
| 12:15–12:40 | DNS con `getent`, `dig`, `resolvectl`; DHCP y Netplan seguro | Resolución explicada |
| 12:40–13:10 | Claves SSH, huellas, SCP y SFTP | Archivo transferido y comparado |
| 13:10–13:45 | `lsblk`, `findmnt`, sparse file, loop, partición, LVM y montaje | LVM aislado montado |
| 13:45–13:55 | Limpiar LVM y generar reporte | Sin loop/VG residual |
| 13:55–14:00 | Apagado y estado | EC2 `Stopped` |

**No recortar:** logs, diagnóstico de red, SSH y validaciones del dispositivo loop.
**Recortar primero:** prioridad avanzada, servidor DNS y detalles internos de LVM.

## Clase 3 — Automatizar y recuperar

**Capítulos:** [7](../07-shell-automatizacion-basica.md), [8](../08-bash-cron.md) y respaldo de [9](../09-almacenamiento-respaldos.md).

| Hora | Actividad | Evidencia inmediata |
|---|---|---|
| 09:00–09:15 | Programar apagado y reconstruir un pipeline | Resultado reproducible |
| 09:15–09:50 | `stdin`, `stdout`, `stderr`, `>`, `>>`, `2>`, pipes y `tee` | Flujo dibujado |
| 09:50–10:15 | `&&`, `||`, códigos de salida y composición | Error controlado |
| 10:15–11:00 | Shebang, variables, comillas, argumentos y `printf` | Script parametrizado |
| 11:00–11:30 | **Receso** | — |
| 11:30–12:20 | `if`, `case`, `for`, `while`, funciones y validaciones | Pruebas éxito/error |
| 12:20–13:05 | Script de respaldo, tar, SHA-256 y manifiesto | Archivo verificable |
| 13:05–13:30 | Restauración en destino vacío | Contenido recuperado |
| 13:30–13:45 | Cron, rutas absolutas y comparación con timers | Entrada auditada |
| 13:45–13:55 | Descargar evidencia mediante SCP | Respaldo fuera de EC2 |
| 13:55–14:00 | Apagado y estado | EC2 `Stopped` |

**No recortar:** comillas, argumentos, estados, validación y restauración.
**Recortar primero:** `case`, timers de systemd y variantes de compresión.

## Clase 4 — Desplegar, proteger y entregar

**Capítulos:** [10](../10-servidores-servicios.md), [11](../11-virtualizacion-contenedores.md), [12](../12-seguridad-linux.md) y [13](../13-proyecto-final.md).

| Hora | Actividad | Evidencia inmediata |
|---|---|---|
| 09:00–09:15 | Revisar créditos, disco, memoria y apagado | Gate de despliegue |
| 09:15–09:40 | APT, DNF, Snap y ciclo de un servicio | Paquete/servicio identificados |
| 09:40–10:05 | Apache, Nginx, WordPress, MariaDB; DNS/DHCP/correo en contexto | Arquitectura dibujada |
| 10:05–10:30 | VM frente a contenedor; imagen, contenedor, red y volumen | Modelo explicado |
| 10:30–11:00 | Compose, secretos, límites, health checks y pull | Configuración validada |
| 11:00–11:30 | **Receso** | — |
| 11:30–12:10 | Levantar DB → WordPress → proxy y abrir túnel SSH | HTTP a través de Nginx |
| 12:10–12:35 | Logs, `docker stats`, puertos y fallo controlado | Incidente diagnosticado |
| 12:35–13:05 | UFW, SSH, AppArmor, actualizaciones y superficie expuesta | Hardening comprobado |
| 13:05–13:30 | Backup y restauración del stack | Datos recuperados |
| 13:30–13:45 | Runbook y presentación de evidencia | Entrega evaluable |
| 13:45–14:00 | Descargar respaldo, terminar EC2 y comprobar EBS | Cuenta sin recursos del curso |

**No recortar:** redes internas, puertos, secretos, logs, respaldo y limpieza AWS.
**Recortar primero:** instalación interactiva de WordPress y anexos DNS/DHCP/correo.

## Cobertura del temario v3

La siguiente matriz enumera cada apartado del PDF. “Contextual” significa que
se explica y compara, pero no se instala un servicio inseguro o costoso;
“aislada” significa que se valida configuración sin ligarla a la VPC.

| PDF | Tema oficial | Capítulo | Sesión | Modalidad y evidencia |
|---|---|---:|---|---|
| 1.1 | Linux en nube y servidores | 1 | 1 | Explicación breve + inventario real de Ubuntu/EC2 |
| 1.2 | Ubuntu, Debian, Fedora y CentOS | 1 | 1 | Comparación operativa; Ubuntu es la referencia |
| 1.3 | Ecosistema Open Source | 1 | 1 | Modelo de licencias, colaboración y trazabilidad |
| 1.4 | Shell frente a entorno gráfico | 1 | 1 | Práctica por SSH + demostración gráfica breve |
| 2.1 | Descarga e instalación Ubuntu/Debian | 2 + anexo VirtualBox | Precurso/1 | EC2 usa AMI; fallback instala ISO verificada |
| 2.2 | Máquinas virtuales con VirtualBox | 2 + anexo VirtualBox | Precurso/1 | Guía completa, NAT, SSH y demo |
| 2.3 | Estructura del sistema de archivos | 2 y 3 | 1 | Recorrido FHS y navegación comprobada |
| 2.4 | Usuarios y permisos iniciales | 2 y 4 | 1 | Creación real de `deploy`, `ops` y área compartida |
| 3.1 | `cd`, `ls`, `pwd` | 3 | 1 | Práctica resuelta en laboratorio desechable |
| 3.2 | Crear, copiar, mover y eliminar | 3 | 1 | Práctica con comprobación y reversión |
| 3.3 | `cat`, `less`, `head`, `tail` | 3 | 1 | Consulta de fixtures pequeños |
| 3.4 | `grep` y expresiones regulares | 3 | 1 | Búsqueda literal/extendida sobre logs |
| 3.5 | Enlaces duros y simbólicos | 3 | 1 | Inodos y destinos comprobados |
| 4.1 | Lectura, escritura y ejecución | 4 | 1 | Matriz `rwx` y pruebas como `deploy` |
| 4.2 | `chmod` y `chown` | 4 | 1 | Cambios mínimos con `stat` antes/después |
| 4.3 | Usuarios y grupos | 4 | 1 | `getent`, UID/GID, alta y membresía |
| 4.4 | `sudo` y políticas de acceso | 4 | 1 | `sudo -l`, regla mínima y validación segura |
| 5.1 | Iniciar y detener procesos | 5 | 2 | `sleep` propio, señales y PID verificado |
| 5.2 | Segundo plano y prioridad | 5 | 2 | Jobs, `bg`/`fg`, `nice` y finalización |
| 5.3 | `top`, `ps`, `htop` | 5 | 2 | Lectura de CPU, memoria, carga y procesos |
| 5.4 | Logs y troubleshooting | 5 | 2 | systemd/journal y fallo controlado |
| 6.1 | Configuración de red | 6 | 2 | Inventario real + Netplan bajo raíz falsa |
| 6.2 | `ping`, `ifconfig`/`ip`, `netstat`, `traceroute` | 6 | 2 | Herramientas actuales prácticas; antiguas contextualizadas |
| 6.3 | DNS y DHCP | 6 + anexos | 2/optativa | Consultas DNS reales; BIND/Kea aislados, sin daemon en VPC |
| 6.4 | SSH, SCP y FTP | 6 | 2 | SSH/SCP/SFTP prácticos; FTP sólo contexto histórico |
| 7.1 | Qué es el shell | 7 | 3 | Modelo terminal–shell–proceso y comprobación |
| 7.2 | Bash y otras shells | 7 | 3 | Tabla Bash/Dash/Zsh/Fish y prueba de intérprete |
| 7.3 | Comandos encadenados | 7 | 3 | `;`, `&&`, `||` y estados de salida |
| 7.4 | Redirecciones `>`, `>>`, `<` | 7 | 3 | stdin/stdout/stderr, pipes y `tee` |
| 7.5 | Script sencillo repetible | 7 | 3 | Resumen parametrizado de un log |
| 8.1 | Condicionales y bucles | 8 | 3 | `if`, `for`, `while` acotado y `case` |
| 8.2 | Scripts de automatización | 8 | 3 | Respaldo con argumentos, errores y hash |
| 8.3 | Cron | 8 | 3 | Candidato validado antes de instalarse |
| 9.1 | Particiones y sistemas de archivos | 9 | 2 | Imagen sparse y loop; nunca disco real |
| 9.2 | Montaje de dispositivos | 9 | 2 | ext4, `findmnt` y `fstab` alternativo |
| 9.3 | Introducción a LVM | 9 | 2 | PV/VG/LV manual + scripts con guardias |
| 9.4 | Copias de seguridad | 9 | 3 | Tar, SHA-256, exportación y restauración |
| 10.1 | APT, Yum y Snap | 10 | 4 | APT práctico; DNF/Yum y Snap comparados |
| 10.2 | Apache, Nginx y WordPress | 10 y 11 | 4 | Nginx del host + stack Compose completo |
| 10.3 | Servicios DNS y DHCP | 10 + anexos | 4/optativa | Arquitectura y configuración validada aislada |
| 10.4 | Correo y bases de datos | 10 y 11 | 4 | Correo contextual; MariaDB práctica en red interna |
| 11.1 | VirtualBox | 11 + anexo | Precurso/4 | Fallback completo y comparación |
| 11.2 | Docker y contenedores | 11 | 4 | Imágenes fijas, contenedores y ciclo de vida |
| 11.3 | VM frente a contenedor | 11 | 4 | Comparación de aislamiento y persistencia |
| 11.4 | Despliegue en Docker | 11 | 4 | Compose con redes, secretos, volúmenes y health checks |
| 12.1 | Hardening de servidores | 12 | Transversal/4 | Checklist aplicado con evidencia |
| 12.2 | UFW/iptables | 12 | 4 | UFW práctico sin perder SSH; iptables sólo lectura |
| 12.3 | Seguridad de usuarios y servicios | 4 y 12 | 1/4 | Mínimo privilegio, SSH y superficie de servicios |
| 12.4 | Backup y recuperación | 9, 12 y 13 | 3/4 | Respaldo, destrucción controlada y restore |
| 13.1 | Entorno listo para uso diario | 13 | 1–4 | Hitos progresivos y gate final |
| 13.2 | Usuarios, permisos y servicios de red | 13 | 1, 2 y 4 | Evidencias acumuladas del proyecto |
| 13.3 | Scripts de respaldo | 8 y 13 | 3–4 | Automatización probada y descarga por SCP |
| 13.4 | Documentación y checklist | 13 | 4 | Runbook, entrega, eliminación AWS y revisión de Billing |

## Evidencias y rúbrica

| Criterio | Peso |
|---|---:|
| Operación correcta y verificable | 25 % |
| Mínimo privilegio y superficie de red | 20 % |
| Automatización y manejo de errores | 20 % |
| Observabilidad y diagnóstico | 15 % |
| Respaldo y recuperación demostrados | 15 % |
| Runbook claro y limpieza final | 5 % |

No se evalúa la memorización de flags. Se evalúa que el alumno consulte ayuda, explique el efecto, compruebe el resultado y pueda revertirlo.

## Control de costos y cierre

Cada sesión debe cerrar con cuatro preguntas:

1. ¿Qué recurso AWS sigue existiendo?
2. ¿Qué deja de consumir cómputo al detener EC2?
3. ¿Qué continúa consumiendo almacenamiento?
4. ¿Qué evidencia confirma que la instancia quedó detenida o terminada?

Al terminar el curso, ningún alumno debe abandonar la videollamada sin comprobar: instancia `Terminated`, volumen raíz eliminado, ausencia de snapshots/Elastic IP y respaldo disponible localmente.
