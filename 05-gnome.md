# 5. GNOME

Ejercicios prácticos hands-on para dominar GNOME. Compararemos GUI vs CLI y veremos las diferencias clave con KDE.

Nota: ejercicios realizados con Ubuntu 24.04.3 LTS - Noble Numbat (GNOME por defecto).

## 5.1 Iniciación a GNOME

| ID | Ejercicio | Resultado |
|---|---|---|
| 5.1.A | Identificar: Panel superior (barra de menú), Dash (dock izquierdo), Escritorio y Bandeja del Sistema | Panel = barra de menú con reloj y notificaciones. Dash = dock fijo, más minimalista que KDE |
| 5.1.B | Clic derecho en Panel → "Configuración de pantalla" → Cambiar resolución | Panel fijo en la parte superior, menos configurable que KDE (sin arrastrar bordes) |
| 5.1.C | Clic derecho en Escritorio → "Añadir al escritorio" → Widget de reloj | GNOME soporta widgets básicos, pero menos variedad que KDE |
| 5.1.D | Presionar Super (tecla Windows) y comparar con Kickoff de KDE | GNOME: Activities Overview full-screen. KDE: menú jerárquico |

## 5.2 Aplicaciones auxiliares de GNOME

| ID | App y Acción | Resultado |
|---|---|---|
| 5.2.A | **GNOME Calculator**: Actividades → Buscar "Calculadora" → Modo Programador | Calculadora básica con modos científicos |
| 5.2.B | **GNOME Calendar**: Actividades → "Calendario" → Añadir evento | Gestión de eventos integrada con Google/Outlook |
| 5.2.C | **GNOME Weather**: Actividades → "Clima" → Configurar ubicación | Pronóstico simple, menos detallado que apps especializadas |

## 5.3 File manager (Nautilus)

**Nota:** Nautilus reemplazó a Nautilus antiguo; interfaz minimalista vs Dolphin de KDE.

**Interfaz de GNOME File Manager (Nautilus):**
- Barra lateral izquierda: Lugares (Home, Escritorio, Documentos), Dispositivos (discos externos), Red.
- Área principal: Vista de iconos, lista o cuadrícula. Breadcrumb trail en la parte superior.
- Barra de herramientas: Botones para atrás/adelante, recargar, buscar, menú de tres puntos (más opciones).
- Diferencias con Dolphin: Sin terminal embebida (F4), sin split view (F3), más simple y rápido, pero menos potente para jerarquías profundas.

**Carpetas del root (/): Explicación breve de las más usadas**
El directorio raíz `/` contiene todo el sistema. Aquí las carpetas clave (explorables en Nautilus con permisos de root, ej: `sudo nautilus`):

- **/home**: Archivos personales de usuarios (equivalente a C:\Users en Windows). Contiene subcarpetas como Desktop, Documents, Downloads.
- **/etc**: Archivos de configuración del sistema (ej: `/etc/passwd` para usuarios, `/etc/fstab` para discos). Editar con cuidado.
- **/var**: Datos variables (logs en `/var/log`, bases de datos en `/var/lib`). Ej: `cat /var/log/syslog` para logs del sistema.
- **/usr**: Programas y bibliotecas instalados (ej: `/usr/bin` para comandos, `/usr/share` para iconos). Mayoría de apps aquí.
- **/tmp**: Archivos temporales (se borran al reiniciar). Ej: `ls /tmp` para ver archivos efímeros.
- **/boot**: Archivos de arranque (kernel en `/boot/vmlinuz`, GRUB config). No modificar sin experiencia.
- **/dev**: Dispositivos hardware (ej: `/dev/sda` para disco, `/dev/null` para descartar output).
- **/proc**: Información del kernel (virtual, ej: `cat /proc/cpuinfo` para CPU, `cat /proc/meminfo` para RAM).
- **/sys**: Similar a /proc, para hardware (ej: `ls /sys/block` para discos).
- **/media y /mnt**: Puntos de montaje para USB/CD (ej: USB aparece en `/media/user/USB`).
- **/opt**: Software opcional (ej: apps de terceros).
- **/root**: Home del usuario root.
- **/sbin**: Comandos de administración (requieren root).

Explora: En Nautilus, ir a "Otro lugar" → `/` → Navegar carpetas. Para archivos clave: `cat /etc/os-release` (info distro), `ls /usr/bin | head -10` (comandos disponibles).

| ID | Ejercicio | Resultado |
|---|---|---|
| 5.3.A | Abrir Nautilus → Identificar barra lateral Lugares y área de archivos | Vista de carpetas personales, más limpia que Dolphin |
| 5.3.B | Cambiar vistas: Iconos, Lista, Compacta | Lista = detalles básicos; Compacta = ahorro de espacio |
| 5.3.C | Clic derecho en archivo → Propiedades → Ver permisos y metadatos | Similar a Dolphin, pero interfaz más simple |
| 5.3.D | Buscar en Nautilus: Presionar Ctrl+F → "documento" | Búsqueda integrada, menos avanzada que KFind de KDE |

## 5.4 GNOME Search Tool

| ID | Acción | Resultado |
|---|---|---|
| 5.4.A | Presionar Super → Escribir "terminal" → Enter | Busca apps y archivos rápidamente |
| 5.4.B | Actividades → Buscar "config" → Abrir "Configuración" | Acceso directo a settings |
| 5.4.C | En Nautilus: Ctrl+F → Buscar archivos por nombre/contenido | Búsqueda local, integrada en file manager |

## 5.5 Color Xterm, GNOME Terminal y Regular Xterm

**Diferencias con Konsole de KDE:** GNOME Terminal es simple, sin tabs por defecto (usa extensiones), pero soporta perfiles de color.

| ID | Comando/Acción | Resultado |
|---|---|---|
| 5.5.A | `pwd` | Imprime directorio actual (igual que KDE) |
| 5.5.B | `cd / && ls -la` | Lista root con ocultos; GNOME Terminal = terminal básica |
| 5.5.C | `tree /home/usuario` (instalar con `sudo apt install tree`) | Muestra jerarquía de directorios en árbol (no visto en KDE) |
| 5.5.D | `find /home -name "*.txt"` | Busca archivos por patrón (más avanzado que ls) |
| 5.5.E | `du -h /home` | Muestra uso de disco por directorio (útil para limpieza) |
| 5.5.F | GNOME Terminal: Preferencias → Perfiles → Añadir "Color Xterm" | Terminal con colores retro, similar a xterm clásico |

## 5.6 Multimedia

| ID | App y Acción | Resultado |
|---|---|---|
| 5.6.A | **GNOME Videos**: Abrir video → Controles básicos | Reproductor simple, menos codecs que VLC |
| 5.6.B | **GNOME Music**: Escanear música → Crear playlists | Gestión básica de biblioteca |
| 5.6.C | **GNOME Photos**: Importar fotos → Editar básico | Editor ligero, integración con Google Photos |

## 5.7 Configuración de GNOME

Ir a Actividades → "Configuración"

| ID | Configuración | Resultado |
|---|---|---|
| 5.7.A | Configuración → Apariencia → Estilo oscuro | Tema oscuro global, menos opciones que KDE |
| 5.7.B | Configuración → Multitarea → Hot Corners → Activar | Esquinas activas para overview (similar a macOS) |
| 5.7.C | Configuración → Región e Idioma → Formatos | Cambios de idioma/localización |
| 5.7.D | Configuración → Multitarea → Workspaces → Número dinámico | Workspaces virtuales: Ctrl+Alt+Up/Down para cambiar, Super+Shift+PageUp/Down para mover ventanas |

## GNOME vs KDE: Diferencias clave

| Aspecto | GNOME | KDE Plasma |
|---|---|---|
| **Filosofía** | Minimalismo + simplicidad | Configurabilidad total + productividad |
| **Window Manager** | Mutter: extensiones para personalización | KWin: efectos avanzados built-in |
| **File Manager** | Nautilus: interfaz simple, sin terminal embebida | Dolphin: terminal embebida, split view |
| **Themes** | Theming limitado sin extensiones | Sistema global robusto |
| **Workflow** | Activities Overview full-screen | Menú jerárquico tradicional |
| **Target** | Usuarios casuales, diseño limpio | Power users, programadores |