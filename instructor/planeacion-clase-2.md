# Planeación operativa — Clase 2

## Índice

- [Intención de la sesión](#intención-de-la-sesión)
- [Ajustes derivados del feedback](#ajustes-derivados-del-feedback)
- [Acuerdo de ritmo](#acuerdo-de-ritmo)
- [Preparación previa](#preparación-previa)
- [Secuencia de enseñanza](#secuencia-de-enseñanza)
- [Agenda minuto a minuto](#agenda-minuto-a-minuto)
- [Comandos mínimos de la sesión](#comandos-mínimos-de-la-sesión)
- [Checkpoints](#checkpoints)
- [Orden de recorte](#orden-de-recorte)
- [Contingencias](#contingencias)
- [Mensaje breve para el grupo](#mensaje-breve-para-el-grupo)

## Intención de la sesión

La prioridad no es recorrer todas las páginas del material, sino que cada alumno pueda ejecutar, explicar y comprobar un flujo útil. Al terminar la sesión podrá:

1. consultar partes de un archivo con `head`, `tail` y `less`;
2. buscar contenido con `grep` y archivos con `find`;
3. distinguir el tamaño de una ruta (`du`) del espacio de un sistema de archivos (`df`);
4. crear, listar, restaurar y verificar un respaldo `tar.gz`;
5. relacionar una operación gráfica con su comando equivalente.

El PDF de la Clase 2 es una **guía de consulta**. No se proyecta ni se recorre de principio a fin.

## Ajustes derivados del feedback

| Señal del grupo | Ajuste observable en esta clase |
|---|---|
| El ritmo se percibió rápido. | Ninguna explicación continua excede ocho minutos. Cada concepto incluye tiempo para que el alumno lo ejecute. |
| Cuesta seguir la presentación. | Se proyecta principalmente la terminal. El material se abre sólo para un diagrama, una sintaxis o una referencia puntual. |
| Se asumieron conocimientos previos. | La sesión comienza con diagnóstico sin calificación; se recuperan rutas y permisos antes de introducir comandos. |
| Faltó espacio para preguntas. | Hay checkpoints a las 10:45, 12:30 y 13:40, además de un semáforo después de cada microciclo. |
| Algunos alumnos avanzan más rápido. | Las extensiones `grep -E`, filtros adicionales de `find` y personalización de escritorios son opcionales y no frenan al grupo base. |

## Acuerdo de ritmo

Al iniciar, decir:

> Leí el comentario del grupo. Hoy vamos a trabajar un comando a la vez: primero explico para qué sirve, lo hacemos juntos, ustedes cambian un dato y comprobamos el resultado. No avanzaremos por número de páginas. Si algo no queda claro, marquen amarillo o rojo y lo retomamos.

Usar el chat o reacciones como semáforo:

- **Verde:** terminé y puedo explicar qué ocurrió.
- **Amarillo:** sigo trabajando o tengo una duda concreta.
- **Rojo:** necesito que repitamos el paso.

No comenzar el siguiente microciclo hasta que al menos 80 % esté en verde. Si hay más de 20 % en amarillo o rojo, repetir con otro archivo y recortar un tema opcional; no acelerar para recuperar el horario.

## Preparación previa

- Confirmar que `data/dummy_logs.txt` y `data/specials.txt` existen; son datos versionados y no se reemplazan por archivos vacíos.
- Conservar `laboratorio/` si contiene evidencia de la Clase 1. No ejecutar `bash ejercicios-bash-scripting/preparar-lab.sh` para iniciar esta sesión, pues reinicia esa carpeta.
- Abrir una terminal con fuente grande y una segunda terminal limpia para resolver incidencias.
- Dejar lista la VM gráfica. No instalar GNOME ni KDE durante la clase.
- Compartir el enlace o archivo del material antes de comenzar para que funcione como consulta.
- Tener abierto este documento y no la secuencia completa de 57 páginas.

## Secuencia de enseñanza

Cada microciclo sigue la misma rutina de 18–20 minutos:

1. **Contexto (2 min):** qué problema resuelve el comando.
2. **Modelo (5–6 min):** sintaxis general, ejemplo y salida esperada.
3. **Práctica (7–8 min):** el alumno repite y modifica un dato.
4. **Comprobación (3–4 min):** una pregunta breve y semáforo.

Antes de ejecutar cualquier comando, pedir que identifiquen:

- qué archivo o ruta es la entrada;
- qué resultado esperan;
- si el comando sólo consulta o modifica algo.

## Agenda minuto a minuto

| Hora | Conducción y evidencia |
|---|---|
| 09:00–09:10 | Reconocer el feedback, explicar el acuerdo de ritmo y probar el semáforo. |
| 09:10–09:30 | Recuperación activa: `pwd`, `ls -ld data` y `ls -l data/dummy_logs.txt`. Preguntar: “¿dónde estoy?, ¿es archivo o directorio?, ¿quién puede escribir?”. Reexplicar rutas o permisos sólo donde el diagnóstico lo indique. |
| 09:30–09:50 | Microciclo 1: `cat` sólo para archivos pequeños; `head -n 3`, `tail -n 2` y `less`. Todos deben entrar a `less`, buscar con `/ERROR` y salir con `q`. |
| 09:50–10:10 | Microciclo 2: búsqueda literal con `grep -n 'ERROR'` y después `grep -ni 'warn'`. Cada alumno cambia el patrón. `grep -E` queda como extensión. |
| 10:10–10:30 | Microciclo 3: `find data -maxdepth 2 -type f -name '*.csv'`. Contrastar “buscar dentro” (`grep`) con “buscar archivos” (`find`). |
| 10:30–10:45 | Microciclo 4: `du -sh data` frente a `df -hT .`. Pedir una predicción antes de ejecutar. |
| 10:45–11:00 | Checkpoint 1 y clínica. El alumno resuelve: “encuentra los CSV y luego busca `ERROR` dentro del log”. No agregar contenido nuevo. |
| 11:00–11:30 | **Receso.** |
| 11:30–11:45 | Modelo mental de `tar`: archivos de entrada → paquete → listado → directorio de restauración. Presentar `tar [operación] [archivo] [entradas]`; todavía no ejecutar el bloque completo. |
| 11:45–12:05 | “Yo hago / hacemos”: crear el respaldo y listarlo. Antes de Enter, identificar entradas y nombre del paquete. |
| 12:05–12:30 | “Tú haces”: restaurar en un directorio nuevo y verificar los hashes. Trabajar por parejas; quien termina explica el flujo a su compañero. |
| 12:30–12:45 | Checkpoint 2 y clínica de errores. Repetir verbalmente la secuencia crear → listar → restaurar → verificar. |
| 12:45–13:05 | Inspección sin cambios: `lsblk -f`, `findmnt /` y `df -hT /`. Enfatizar dispositivo, punto de montaje y capacidad; no formatear discos. |
| 13:05–13:20 | Un solo diagrama para aplicación → toolkit → X.Org/Wayland → kernel → pantalla. GNOME y KDE son escritorios, no “Linux” ni el servidor gráfico. |
| 13:20–13:40 | Demostración de escritorio: recorrido breve de GNOME con Actividades y Files; después, Plasma con Panel, Kickoff, Dolphin y herramientas, sin repetir comandos. |
| 13:40–13:52 | Resolver dudas breves sobre KDE y recoger la evidencia final del respaldo. |
| 13:52–14:00 | Exit ticket de tres preguntas y cierre. Informar qué apartados quedaron como consulta, no como deuda del alumno. |

## Comandos mínimos de la sesión

Ejecutarlos desde la raíz `~/linux-desde-cero`.

### Recuperación y consulta

```bash
pwd
ls -ld data
ls -l data/dummy_logs.txt
head -n 3 data/dummy_logs.txt
tail -n 2 data/dummy_logs.txt
less data/dummy_logs.txt
```

Dentro de `less`, usar `/ERROR` y después `q`.

### Buscar y medir

```bash
grep -n 'ERROR' data/dummy_logs.txt
grep -ni 'warn' data/dummy_logs.txt
find data -maxdepth 2 -type f -name '*.csv'
du -sh data
df -hT .
```

### Crear, listar, restaurar y verificar

Ejecutar una línea, comprobar el resultado y sólo entonces continuar:

```bash
mkdir -p laboratorio/shell/restaurado
tar -czf laboratorio/shell/respaldo-clase2.tar.gz data/dummy_logs.txt data/specials.txt
tar -tzf laboratorio/shell/respaldo-clase2.tar.gz
tar -xzf laboratorio/shell/respaldo-clase2.tar.gz -C laboratorio/shell/restaurado
sha256sum data/dummy_logs.txt laboratorio/shell/restaurado/data/dummy_logs.txt
sha256sum data/specials.txt laboratorio/shell/restaurado/data/specials.txt
```

Los dos hashes de cada pareja deben coincidir. `sha256sum` se usa aquí únicamente como comprobación visible; no se profundiza todavía en criptografía.

## Checkpoints

### Checkpoint 1 — antes del receso

Sin copiar un bloque completo, el alumno debe poder:

1. mostrar las primeras tres líneas del log;
2. localizar las líneas que contienen `ERROR`;
3. encontrar archivos con extensión `.csv`;
4. explicar en una frase la diferencia entre `du` y `df`.

### Checkpoint 2 — respaldo

Pedir que señale en la terminal:

- el archivo `respaldo-clase2.tar.gz`;
- el listado del paquete antes de extraerlo;
- los archivos restaurados en una ruta diferente;
- dos hashes iguales para cada original y restaurado.

### Exit ticket

1. ¿Qué diferencia práctica hay entre `grep` y `find`?
2. ¿Qué comando lista un `tar.gz` sin extraerlo?
3. Si `du` y `df` muestran números distintos, ¿significa necesariamente que uno falló?

Semáforo final: verde = lo haría solo; amarillo = lo haría con la guía; rojo = necesito repetirlo. Usar el resultado para abrir la Clase 3.

## Orden de recorte

Si el grupo necesita más tiempo, recortar en este orden:

1. personalización de GNOME/KDE;
2. demostración detallada de KDE, dejando sólo Panel, Kickoff, Dolphin y una diferencia frente a GNOME;
3. `pr`, `lpr`, multimedia e instalación de escritorios: sólo referencia en el material;
4. opciones `grep -E`, `grep -F` y filtros avanzados de `find`;
5. detalles internos de X.Org y Wayland.

No recortar la práctica de búsqueda ni la secuencia crear → listar → restaurar → verificar. Los temas opcionales no se “recuperan” hablando más rápido.

## Contingencias

- Si falla EC2, continuar en WSL, VM, Multipass o contenedor con los mismos datos.
- Si falla la VM gráfica, explicar el diagrama y hacer la equivalencia GUI/CLI con capturas o como demostración del instructor; no instalar un escritorio en vivo.
- Si un alumno se pierde, volver primero a `pwd` y a la ruta de entrada. Evitar resolver con `rm -rf`, `chmod 777` o pegando un bloque más grande.
- Para alumnos adelantados, ofrecer `grep -Ei 'warn|error'`, un segundo patrón de `find` o el Reto 7 sin interrumpir al grupo base.

## Mensaje breve para el grupo

> Gracias por compartir el comentario sobre el ritmo de la primera clase. En esta sesión trabajaremos en bloques más cortos, con práctica después de cada comando y pausas visibles para preguntas. El PDF será material de consulta; no es necesario seguirlo página por página. Al final revisaremos juntos una evidencia concreta de búsqueda y restauración.
