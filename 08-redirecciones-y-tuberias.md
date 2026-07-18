# 8. Redirecciones y tuberías

## Índice

- [Objetivos](#objetivos)
- [Antes de empezar](#antes-de-empezar)
- [8.1 Redirecciones](#81-redirecciones)
- [8.2 Tuberías](#82-tuberías)
- [8.3 Bifurcación con `tee`](#83-bifurcación-con-tee)
- [8.4 Redirección de errores](#84-redirección-de-errores)
- [Práctica guiada: reporte de incidentes](#práctica-guiada-resuelta--reporte-de-incidentes)
- [Errores frecuentes](#errores-frecuentes)
- [Reto 8](#reto-8--pipeline-auditable)

## Objetivos

- Redirigir `stdout` y `stderr` por separado o juntos.
- Construir pipelines legibles.
- Duplicar una salida con `tee`.
- Producir reportes sin perder diagnósticos.

## Antes de empezar

Ejecuta todo desde la raíz del curso. Prepararemos `laboratorio/io` y usaremos `data/dummy_logs.txt` como entrada; los archivos originales de `data/` no se modifican.

```bash
cd ~/linux-desde-cero
mkdir -p laboratorio/io
```

> **Continuidad entre sesiones.** `laboratorio/io` es exclusivo de esta parte de la Clase 3 y puede crearse aunque conserves `laboratorio/shell` o evidencia de la Clase 2. `data/dummy_logs.txt` es un archivo versionado de entrada: compruébalo con `ls data/dummy_logs.txt`; si falta, no lo sustituyas por un archivo vacío. Verifica primero `pwd` y recupera el repositorio si fuera necesario.

## 8.1 Redirecciones

| Operador | Acción |
|---|---|
| `>` | crea/sobrescribe la salida |
| `>>` | agrega al final |
| `<` | toma entrada desde archivo |
| `2>` | redirige errores |
| `2>&1` | envía descriptor 2 al destino actual de 1 |

```bash
mkdir -p laboratorio/io
printf '%s\n' alpha beta gamma > laboratorio/io/entrada.txt
wc -l < laboratorio/io/entrada.txt > laboratorio/io/conteo.txt
ls /etc/hosts /ruta-inexistente \
  > laboratorio/io/encontrados.txt \
  2> laboratorio/io/errores.txt
```

`/etc/hosts` existe y debe quedar en `encontrados.txt`. `/ruta-inexistente` es falsa a propósito y su mensaje debe quedar en `errores.txt`. Aunque `ls` termina con error parcial, ambos archivos se crean.

Compruébalo:

```bash
cat laboratorio/io/encontrados.txt
cat laboratorio/io/errores.txt
```

`>` elimina el contenido previo. Usa `>>` cuando realmente deseas acumular.

### Orden de redirecciones

```bash
comando > salida.log 2>&1
```

Primero conecta `stdout` al archivo y luego conecta `stderr` al mismo destino. El orden puede cambiar el resultado.

`comando` y `salida.log` son marcadores conceptuales. Un ejemplo resuelto y seguro es:

```bash
ls /etc/hosts /ruta-inexistente > laboratorio/io/salida-completa.log 2>&1 || true
cat laboratorio/io/salida-completa.log
```

`|| true` se usa aquí porque el error es intencional; no debe añadirse indiscriminadamente a comandos reales.

## 8.2 Tuberías

Una tubería conecta `stdout` del comando izquierdo con `stdin` del derecho:

```bash
grep -E 'WARN|ERROR' data/dummy_logs.txt | sort | nl -ba
```

- `|`: conecta procesos.
- `nl -ba`: numera incluso líneas vacías.
- Cada etapa debe poder verificarse de forma independiente.

El estado normal de un pipeline corresponde al último comando. En scripts robustos se usa `set -o pipefail` para detectar fallos anteriores.

## 8.3 Bifurcación con `tee`

```bash
grep -E 'WARN|ERROR' data/dummy_logs.txt \
  | tee laboratorio/io/incidentes.txt \
  | wc -l
```

`tee` copia la entrada al archivo y también la envía al siguiente comando. `tee -a` agrega en lugar de sobrescribir.

## 8.4 Redirección de errores

```bash
find /etc -type f -name '*.conf' \
  > laboratorio/io/configs.txt \
  2> laboratorio/io/find-errors.txt
```

No descartes errores con `/dev/null` hasta entenderlos. Durante aprendizaje y automatización, conservar diagnósticos facilita depurar.

## Práctica guiada resuelta — Reporte de incidentes

La práctica crea `reporte.txt` y `reporte-errors.log`. No necesitas crear ninguno antes; las redirecciones y `tee` lo hacen.

```bash
mkdir -p laboratorio/io

{
  printf 'REPORTE DE INCIDENTES\n'
  printf 'Generado: %s\n\n' "$(date --iso-8601=seconds)"
  grep -E 'WARN|ERROR' data/dummy_logs.txt
} 2> laboratorio/io/reporte-errors.log \
  | tee laboratorio/io/reporte.txt

printf 'Total: '
grep -Ec 'WARN|ERROR' laboratorio/io/reporte.txt
```

Explicación:

- `{ ...; }` agrupa salidas.
- La fecha se calcula al ejecutar.
- `stderr` queda separado en `reporte-errors.log`.
- `tee` permite ver y guardar.
- `grep -c` cuenta líneas coincidentes.

La salida final debe mostrar `Total: 3`, porque el fixture contiene dos `ERROR` y un `WARN`.

## Errores frecuentes

- Sobrescribir un archivo con `>` cuando se quería `>>`.
- Redirigir al mismo archivo que todavía se está leyendo.
- Crear pipelines largos sin probar cada segmento.
- Ocultar `stderr` y confundir una salida vacía con éxito.

## Reto 8 — Pipeline auditable

[Ver respuesta](instructor/soluciones.md#respuesta-reto-8)

Crea `laboratorio/reto8/usuarios.txt` con los usuarios de `data/dummy_logs.txt`, ordenados y sin duplicados. Guarda errores en `laboratorio/reto8/errores.log` y muestra en terminal el número de usuarios únicos sin releer manualmente el archivo original.

### Criterios de comprobación

- Usa al menos una tubería y `tee`.
- Datos y errores están separados.
- El archivo final contiene sólo nombres únicos.
- El conteo coincide con las líneas del archivo final.

## Checklist

- [ ] Distingo `>`, `>>`, `2>` y `2>&1`.
- [ ] Construyo y pruebo pipelines por etapas.
- [ ] Uso `tee` para observar y guardar.
