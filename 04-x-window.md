# 4. X Window y Wayland

## Índice

- [Objetivos](#objetivos)
- [Antes de continuar](#antes-de-continuar)
- [4.1 X Window y Wayland](#41-x-window-y-wayland)
- [Práctica guiada: mapa de tu sesión](#práctica-guiada-resuelta--mapa-de-tu-sesión)
- [Errores frecuentes](#errores-frecuentes)
- [Reto 4](#reto-4--mapa-de-la-sesión-gráfica)

## Objetivos

- Distinguir Linux, shell, terminal, protocolo gráfico, compositor y escritorio.
- Identificar la sesión gráfica sin memorizar componentes históricos.
- Decidir cuándo un servidor necesita GUI y cuándo conviene administrarlo por SSH.

## Antes de continuar

Este capítulo se trabaja en una VM con escritorio abierto, no en la terminal SSH de EC2. La EC2 sigue siendo útil para los comandos de servidor; la VM gráfica sirve para observar cómo una aplicación llega a una pantalla.

```bash
cd ~/linux-desde-cero
pwd
```

No necesitas archivos de la Clase 1 para esta demostración. Si `laboratorio/` existe, conserva su contenido. El reto de este capítulo crea `laboratorio/sesion-grafica.txt` desde un editor gráfico; si la carpeta no existe, puedes crearla con `mkdir -p laboratorio`.

> **Cuidado.** No instales GNOME, KDE ni un servidor gráfico en una EC2 sólo para seguir la práctica. Si no tienes VM gráfica, observa la demostración del instructor y usa el diagrama.

## 4.1 X Window y Wayland

> **Situación real.** Una persona de soporte usa una aplicación con ventanas en su laptop, mientras que una persona de operaciones administra por SSH un servidor sin pantalla. Ambos usan Linux, pero no necesitan la misma capa gráfica.

Linux es el kernel y el sistema base. Un escritorio como GNOME o KDE Plasma organiza ventanas, menús y configuración. X.Org y Wayland son formas de comunicar aplicaciones gráficas con la pantalla, teclado y ratón. No son sinónimos.

```text
aplicación → toolkit → X.Org o compositor Wayland → kernel/controladores → pantalla
                         ↑
                  teclado y ratón
```

### Modelo mental: quién hace qué

| Componente | Responsabilidad | Ejemplo práctico |
|---|---|---|
| Aplicación | Hace el trabajo visible | navegador, editor, Files/Dolphin |
| Toolkit | Dibuja controles y ventanas | GTK o Qt |
| X.Org o Wayland | Protocolo/canal gráfico | comunica app, entrada y pantalla |
| Compositor | Ordena ventanas y efectos | GNOME Shell o KWin |
| Escritorio | Experiencia completa de usuario | GNOME o KDE Plasma |
| Shell/terminal | Ejecuta comandos de texto | Bash en GNOME Terminal o Konsole |

> **Comprueba.** GNOME y KDE no reemplazan a Linux; son entornos de escritorio. Una terminal puede existir dentro de ambos y también en un servidor sin escritorio.

### Identificar una sesión

Abre GNOME Terminal o Konsole **dentro de la VM gráfica**. Las variables que empiezan con `$` son valores que la sesión ya conoce; no sustituyas tú el signo `$`.

```bash
echo "$XDG_SESSION_TYPE"
echo "$XDG_CURRENT_DESKTOP"
```

La primera línea suele mostrar `wayland` o `x11`. La segunda puede mostrar `GNOME`, `KDE`, `ubuntu:GNOME` u otro nombre. Los valores cambian según la distribución y la sesión elegida al iniciar.

#### Qué significa una salida vacía

Si una variable no muestra nada, probablemente ejecutaste el comando desde SSH, una consola virtual o una sesión sin escritorio. Eso no indica que Linux esté roto: indica que no hay una sesión gráfica que describir.

### Servidor frente a escritorio

Un servidor de aplicación normalmente se administra por SSH porque no necesita ventanas para atender peticiones. Evitar una GUI reduce paquetes instalados, memoria usada, actualizaciones y superficie de ataque. Una estación de soporte o desarrollo sí puede usar GUI para editar, revisar archivos o ejecutar herramientas visuales.

| Si necesitas… | Usa principalmente… |
|---|---|
| operar una EC2, revisar logs, cambiar configuración | SSH y terminal |
| asistir a una persona local, mover documentos, ajustar pantalla | escritorio gráfico |
| automatizar despliegues o tareas repetibles | comandos y scripts reproducibles |

## Práctica guiada resuelta — Mapa de tu sesión

1. En la VM gráfica, abre una terminal.
2. Ejecuta las dos líneas de identificación.
3. Abre el menú de aplicaciones y localiza una aplicación visible, por ejemplo Files o Konsole.
4. Abre un editor de texto gráfico, escribe protocolo, escritorio y dos aplicaciones visibles, y guarda el archivo como `~/linux-desde-cero/laboratorio/sesion-grafica.txt`.

El archivo es una evidencia humana, no una salida que debas generar con redirecciones. Si `laboratorio/` no existe, crea la carpeta desde Files o ejecuta:

```bash
mkdir -p laboratorio
```

> **Comprueba.** En tu evidencia debe quedar clara esta frase: “Mi aplicación se muestra mediante una sesión gráfica; mi servidor EC2 no necesita esa sesión para ejecutar servicios”.

## Errores frecuentes

- Intentar abrir una aplicación gráfica desde SSH sin una sesión de display.
- Llamar “Linux” únicamente al escritorio que se ve en pantalla.
- Instalar un escritorio pesado en un servidor para evitar aprender SSH.
- Memorizar nombres de procesos en vez de comprender la función de cada capa.

## Reto 4 — Mapa de la sesión gráfica

[Ver respuesta](instructor/soluciones.md#respuesta-reto-4)

Desde la VM del instructor, crea o completa `~/linux-desde-cero/laboratorio/sesion-grafica.txt` con protocolo, escritorio, dos aplicaciones visibles y una frase sobre cada capa. Si el archivo de evidencia no existe, créalo desde el editor gráfico; si `laboratorio/` no existe, créalo primero.

### Criterios de comprobación

- Distingue protocolo, escritorio y aplicación.
- Los valores se observan en la sesión, no se inventan.
- Explica por qué la EC2 del laboratorio no requiere GUI.

## Checklist

- [ ] Distingo X.Org, Wayland, GNOME y KDE.
- [ ] Sé reconocer si estoy en una sesión gráfica o en SSH.
- [ ] Puedo justificar por qué un servidor puede operar sin escritorio.
