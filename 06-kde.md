# 6. KDE Plasma Desktop

Ejercicios prácticos hands-on para dominar KDE. Compararemos GUI vs CLI y veremos las diferencias clave con GNOME.

## 6.1 Partes de la pantalla

| ID | Ejercicio | Resultado |
|---|---|---|
| 6.1.A | Identificar: Panel (barra inferior), Kickoff (icono K), Escritorio, y Bandeja del Sistema | Panel = taskbar de Windows, NO es el Dash/Dock de GNOME |
| 6.1.B | Clic derecho en Panel → "Editar Panel" → Arrastrar y mover a otro borde | Panel reposicionado. KDE es altamente configurable |
| 6.1.C | Modo edición activo → "Añadir Widgets" → Buscar "Reloj Digital" → Arrastrar al escritorio | Widget independiente en el escritorio |
| 6.1.D | Abrir Kickoff y comparar con Activities Overview de GNOME | KDE: menú jerárquico. GNOME: overview full-screen |

## 6.2 Dolphin File Manager

**Nota:** Dolphin reemplazó a KFM (antiguo gestor de KDE).

| ID | Ejercicio | Resultado |
|---|---|---|
| 6.2.A | Abrir Dolphin → Identificar panel Lugares (izq) y área de archivos (der) | Vista de carpetas personales (Desktop, Documents, Downloads) |
| 6.2.B | Cambiar entre vistas: Iconos, Detalles, Columnas | Modo Columnas = ideal para jerarquías |
| 6.2.C | Presionar `F3` → Navegar al `/etc` en panel derecho | Split view vertical. Útil para arrastrar entre directorios |
| 6.2.D | Presionar `F4` → Cambiar carpeta en Dolphin | Terminal embebida (Konsole) con PWD sincronizado |

## 6.3 Navegación y visualización de archivos

| ID | Comando/Acción | Resultado |
|---|---|---|
| 6.3.A | `pwd` | Imprime directorio actual (ej: `/home/usuario`) |
| 6.3.B | `cd /` | Cambia a root. Prompt: `user@kubuntuvm:/$` |
| 6.3.C | `ls -l` | Lista detallada: permisos, owner, tamaño, fecha. GUI = capa visual sobre esto |
| 6.3.D | `cat /etc/issue` | Muestra info de distro (ej: `Kubuntu 22.04 LTS`) |
| 6.3.E | Dolphin: usar breadcrumb trail → `/` → `home` → `usuario` | GUI y CLI muestran la misma jerarquía |

## 6.4 Crear directorios

| ID | Comando/Acción | Resultado |
|---|---|---|
| 6.4.A | `mkdir ~/CursoKDE` | Crea directorio en home |
| 6.4.B | `mkdir -p ~/CursoKDE/modulos/configuracion` | Flag `-p`: crea toda la ruta anidada |
| 6.4.C | `ls -F ~/CursoKDE/` | Verifica: muestra `modulos/` |
| 6.4.D | Dolphin: clic derecho → "Crear Nuevo" → "Carpeta" → `EjerciciosGUI` | Aparece en GUI y CLI instantáneamente (sincronizados) |

## 6.5 Operaciones con archivos: copiar, mover, borrar

| ID | Comando/Acción | Resultado |
|---|---|---|
| 6.5.A | `touch ~/CursoKDE/archivo_a_copiar.txt` | Crea archivo vacío |
| 6.5.B | `cp ~/CursoKDE/archivo_a_copiar.txt ~/CursoKDE/copia_simple.txt` | Copia en mismo directorio |
| 6.5.C | `mv ~/CursoKDE/copia_simple.txt ~/EjerciciosGUI/archivo_movido.txt` | Mueve Y renombra |
| 6.5.D | `rm -rf ~/EjerciciosGUI` | Borra recursivamente sin confirmación (`-rf` = forced) |
| 6.5.E | Dolphin: arrastrar `CursoKDE` → Papelera → Vaciar Papelera | Drag & drop = equivalente GUI de `rm` |

## 6.6 Links (Simbólicos y Hard Links)

**Explicación:** Los links permiten acceder al mismo archivo desde múltiples ubicaciones sin duplicar datos.

- **Hard Link**: Otro nombre para el mismo archivo físico. Comparte el mismo inode (número único del archivo en disco). Si borras el archivo original, el hard link sigue funcionando perfectamente (el archivo existe mientras al menos un hard link apunte a él). Solo funciona dentro del mismo filesystem.
- **Symbolic Link (Symlink)**: Un puntero que apunta al archivo original. Si borras el original, el symlink se rompe ("broken link"). Puede apuntar a archivos en diferentes filesystems o directorios.

**¿Qué es un inode?** Estructura de datos que representa un archivo en el disco. Contiene metadatos (permisos, tamaño, timestamps, punteros a bloques de datos) pero NO el nombre del archivo ni su contenido. Cada archivo tiene un inode único por filesystem. Los hard links comparten el mismo inode.

**Desde KDE (Dolphin) sin terminal:**
- **Symlinks**: Sí, clic derecho en archivo → "Crear enlace" (crea symlink automáticamente).
- **Hard Links**: No directamente en GUI; requiere terminal (`ln` sin `-s`).

**Casos de uso:**
- **Hard Links**: Backup de archivos críticos (ej: `ln /etc/passwd /backup/passwd_backup`). El backup sobrevive si borras el original.
- **Symbolic Links**: Enlaces a directorios compartidos (ej: `ln -s /mnt/shared /home/user/shared`). Facilita acceso sin duplicar datos. También para versiones de software (ej: `ln -s /usr/bin/python3.9 /usr/bin/python`).

| ID | Comando/Acción | Resultado |
|---|---|---|
| 6.6.A | `echo "Soy el archivo original" > original.txt` | Crea archivo con contenido |
| 6.6.B | `ln -s original.txt enlace_simbolico.txt` | Symlink (acceso directo) |
| 6.6.C | `ln original.txt enlace_duro.txt` | Hard link (mismo inode, solo en mismo filesystem) |
| 6.6.D | Dolphin: observar íconos | Symlink tiene flecha superpuesta. Hard link = igual que original |
| 6.6.E | `ls -li` | Inode (1ra columna): original y hard link tienen el mismo, symlink difiere |
| 6.6.F | Dolphin: clic derecho en `original.txt` → "Crear enlace" | Crea symlink en el mismo directorio |

## 6.7 Asociación de tipos de archivo (MIME types)

| ID | Acción | Resultado |
|---|---|---|
| 6.7.A | `touch test.abc` (Ctrl+Alt+T para Konsole) | Crea archivo con extensión desconocida |
| 6.7.B | Doble clic en `test.abc` en Dolphin | KDE pregunta con qué app abrirlo |
| 6.7.C | Clic derecho → Propiedades → pestaña "Tipo de Archivo" → Añadir → KWrite (mover arriba) → Aceptar → Doble clic nuevamente | Se abre con KWrite. Asociación MIME configurada |

## 6.8 Propiedades y permisos

| ID | Comando/Acción | Resultado |
|---|---|---|
| 6.8.A | Clic derecho en `Documentos` → Propiedades → Ver pestañas General, Permisos, Metadatos | Muestra tamaño, fecha, permisos de acceso |
| 6.8.B | Pestaña Permisos → Sección "Otros" → "Puede ver y modificar" → Aplicar | Equivalente GUI de `chmod` |
| 6.8.C | `chmod o+w ~/Documentos` | Da permiso de escritura a "others". Cambio visible en GUI |
| 6.8.D | `sudo chown root:root ~/Documentos` | Cambia owner a root. Verificar en Dolphin > Propiedades |

## 6.9 Apps esenciales de KDE

| ID | App y Acción | Resultado |
|---|---|---|
| 6.9.A | **Spectacle** (screenshot tool): Menú > Utilidades → Modo "Región rectangular" → Capturar → Guardar en `~/Descargas` | Genera archivo `.png` |
| 6.9.B | **Ark** (compresor): Menú > Utilidades → Nuevo → Seleccionar `archivo_a_copiar.txt` → Formato `.zip` → `ejemplo.zip` | Crea archivo comprimido |
| 6.9.C | **Okular** (visor universal): Abrir PDF → Menú Herramientas → Opciones de anotación (highlight, notas) | Visor con capacidad de markup |

## 6.10 Herramientas de productividad

| ID | App y Acción | Resultado |
|---|---|---|
| 6.10.A | **Konsole**: Ctrl+Shift+T (nueva pestaña) → Ctrl+Shift+L (split vertical) → En panel izq: `htop` → En panel der: `ls -l /etc` | Terminal con tabs y splits. Máxima productividad |
| 6.10.B | **KWrite vs KEdit**: Abrir `original.txt` en ambos y comparar | KEdit = notepad simple. KWrite = editor con syntax highlighting y números de línea |
| 6.10.C | **KDE Help Center**: Menú > Ayuda → Buscar "Dolphin" | Documentación unificada del sistema |
| 6.10.D | **KFind**: Menú > Utilidades → Buscar en `/etc` → Patrón `*.conf` → Modificado últimos 7 días → Buscar | Búsqueda avanzada con filtros de fecha/tamaño/contenido |

## 6.11 System Settings (Configuración)

| ID | Configuración | Resultado |
|---|---|---|
| 6.11.A | K-Menu → Preferencias del Sistema → Apariencia → Tema Global → "Breeze Dark" | Todo el sistema cambia a tema oscuro instantáneamente |
| 6.11.B | Comportamiento del Espacio de Trabajo → Efectos de Escritorio → Activar "Wobbly Windows" → Mover ventana | Efecto de gelatina en ventanas. KDE = altamente customizable |
| 6.11.C | Comportamiento del Espacio de Trabajo → General → Comportamiento de clic → Cambiar a "Clic simple" | Clic simple abre archivos (como web browser) |

## 6.12 KMenuEdit (Personalizar menú de apps)

| ID | Acción | Resultado |
|---|---|---|
| 6.12.A | Clic derecho en Kickoff → "Editar Aplicaciones" → Panel izq: clic derecho en "Utilidades" → "Nuevo elemento" → Nombre: "Calculadora CLI" | Nueva entrada en blanco creada |
| 6.12.B | Campo "Comando": `konsole -e bc -l` → Guardar | Entrada configurada para ejecutar calculadora en terminal |
| 6.12.C | Cerrar editor → K-Menu → Utilidades → "Calculadora CLI" | Abre Konsole con `bc` ejecutándose |

## 6.13 Configuración avanzada del sistema

**Nota:** "KDE Control Center" (nombre antiguo) ahora es "System Settings" en Plasma.

| ID | Configuración | Resultado |
|---|---|---|
| 6.13.A | System Settings → Comportamiento del Espacio de Trabajo → Escritorios Virtuales → Aumentar a 4 → Nombres: Trabajo, Estudio, Navegación, Música → Ctrl+F8 | 4 escritorios virtuales con nombres custom |
| 6.13.B | System Settings → Arranque y Apagado → Gestión de Sesiones → "Empezar con sesión vacía" | Apps NO se restauran al reiniciar |
| 6.13.C | System Settings → Conexiones (Red) → Configurar interfaces y VPNs | Network Manager de Plasma |

## 6.14 Personalizar el Panel

| ID | Acción | Resultado |
|---|---|---|
| 6.14.A | K-Menu → Buscar Dolphin → Clic derecho → "Añadir a la barra de tareas" | Icono fijo en Panel para acceso rápido |
| 6.14.B | Clic derecho en Panel → "Editar Panel" → "Añadir Widgets" → "Application Launcher" → Arrastrar al Panel | Segundo botón de Kickoff añadido |
| 6.14.C | Modo "Editar Panel" → Arrastrar elementos (reloj, Kickoff, etc.) → Icono candado ("Bloquear Widgets") | Reorden completo. Panel extremadamente flexible |

## KDE vs GNOME: Diferencias clave

| Aspecto | KDE Plasma | GNOME |
|---|---|---|
| **Filosofía** | Configurabilidad total + productividad | Minimalismo + simplicidad |
| **Window Manager** | KWin: efectos avanzados built-in (Wobbly Windows) | Mutter: extensiones para personalización |
| **File Manager** | Dolphin: terminal embebida (F4), split view (F3) | Nautilus: interfaz simple y minimalista |
| **Themes** | Sistema global robusto, cambios instantáneos | Theming más limitado sin extensiones |
| **Workflow** | Menú jerárquico tradicional | Activities Overview full-screen |
| **Target** | Power users, programadores | Usuarios casuales, diseño limpio |