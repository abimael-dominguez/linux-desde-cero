# PDF del curso — Linux desde cero

## Índice

- [Compilar PDFs](#compilar-pdfs)
- [Requisitos](#requisitos)
- [Validar el resultado](#validar-el-resultado)

## Compilar PDFs

Cada carpeta de clase contiene el generador reproducible, el HTML intermedio, el PDF final y un script de compilación.

| Clase | Contenido | Compilar |
|---|---|---|
| `clase_1` | Fundamentos, archivos y permisos | `bash docs/pdf/clase_1/build.sh` |
| `clase_2` | Shell útil y escritorios | `bash docs/pdf/clase_2/build.sh` |
| `clase_3` | I/O, procesos y Bash | `bash docs/pdf/clase_3/build.sh` |
| `clase_4` | Regex, red y copias remotas | `bash docs/pdf/clase_4/build.sh` |

Los generadores leen directamente los Markdown de la raíz del repositorio. Los recursos compartidos de marca, tipografías y renderizado viven en `shared/`; no se requieren dependencias globales de Node.

## Requisitos

Requisitos de compilación: Node.js, Google Chrome, `pdfinfo` y `pdftotext`.

Para regenerar todo el curso: `bash docs/pdf/build-all.sh`.

## Validar el resultado

Para comprobar estructura, tamaño de página y destinos internos: `bash docs/pdf/validate-all.sh`.
