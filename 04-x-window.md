# 4. X Window y Wayland

## Objetivos

- Distinguir shell, terminal, servidor gráfico, compositor y escritorio.
- Identificar la sesión gráfica sin memorizar componentes históricos.
- Entender por qué un servidor EC2 normalmente no incluye GUI.

## Antes de empezar

Este capítulo se practica en una VM con escritorio abierto, no en la terminal SSH de EC2. Abre GNOME Terminal o Konsole dentro de la VM.

Las variables empiezan con `$` porque su valor lo proporciona la sesión gráfica. No debes sustituirlas manualmente.

## 4.1 X Window

X Window System define un modelo de ventanas y entrada que tradicionalmente se implementa con X.Org. En escritorios actuales también es común Wayland, un protocolo más reciente en el que el compositor asume más responsabilidades.

```text
aplicación → toolkit → X.Org o compositor Wayland → kernel/controladores → pantalla
                         ↑
                  teclado y ratón
```

GNOME y KDE Plasma son **entornos de escritorio**; no son sinónimos de X Window.

### Identificar una sesión

Ejecuta esto en la terminal de una VM gráfica:

```bash
printf 'Tipo: %s\n' "${XDG_SESSION_TYPE:-no definido}"
printf 'Escritorio: %s\n' "${XDG_CURRENT_DESKTOP:-no definido}"
printf 'Display X11: %s\n' "${DISPLAY:-no definido}"
printf 'Display Wayland: %s\n' "${WAYLAND_DISPLAY:-no definido}"
```

Salida representativa:

```text
Tipo: wayland
Escritorio: ubuntu:GNOME
Display X11: :0
Display Wayland: wayland-0
```

- `XDG_SESSION_TYPE`: protocolo principal de la sesión.
- `DISPLAY`: dirección usada por clientes X11, incluso mediante compatibilidad.
- `WAYLAND_DISPLAY`: socket del compositor Wayland.
- Los valores cambian según la VM y la sesión elegida.
- `${VARIABLE:-no definido}` muestra un texto comprensible cuando la variable no existe.

### Servidor frente a escritorio

Una instancia EC2 para terminal no necesita GUI: reduce paquetes, memoria y superficie de ataque. El curso usa una VM gráfica del instructor para demostrar GNOME/KDE y EC2 para administración real por SSH.

## Práctica guiada resuelta

En la VM gráfica:

```bash
session_id=${XDG_SESSION_ID:-$(loginctl | awk -v user="$USER" '$3 == user {print $1; exit}')}
loginctl show-session "$session_id" -p Type -p Desktop -p Remote 2>/dev/null || true
ps -e | grep -E 'gnome-shell|kwin_wayland|Xorg' || true
```

La primera línea obtiene el ID de la sesión y lo guarda en `session_id`. La segunda consulta esa sesión. `|| true` evita presentar como fallo grave la ausencia de un proceso opcional.

Interpretación:

- `Type` confirma `x11` o `wayland`.
- `Desktop` identifica el entorno cuando está disponible.
- `Remote=yes` indica una sesión remota.
- La lista de procesos ayuda a reconocer GNOME Shell, KWin o X.Org.

## Errores frecuentes

- Intentar ejecutar una aplicación gráfica en una sesión SSH sin display.
- Llamar “Linux” al escritorio completo.
- Instalar un escritorio pesado en un servidor sólo para administrar archivos.

## Reto 4 — Mapa de la sesión gráfica

[Ver respuesta](instructor/soluciones.md#respuesta-reto-4)

Desde la VM del instructor, crea `laboratorio/sesion-grafica.txt`. Registra protocolo, escritorio, compositor o servidor gráfico y dos aplicaciones visibles. Explica la función de cada capa en una frase.

### Criterios de comprobación

- Diferencia protocolo, escritorio y aplicación.
- Los valores se obtienen de la sesión, no se inventan.
- Explica por qué la EC2 del laboratorio no requiere GUI.

## Checklist

- [ ] Distingo X.Org, Wayland, GNOME y KDE.
- [ ] Puedo identificar el tipo de sesión.
- [ ] Comprendo la diferencia entre servidor y desktop.
