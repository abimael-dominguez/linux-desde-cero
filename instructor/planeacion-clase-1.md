# Planeación operativa — Clase 1

## Índice

- [Propósito](#propósito)
- [Acuerdo de ritmo](#acuerdo-de-ritmo)
- [Agenda sugerida](#agenda-sugerida)
- [Recortes seguros](#recortes-seguros)

## Propósito

Al terminar la sesión, el alumno identifica su equipo Linux, sabe qué identidad está usando y puede navegar, crear, copiar, mover, identificar, enlazar y proteger archivos de práctica. No se busca memorizar todas las opciones: se busca que pueda explicar qué ruta cambiará y qué espera observar.

## Acuerdo de ritmo

Cada bloque usa: **para qué sirve → demostración breve → práctica individual → comprobación**. Ninguna explicación continua supera ocho minutos. Usar semáforo en chat o reacciones: verde = terminé, amarillo = sigo, rojo = repitamos.

## Agenda sugerida

| Hora | Actividad y evidencia |
|---|---|
| 09:00–09:20 | Diagnóstico sin calificación: `whoami`, `hostname`, `pwd` y `/etc/os-release`. |
| 09:20–09:45 | Linux, distribución, terminal y shell; cada alumno identifica qué componente está observando. |
| 09:45–10:15 | Usuarios, grupos y `sudo`; lectura de `id` y `getent`, sin crear cuentas todavía. |
| 10:15–10:45 | Consulta segura de paquetes con `apt search` y `apt show`; instalación de `tree` sólo tras explicar efecto y permiso. |
| 10:45–11:00 | Checkpoint: distinguir kernel, distribución, usuario y grupo. |
| 11:00–11:30 | **Receso.** |
| 11:30–11:55 | Rutas, tipos de archivo y jerarquía; localizar `/home`, `/etc`, `/var` y `/tmp`. |
| 11:55–12:35 | `pwd`, `ls`, `cd`, `mkdir`, `touch`, `cp` y `mv`: un comando por ciclo. |
| 12:35–13:05 | `file`, enlaces y permisos; comprobar antes y después de cada cambio. |
| 13:05–13:35 | Práctica guiada: carpeta de servicio, configuración, script y enlace. |
| 13:35–13:55 | Reto 3 y clínica de errores. |
| 13:55–14:00 | Exit ticket: ruta, permiso y operación segura. |

## Recortes seguros

Si el grupo requiere más tiempo, dejar como lectura: comparación extensa de distribuciones, detalles de NSS/LDAP, creación de usuario temporal y opciones avanzadas de `tree`. No recortar navegación, copia/movimiento, enlaces ni permisos.
