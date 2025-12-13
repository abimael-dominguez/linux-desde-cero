# 9. Ejecución de programas

En este capítulo exploraremos la ejecución de programas en Linux: monitoreo de procesos con `ps` y `top`, ejecución en segundo plano, gestión de recursos con `free`, prioridades con `nice` y `renice`, señales con `kill`, y más. Ejemplos prácticos incluidos para optimizar el rendimiento del sistema.

## Índice

- [9. Ejecución de programas](#9-ejecución-de-programas)
  - [Introducción](#introducción)
  - [Monitoreo de procesos con `ps`](#monitoreo-de-procesos-con-ps)
  - [Monitoreo en tiempo real con `top`](#monitoreo-en-tiempo-real-con-top)
  - [Matar procesos](#matar-procesos)
  - [Ver recursos disponibles con `free`](#ver-recursos-disponibles-con-free)
  - [9.1 Ejecución en el fondo (background) &, KILL, NICE y NOHUP](#91-ejecución-en-el-fondo-background--kill-nice-y-nohup)
    - [Ejecutar en background con &](#ejecutar-en-background-con-)
    - [Diferencia entre Ctrl + Z y :q](#diferencia-entre-ctrl--z-y-q)
    - [KILL](#kill)
    - [Prioridades de ejecución](#prioridades-de-ejecución)
      - [NICE](#nice)
      - [RENICE](#renice)
    - [NOHUP](#nohup)
  - [9.2 Comando TIME](#92-comando-time)
  - [9.3 Comando TOP](#93-comando-top)
  - [Conclusión y ejercicios](#conclusión-y-ejercicios)

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
$ vim archivo.txt  # Ejecuta vim (o para mandae directo a background `vim archivo.txt &`)
# Presiona Ctrl + Z (si estás dentro de vim)
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

### Ejercicio práctico: Gestionar procesos con kill, nice y renice
1. Crea un script simple para darle un nombre identificable al proceso:
   ```
   $ nano mi_proceso.sh
   #!/bin/bash
   echo "Proceso en ejecución..."
   sleep 300  # Espera 300 segundos (5 minutos) para simular un proceso largo
   ```
   ```
   $ chmod +x mi_proceso.sh
   ```

2. Inicia el proceso con baja prioridad usando `nice`:
   ```
   $ nice -n 10 ./mi_proceso.sh &
   $ jobs  # Nota el job number
   ```

3. Verifica su prioridad en `top` (columna NI) o con `ps`:
   ```
   $ ps -o pid,ni,cmd | grep mi_proceso
   $ top -p <PID>
   ```

4. Cambia la prioridad del proceso en ejecución con `renice`:
   ```
   $ sudo renice -5 -p <PID>
   $ top -p <PID> # Verifica el cambio con top
   $ ps -o pid,ni,cmd | grep mi_proceso  # Verifica el cambio
   ```

5. Termina el proceso suavemente con `kill`:
   ```
   $ kill <PID>
   $ ps -o pid,ni,cmd | grep mi_proceso  # Debería desaparecer
   ```

6. Si no responde, fuerza la terminación:
   ```
   $ kill -9 <PID>
   ```

7. Experimenta con diferentes valores de nice y señales de kill para entender su impacto en el sistema.


## NOHUP
Ejecuta comandos inmunes a señales de hangup (cierre de sesión). Útil para procesos largos.

Ejemplo:
```
$ nohup long-command &
# Salida se guarda en nohup.out
```

### Ejercicio práctico: Ejecutar un proceso largo con nohup
1. Crea un script simple que simule un proceso largo:
   ```
   $ nano script_largo.sh
   #!/bin/bash
   echo "Iniciando proceso largo..."
   for i in {1..10}; do
       echo "Iteración $i - $(date)"
       sleep 60  # Espera 1 minuto por iteración
   done
   echo "Proceso completado."
   ```

2. Haz el script ejecutable y ejecútalo con `nohup`:
   ```
   $ chmod +x script_largo.sh
   $ nohup ./script_largo.sh &
   ```

3. Verifica que esté corriendo en background:
   ```
   $ jobs
   $ ps aux | grep script_largo
   ```

4. Cierra la sesión (o abre una nueva terminal) y verifica que el proceso sigue corriendo:
   ```
   $ ps aux | grep script_largo
   ```

5. Revisa la salida en `nohup.out`:
   ```
   $ tail -f nohup.out
   ```

6. Una vez completado, elimina el archivo de salida si deseas:
   ```
   $ rm nohup.out
   ```

Este ejercicio demuestra cómo `nohup` permite que procesos continúen ejecutándose incluso después de cerrar la sesión, guardando la salida en un archivo.

## 9.2 Comando TIME
Mide el tiempo de ejecución de un comando (usuario, sistema, real).

Ejemplo:
```
$ time sleep 5
real    0m5.001s
user    0m0.000s
sys     0m0.000s
```

### Ejercicio práctico: Medir tiempos de ejecución
1. Mide el tiempo de un comando simple:
   ```
   $ time ls -la /etc
   ```

2. Crea un script CPU-intensivo y mide su tiempo:
   ```
   $ nano cpu_intensivo.sh
   #!/bin/bash
   for i in {1..100000}; do
       echo $i > /dev/null
   done
   ```
   ```
   $ chmod +x cpu_intensivo.sh
   $ time ./cpu_intensivo.sh
   ```

3. Mide el tiempo de una operación I/O (copia de archivos):
   ```
   $ time cp -r /etc /tmp/etc_backup
   ```

4. Compara los tiempos: Observa cómo `real` (tiempo total) difiere de `user` (CPU en modo usuario) y `sys` (CPU en modo sistema). En tareas CPU-intensivas, `user` será alto; en tareas I/O, `real` será mucho mayor que `user + sys`.

5. Experimenta con `time` en combinación con otros comandos, como `find` o `grep` en archivos grandes, para ver el impacto en el rendimiento.

## 9.3 Comando TOP
Ya cubierto arriba, pero adicional: Presiona `q` para salir, `h` para ayuda.

## Conclusión y ejercicios
Practica con `ps`, `top` y jobs. Ejercicio: Ejecuta `vim` y `mc` (Midnight Commander), suspende con `Ctrl + Z`, lista con `jobs`, y reanuda.
