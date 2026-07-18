# Validación segura de comandos y salidas

Validación realizada el 11 de julio de 2026 para comprobar que el material corresponde con Ubuntu 24.04 LTS sin hacer cambios persistentes en el sistema del instructor.

## Índice

- [Entornos utilizados](#entornos-utilizados)
- [Resultados](#resultados)
- [Comandos no ejecutados literalmente](#comandos-no-ejecutados-literalmente)
- [Adecuaciones derivadas de las pruebas](#adecuaciones-derivadas-de-las-pruebas)
- [Garantía de seguridad](#garantía-de-seguridad)

## Entornos utilizados

- Host: Ubuntu 24.04.4 LTS, únicamente para comandos de lectura y archivos temporales bajo `mktemp`.
- Contenedores desechables `ubuntu:24.04`: instalación de paquetes, usuarios de prueba, compilación y servidor OpenSSH.
- Todo contenedor se ejecutó con `--rm`; no se instalaron paquetes, usuarios o servicios en el host.

## Resultados

| Área | Comprobación | Resultado |
|---|---|---|
| Markdown | Enlaces locales, fences y correspondencia entre 11 retos y 11 soluciones | OK |
| Bash | `bash -n` y ShellCheck sobre todos los scripts | OK |
| Laboratorio | Preparación repetible y fixtures originales sin modificaciones | OK |
| Salidas del taller 12 | Conteos, CSV, temperaturas, arrays, modelos y funciones comparados con lo documentado | OK |
| Archivos y permisos | Rutas, enlaces duros/simbólicos, `chmod`, `stat`, `file`, `findmnt`, `lsblk` y `df` | OK |
| Texto e I/O | `grep`, `find`, `sed`, redirecciones, pipes, `tee`, `tar` y restauración | OK |
| Procesos | `ps`, estados STOP/CONT, `renice`, TERM y desaparición del PID | OK |
| Red | `ip`, `ss`, loopback con `ping`, HTTP con `curl`, servicios y DNS | OK |
| SSH | Servidor OpenSSH efímero, autenticación por clave y huella conocida | OK |
| SCP/SFTP | Copia local→remoto, remoto→local, sesión SFTP y comparación de archivos | OK |
| Integridad | SHA-256 generado localmente y verificado en el destino | OK |
| Compilación | Pac-Man: compilación, linkado, librería ncurses, arranque y `make clean` | OK |
| Cron | Sintaxis de las cuatro expresiones comprobada mediante dry-run de `crontab` | OK |
| Ubuntu limpio | Smoke test completo dentro de `ubuntu:24.04` | OK |

## Comandos no ejecutados literalmente

Los siguientes casos se validaron por sintaxis, herramientas equivalentes o un entorno local aislado:

- Creación de cuenta, instancia, security group e IP pública en AWS: dependen de una cuenta real y pueden generar costos.
- SSH hacia una EC2 pública: se reprodujo el mismo flujo contra OpenSSH dentro de un contenedor.
- Escritorios y MIME: se validaron consultas de tipo y asociación; las acciones de clic deben demostrarse en la VM gráfica del instructor.
- Impresión con `lpr`: el comando existe, pero no se envió un trabajo porque no hay una impresora de laboratorio configurada.
- Reinicio o modificación de servicios: sólo se consultó ayuda/estado y journal; no se reinició ningún servicio.
- `rm -i` y `rm -rI`: se revisaron opciones y rutas, sin automatizar confirmaciones destructivas.

## Adecuaciones derivadas de las pruebas

- Se documentaron los paquetes requeridos para `ping`, `dig`, `curl` y SSH en instalaciones mínimas.
- La regex de usuarios acepta letras, números, guion y guion bajo, conforme a los fixtures.
- Se aclaró la diferencia entre `ssh -p` y `scp -P`.
- Se documentó el caso en que `ssh.service` no existe.
- Se corrigió el espaciado real producido por `uniq -c`.
- La suma de comprobación usa sólo el basename para poder verificarse en el host remoto.

## Garantía de seguridad

- No se ejecutaron `mkfs`, `mkswap`, cambios de UUID, montajes, reglas de firewall o comandos de borrado sobre rutas del sistema.
- No se crearon usuarios, claves, servicios o paquetes persistentes en el host.
- Las claves SSH fueron temporales y desaparecieron con el contenedor.
- Las pruebas que mueven o eliminan archivos operaron únicamente sobre copias dentro de `laboratorio/` o directorios temporales.
