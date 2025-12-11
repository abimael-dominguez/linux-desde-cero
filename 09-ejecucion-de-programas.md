# 9. Ejecución de programas

En este capítulo exploraremos la ejecución de programas en Linux: monitoreo de procesos con `ps` y `top`, ejecución en segundo plano, gestión de recursos con `free`, prioridades con `nice` y `renice`, señales con `kill`, y más. Ejemplos prácticos incluidos para optimizar el rendimiento del sistema.

## Introducción
Los procesos son instancias en ejecución de programas con espacio de memoria propio. Aprenderemos a listar, monitorear y controlar procesos para una administración eficiente.

## Monitoreo de procesos con `ps`
El comando `ps` (process status) muestra información sobre procesos activos.

- `ps`: Lista procesos del usuario actual en la terminal actual.
- `ps -a`: Muestra procesos de todos los usuarios, excluyendo los de control de terminal.
- `ps -aux`: Muestra todos los procesos con detalles completos (usuario, PID, %CPU, %MEM, etc.).
- `ps -aux | grep bash`: Filtra procesos relacionados con bash.

Ejemplo:
```
$ ps -aux | head -10
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1  225564  9212 ?        Ss   08:00   0:02 /sbin/init
root         2  0.0  0.0      0     0 ?        S    08:00   0:00 [kthreadd]
...
```

Nota: `%MEM` indica el porcentaje de memoria usada; `%CPU` el porcentaje de CPU.

## Monitoreo en tiempo real con `top`
`top` proporciona una vista en tiempo real de procesos, actualizándose periódicamente.

- Ejecuta `top` para ver la lista interactiva.
- Presiona `Shift + M` para ordenar por uso de memoria (%MEM).
- Presiona `Shift + P` para ordenar por uso de CPU (%CPU).

Ejemplo de salida (simulada):
```
top - 10:00:00 up 2:00,  1 user,  load average: 0.00, 0.01, 0.05
Tasks: 100 total,   1 running,  99 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   2048.0 total,   1500.0 free,    300.0 used,    248.0 buff/cache
MiB Swap:   1024.0 total,   1024.0 free,      0.0 used.   1748.0 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
    1 root      20   0  225564   9212   6680 S   0.0   0.4   0:02.34 systemd
    2 root      20   0       0      0      0 S   0.0   0.0   0:00.00 kthreadd
...
```

## Matar procesos
Para terminar un proceso problemático:
- En `top`, presiona `k`, ingresa el PID y confirma con ENTER.

Alternativamente, usa `kill <PID>` o `kill -9 <PID>` para forzar.

Ejemplo:
```
$ kill 1234  # Envía señal SIGTERM
$ kill -9 1234  # Fuerza con SIGKILL
```

## Ver recursos disponibles con `free`
`free` muestra el uso de memoria RAM y swap.

Ejemplo:
```
$ free -h
              total        used        free      shared  buff/cache   available
Mem:           1.9G        300M        1.4G         10M        200M        1.5G
Swap:          1.0G          0B        1.0G
```

## 9.1 Ejecución en el fondo (background) &, KILL, NICE y NOHUP

## Ejecutar en background con &

Agrega `&` al final de un comando para ejecutarlo en background.

Ejemplo:
```
$ long-running-command &
[1] 1234
```

Para ejecutar programas sin bloquear la terminal:
- Ejecuta un comando seguido de `&` para enviarlo a background inmediatamente.
- Usa `Ctrl + Z` para suspender un proceso en ejecución y enviarlo a background.
- Reanuda con `% <número de job>` (ej. `%1`), `bg` (background) o `fg` (foreground).

Ejemplo:
```
$ vim archivo.txt  # Ejecuta vim
# Presiona Ctrl + Z
[1]+  Stopped                 vim archivo.txt
$ %1  # Reanuda en foreground
$ bg  # Reanuda en background
$ jobs  # Lista jobs activos
[1]+  Stopped                 vim archivo.txt
```

Nota: Los jobs se numeran automáticamente. Usa `jobs` para verlos.

### Diferencia entre Ctrl + Z y :q
- `Ctrl + Z`: Suspende el proceso (lo pausa) y lo envía a background. No termina el programa; puedes reanudarlo.
- `:q` (en editores como Vim): Sale del programa completamente, liberando recursos. Si hay cambios sin guardar, usa `:q!` para forzar.

Ejemplo práctico: En Vim, edita un archivo, presiona `Ctrl + Z` para pausar y volver a la shell, luego `%1` para continuar editando.

## KILL
Termina procesos. `kill -l` lista todas las señales disponibles (hay más de 60). Señales clave:
- SIGHUP (1): Reinicia el proceso (útil para recargar configuraciones).
- SIGKILL (9): Fuerza terminación inmediata (no puede ignorarse).
- SIGTERM (15): Pide al proceso terminar suavemente (por defecto).

Ejemplo:
```
$ kill 1234          # SIGTERM
$ kill -9 1234       # SIGKILL
$ killall firefox    # Mata todos los procesos de firefox
$ killall chrome     # Mata todos los procesos de chrome
```

## Prioridades de ejecución
Linux es un sistema multitarea: el kernel actúa como "policía de tráfico" para dar turnos a procesos en la CPU. Por defecto, todos los procesos son tratados igualitariamente. Sin embargo, en cargas altas (como codificación de video o backups), podemos intervenir para priorizar tareas importantes, como backups sobre servicios web.

Usos: Ajustar prioridades para minimizar impacto en sistemas compartidos, asegurando que tareas críticas (ej. bases de datos) no se ralenticen por procesos intensivos.

### NICE
Ajusta la prioridad al lanzar un proceso. Valores de -20 (alta prioridad, mejor) a 19 (baja). Como en golf, menor valor es mejor. Usuarios normales solo pueden aumentar (valores positivos); administradores pueden disminuir.

Ejemplo: Priorizar un checksum de disco para backup.
```
$ sudo nice -12 sha256sum /dev/sda16  # Alta prioridad
$ nice 12 sha256sum /dev/sda16       # Baja prioridad
```

Ver prioridades en `top`: Columna `NI` (nice). Procesos root a menudo tienen -20.

### RENICE
Cambia la prioridad de un proceso en ejecución sin interrumpirlo. Usa el PID; a veces requiere `-u <usuario>` para especificar el usuario.

Ejemplo: Cambiar prioridad de un proceso corriendo.
```
$ sudo renice 10 -p 5096  # Baja prioridad
$ sudo renice 5 -u usuario -p 5096  # Especificando usuario
```


## NOHUP
Ejecuta comandos inmunes a señales de hangup (cierre de sesión). Útil para procesos largos.

Ejemplo:
```
$ nohup long-command &
# Salida se guarda en nohup.out
```

## 9.2 Comando TIME
Mide el tiempo de ejecución de un comando (usuario, sistema, real).

Ejemplo:
```
$ time sleep 5
real    0m5.001s
user    0m0.000s
sys     0m0.000s
```

## 9.3 Comando TOP
Ya cubierto arriba, pero adicional: Presiona `q` para salir, `h` para ayuda.

## Conclusión y ejercicios
Practica con `ps`, `top` y jobs. Ejercicio: Ejecuta `vim` y `mc` (Midnight Commander), suspende con `Ctrl + Z`, lista con `jobs`, y reanuda.
