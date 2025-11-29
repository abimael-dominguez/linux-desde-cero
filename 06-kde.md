# 📚 Guía de Ejercicios Prácticos: KDE Plasma (Kubuntu)

Esta guía proporciona ejercicios prácticos y de terminal para cada sección del curso de KDE, haciendo hincapié en el enfoque "hands-on" y las diferencias con entornos como GNOME.

## 6.1 Partes de la pantalla

| Propósito | ID | Ejercicios Prácticos (Interfaz Gráfica) | Output Esperado/Visualización |
|---|---|---|---|
| Identificar Elementos Clave | 6.1.A | Identificar y nombrar el Panel (barra de tareas), el Menú de Aplicaciones (Kickoff, usualmente el icono de la K o el logotipo de la distribución), el Escritorio y el Área de Notificación/Bandeja del Sistema. | Se identifica el Panel (similar a la barra de tareas en Windows, diferente al concepto de Dash o Dock en GNOME). |
| Cambiar Disposición del Panel | 6.1.B | 1. Hacer clic derecho en una zona vacía del Panel. 2. Seleccionar "Editar Panel" (o "Entrar en el modo de edición de panel"). 3. Arrastrar el panel desde el borde central (con el icono del 'agarre') y colocarlo en el borde superior o lateral de la pantalla. | El panel cambia de posición. Propósito: Demostrar que KDE es altamente configurable y flexible en la disposición de sus elementos. |
| Usar Widgets | 6.1.C | 1. Con el modo "Editar Panel" activo, hacer clic en "Añadir Widgets". 2. Buscar el widget "Reloj Digital". 3. Arrastrar el widget y soltarlo sobre el escritorio, fuera del panel. | El reloj aparece como un elemento independiente en el escritorio. |
| Panel vs. Dash (Diferencia clave) | 6.1.D | Abrir el Menú de Aplicaciones (K-Menu/Kickoff) y comparar visualmente la búsqueda de aplicaciones con la "Vista de Actividades" (Activities Overview) de GNOME. | KDE usa un menú jerárquico tradicional y un buscador integrado, mientras que GNOME utiliza un espacio de trabajo completo (Overview) para la búsqueda y gestión de ventanas/escritorios virtuales. |

## 6.2 Administración de archivos KFM (Dolphin)

*Nota: El gestor de archivos de KDE se llama Dolphin. KFM (KDE File Manager) era el nombre antiguo.*

| Propósito | ID | Ejercicios Prácticos (Interfaz Gráfica) | Output Esperado/Visualización |
|---|---|---|---|
| Exploración Básica | 6.2.A | 1. Abrir Dolphin (desde el K-Menu o el icono en el Panel). 2. Identificar el panel Lugares (izquierda) y el área de Archivos/Directorios (derecha). | La ventana de Dolphin se abre, mostrando las carpetas personales (Escritorio, Documentos, Descargas, etc.). |
| Modos de Vista | 6.2.B | 1. En la barra de herramientas superior, usar los botones para cambiar entre los modos de vista: Iconos, Detalles y Columnas. 2. Observar el panel de información lateral si está habilitado. | La forma en que se presentan los archivos cambia drásticamente. El modo "Columnas" es útil para ver la jerarquía. |
| Dividir la Vista | 6.2.C | 1. Pulsar la tecla F3 (o seleccionar el menú "Ventana" > "Dividir la vista"). 2. En el panel recién creado (derecho), navegar a la carpeta /etc. | Dolphin se divide verticalmente en dos paneles independientes. Propósito: Característica de eficiencia para mover archivos entre ubicaciones distantes. |
| Abrir Terminal Embebida | 6.2.D | 1. Pulsar la tecla F4 (o hacer clic en el icono de Terminal en la barra de herramientas). 2. Navegar a otra carpeta (ej: Descargas). 3. Verificar que el prompt de la terminal embebida cambie automáticamente. | Una terminal de Konsole aparece en la parte inferior de Dolphin, mostrando el prompt en el directorio actual de la ventana principal. |

## 6.3 Navegar por la estructura de directorios y ver el contenido de los ficheros

| Propósito | ID | Comandos de Terminal | Output Esperado/Visualización |
|---|---|---|---|
| Ubicación Actual (CLI) | 6.3.A | `pwd` | Muestra el directorio actual (ej: /home/usuario). |
| Navegación Absoluta (CLI) | 6.3.B | `cd /` | Cambia al directorio raíz. Visualización: El prompt de la terminal ahora mostrará user@kubuntuvm:/$. |
| Contenido Detallado (CLI) | 6.3.C | `ls -l` | Muestra el listado de archivos y directorios con detalles (permisos, propietario, tamaño, fecha). Propósito: Entender que la interfaz gráfica (Dolphin) es solo una vista de esta estructura subyacente. |
| Ver Contenido de Archivo (CLI) | 6.3.D | `cat /etc/issue` | Muestra el contenido del archivo de información de la distribución (ej: Kubuntu 22.04 LTS \n \l). Propósito: Introducir una herramienta básica de visualización. |
| Navegación Gráfica (Dolphin) | 6.3.E | 1. En Dolphin, usar la barra de ubicación (breadcrumb trail) haciendo clic en los nombres de las carpetas. 2. Hacer clic en el componente de Raíz (/). 3. Luego hacer clic en el componente home y en la carpeta de usuario. | La vista gráfica sigue el mismo camino jerárquico que la terminal. |

## 6.4 Crear un nuevo directorio

| Propósito | ID | Comandos de Terminal | Output Esperado/Visualización |
|---|---|---|---|
| Creación Rápida (CLI) | 6.4.A | `mkdir ~/CursoKDE` | Crea un directorio llamado CursoKDE en el directorio Home. |
| Creación Múltiple (CLI) | 6.4.B | `mkdir -p ~/CursoKDE/modulos/configuracion` | Crea directorios anidados con un solo comando. |
| Comprobación (CLI) | 6.4.C | `ls -F ~/CursoKDE/` | Muestra modulos/. |
| Creación Gráfica (Dolphin) | 6.4.D | 1. Abrir Dolphin y navegar al directorio Home. 2. Hacer clic derecho en un espacio vacío. 3. Seleccionar "Crear Nuevo" > "Carpeta...". 4. Escribir EjerciciosGUI y presionar Enter. | El nuevo directorio EjerciciosGUI aparece inmediatamente en Dolphin y es visible mediante ls en la terminal. Propósito: Mostrar la sincronía entre GUI y CLI. |

## 6.5 Copiar, Borrar y Mover un documento o directorio

| Propósito | ID | Comandos de Terminal/Ejercicios Prácticos | Output Esperado/Visualización |
|---|---|---|---|
| Crear un archivo de prueba (CLI) | 6.5.A | `touch ~/CursoKDE/archivo_a_copiar.txt` | Crea un archivo vacío en el directorio CursoKDE. |
| Copia de Archivo (CLI) | 6.5.B | `cp ~/CursoKDE/archivo_a_copiar.txt ~/CursoKDE/copia_simple.txt` | Copia el archivo en el mismo directorio con un nombre diferente. |
| Movimiento/Renombre (CLI) | 6.5.C | `mv ~/CursoKDE/copia_simple.txt ~/EjerciciosGUI/archivo_movido.txt` | Mueve el archivo a EjerciciosGUI y lo renombra en el proceso. |
| Borrado Recursivo (CLI) | 6.5.D | `rm -rf ~/EjerciciosGUI` | Borra el directorio EjerciciosGUI y todo su contenido sin pedir confirmación (-f → forced). |
| Arrastrar y Soltar (Dolphin) | 6.5.E | 1. En Dolphin, localizar el directorio CursoKDE. 2. Arrastrar el directorio y soltarlo sobre el icono de la Papelera (Trash) en el panel de Lugares (izquierda). 3. Hacer clic derecho en el icono de la Papelera y seleccionar "Vaciar Papelera". | Se visualiza cómo el arrastre y la acción de vaciar la papelera son la equivalencia gráfica del comando rm. |

## 6.6 Enlaces KDE (Enlaces Simbólicos y Duros)

*Nota: El concepto es idéntico a los enlaces de Linux.*

| Propósito | ID | Comandos de Terminal/Ejercicios Prácticos | Output Esperado/Visualización |
|---|---|---|---|
| Crear Archivo Original (CLI) | 6.6.A | `echo "Soy el archivo original" > original.txt` | Crea el archivo de contenido. |
| Crear Enlace Simbólico (CLI) | 6.6.B | `ln -s original.txt enlace_simbolico.txt` | Crea un enlace simbólico al archivo. |
| Crear Enlace Duro (CLI) | 6.6.C | `ln original.txt enlace_duro.txt` | Crea un enlace duro (solo si están en el mismo sistema de archivos). |
| Visualización (Dolphin) | 6.6.D | 1. Abrir Dolphin en la ubicación donde se crearon los archivos. 2. Observar que enlace_simbolico.txt tiene un icono de flecha superpuesto, y enlace_duro.txt se ve igual que el original. | La GUI de KDE ayuda a distinguir los enlaces simbólicos de los archivos normales, pero no los duros. |
| Comprobar con ls (CLI) | 6.6.E | `ls -li` | Observar el primer número (inode). El original y el enlace duro deben tener el mismo número de inode, el simbólico tendrá uno diferente. |

## 6.7 Asociar un nuevo tipo de archivo

| Propósito | ID | Ejercicios Prácticos (Interfaz Gráfica) | Output Esperado/Visualización |
|---|---|---|---|
| Crear Archivo Desconocido (CLI) | 6.7.A | Abrir Konsole (Ctrl+Alt+T) y ejecutar: `touch test.abc` | Crea un archivo sin extensión común. |
| Intento de Abrir | 6.7.B | 1. Hacer doble clic en test.abc en Dolphin. 2. Observar la ventana de diálogo que aparece. | KDE intentará adivinar o preguntará al usuario con qué aplicación abrir el archivo. |
| Asociación Permanente | 6.7.C | 1. Hacer clic derecho en test.abc, seleccionar "Propiedades". 2. Ir a la pestaña "Tipo de Archivo" (o "Asociaciones de Archivo"). 3. Debajo de 'Aplicación preferida', hacer clic en "Añadir...". 4. Seleccionar "KWrite" y moverlo a la parte superior de la lista. 5. Hacer clic en Aceptar. 6. Volver a hacer doble clic en test.abc. | Se abre automáticamente en KWrite. Propósito: Demostrar cómo KDE gestiona las asociaciones de MIME/archivos. |

## 6.8 Propiedades de un fichero o directorio

| Propósito | ID | Ejercicios Prácticos (Interfaz Gráfica/Terminal) | Output Esperado/Visualización |
|---|---|---|---|
| Ver Propiedades | 6.8.A | 1. Hacer clic derecho en un directorio (ej: Documentos) y seleccionar "Propiedades". 2. Examinar las pestañas General, Permisos y Metadatos. | Se abre una ventana de diálogo con información sobre el tamaño, fecha y, crucialmente, los permisos de acceso. |
| Cambiar Permisos (GUI) | 6.8.B | 1. En la ventana de propiedades, ir a la pestaña "Permisos". 2. En la sección "Otros", cambiar el menú desplegable de 'Acceso a' a "Puede ver y modificar el contenido" (Lectura y Escritura). 3. Hacer clic en "Aplicar". | La casilla de verificación cambia. Esto es la equivalencia gráfica del comando chmod. |
| Cambiar Permisos (CLI) | 6.8.C | Abrir Konsole y ejecutar: `chmod o+w ~/Documentos` | Se da permiso de escritura a "otros" en el directorio Documentos. Comprobación: Al volver a la pestaña de permisos en Dolphin, se observa el cambio. |
| Cambiar Propietario (CLI) | 6.8.D | `sudo chown root:root ~/Documentos` | El propietario del archivo cambia a root. Comprobación: En Dolphin > Propiedades > Permisos, el propietario listado será root. |

## 6.9 Aplicaciones Auxiliares de KDE

| Propósito | ID | Ejercicios Prácticos (Interfaz Gráfica) | Output Esperado/Visualización |
|---|---|---|---|
| Captura de Pantalla (Spectacle) | 6.9.A | 1. Abrir Spectacle (Menú > Utilidades > Spectacle). 2. En 'Modo de captura', seleccionar "Región rectangular". 3. Hacer clic en "Tomar una nueva captura de pantalla" y seleccionar un área específica. 4. Hacer clic en "Guardar como..." y guardar la imagen en ~/Descargas. | Se genera un archivo .png en ~/Descargas. |
| Gestor de Archivo Comprimido (Ark) | 6.9.B | 1. Abrir Ark (Menú > Utilidades > Ark). 2. Hacer clic en "Nuevo". 3. En el diálogo, seleccionar el archivo archivo_a_copiar.txt (de la sección 6.5). 4. Seleccionar el formato .zip y guardar el archivo comprimido como ejemplo.zip. | Un archivo ejemplo.zip aparece. Muestra cómo KDE maneja la compresión de archivos. |
| Visor de Documentos (Okular) | 6.9.C | 1. Abrir un PDF o un archivo de ayuda del sistema con Okular. 2. Explorar el menú "Herramientas" para ver las opciones de anotación (resaltar, añadir notas). | El documento se abre. Propósito: Okular es el visor universal de KDE, con capacidades de anotación. |

## 6.10 konsole, kedit, kwrite, kdehelp, Kfind

| Propósito | ID | Ejercicios Prácticos (Uso de Aplicación) | Output Esperado/Visualización |
|---|---|---|---|
| Konsole (Pestañas y Divisiones) | 6.10.A | 1. Abrir Konsole. 2. Presionar Ctrl+Shift+T para nueva pestaña. 3. Presionar Ctrl+Shift+L para dividir la vista verticalmente. 4. En la nueva división, ejecutar htop. 5. En la original, ejecutar `ls -l /etc`. | La ventana de la terminal está organizada en paneles y pestañas, demostrando su alta productividad. |
| KWrite vs. KEdit | 6.10.B | 1. Abrir KEdit y KWrite. 2. Abrir el mismo archivo (original.txt de 6.6) en ambos. 3. Comparar la interfaz: KEdit es simple; KWrite tiene numeración de líneas y resaltado. | KWrite ofrece una interfaz más rica para edición de código o texto extenso, mientras que KEdit es un bloc de notas simple. |
| KDEHelp (Documentación) | 6.10.C | 1. Abrir KDEHelp (Menú > Ayuda > Centro de Ayuda de KDE). 2. Usar el buscador para encontrar la documentación de Dolphin. | Se abre el centro de ayuda de KDE, una documentación unificada para todo el entorno. |
| Kfind (Búsqueda Avanzada) | 6.10.D | 1. Abrir Kfind (Menú > Utilidades > KFind). 2. En la pestaña "Nombre/Ubicación", establecer 'Buscar en' a /etc. 3. En la pestaña "Contenido", escribir el patrón *.conf. 4. En la pestaña "Fecha/Tamaño", seleccionar 'Modificado' y ajustar el rango de tiempo a 'en los últimos 7 días'. 5. Hacer clic en "Buscar". | Kfind muestra una lista de archivos que cumplen los criterios. Diferencia Clave: Muestra la alta capacidad de KDE para búsquedas detalladas. |

## 6.11 Configuración de KDE (Preferencias del Sistema)

| Propósito | ID | Ejercicios Prácticos (Interfaz Gráfica) | Output Esperado/Visualización |
|---|---|---|---|
| Cambiar Apariencia (Tema Global) | 6.11.A | 1. Abrir el Menú de Aplicaciones (K-Menu). 2. Buscar y abrir "Preferencias del Sistema". 3. Ir a la sección "Apariencia" y seleccionar "Tema Global". 4. Cambiar el tema a "Breeze Dark". | Todos los elementos del escritorio, ventanas y widgets cambian de color instantáneamente. |
| Ajustar Efectos de Ventana | 6.11.B | 1. En 'Preferencias del Sistema', ir a "Comportamiento del Espacio de Trabajo". 2. Hacer clic en "Efectos de Escritorio". 3. Buscar y activar el efecto "Ventanas Oscilantes" (Wobbly Windows). 4. Mover una ventana para ver el efecto. | Propósito: Muestra el alto nivel de personalización de los efectos visuales de KDE. |
| Cambiar Clic del Ratón | 6.11.C | 1. En 'Preferencias del Sistema', ir a "Comportamiento del Espacio de Trabajo" > "General". 2. En la sección "Comportamiento al hacer clic", cambiar la opción de doble clic a "Clic simple para abrir archivos y carpetas". | El comportamiento de los clics cambia inmediatamente. Propósito: Demostrar cómo se puede cambiar una convención de usabilidad fundamental. |

## 6.12 Editor de menús (KMenuEdit)

| Propósito | ID | Ejercicios Prácticos (Interfaz Gráfica) | Output Esperado/Visualización |
|---|---|---|---|
| Acceder y Crear Entrada | 6.12.A | 1. Hacer clic derecho en el botón del Menú de Aplicaciones (Kickoff) y seleccionar "Editar Aplicaciones". 2. En el panel izquierdo, navegar y hacer clic derecho en la carpeta "Utilidades". 3. Seleccionar "Nuevo elemento". 4. En el campo 'Nombre', escribir "Calculadora CLI". | Se abre la ventana del Editor de Menús y aparece una nueva entrada en blanco. |
| Configurar Comando | 6.12.B | 1. En el campo "Comando", escribir `konsole -e bc -l`. 2. Hacer clic en "Guardar" (icono de disquete). | La nueva entrada ahora ejecutará la calculadora de terminal. |
| Comprobación | 6.12.C | 1. Cerrar el Editor de Menús. 2. Abrir el Menú de Aplicaciones. 3. Navegar a "Utilidades" y hacer clic en "Calculadora CLI". | Se abre una ventana de Konsole ejecutando el programa bc. Propósito: Demostrar cómo se personalizan y añaden aplicaciones al menú principal de KDE. |

## 6.13 KDE Control Center (Preferencias del Sistema)

*Nota: El "KDE Control Center" es el nombre histórico. En la versión moderna (Plasma), se llama "Configuración del Sistema" (System Settings).*

| Propósito | ID | Ejercicios Prácticos (Interfaz Gráfica) | Output Esperado/Visualización |
|---|---|---|---|
| Ajustar Escritorios Virtuales | 6.13.A | 1. En "Configuración del Sistema", ir a "Comportamiento del Espacio de Trabajo" > "Escritorios Virtuales". 2. En la sección 'Número de escritorios', aumentar a 4 y cambiar los nombres (ej: Trabajo, Estudio, Navegación, Música). 3. Usar el atajo Ctrl+F8 (o el Pager) para ver los escritorios. | Los escritorios virtuales se actualizan con sus nuevos nombres. |
| Gestión de Sesiones | 6.13.B | 1. En 'Configuración del Sistema', ir a "Arranque y Apagado". 2. Hacer clic en "Gestión de Sesiones". 3. Cambiar la opción a "Empezar con una sesión vacía". | Propósito: Explicar que KDE permite al usuario controlar si las aplicaciones abiertas se restauran al reiniciar. |
| Ajustes de Red | 6.13.C | 1. En 'Configuración del Sistema', ir a "Conexiones" (o "Red"). 2. Mostrar dónde se pueden configurar las interfaces de red (Wi-Fi, Ethernet, VPNs) y dónde se puede añadir una VPN. | La interfaz de gestión de red de Plasma (Network Manager) se abre. Propósito: Familiarizar con la ubicación de la configuración avanzada de red. |

## 6.14 Añadir aplicaciones al panel

| Propósito | ID | Ejercicios Prácticos (Interfaz Gráfica) | Output Esperado/Visualización |
|---|---|---|---|
| Añadir un Lanzador Fijo | 6.14.A | 1. Abrir el Menú de Aplicaciones (Kickoff). 2. Buscar Dolphin. 3. Hacer clic derecho en la entrada de Dolphin y seleccionar "Añadir a la barra de tareas (Task Manager)". | El icono de Dolphin aparece permanentemente en el Panel (Task Manager), permitiendo un acceso rápido. |
| Añadir un Widget Lanzador de Aplicación | 6.14.B | 1. Hacer clic derecho en el Panel y seleccionar "Editar Panel". 2. Hacer clic en "Añadir Widgets". 3. Buscar "Lanzador de Aplicación" (Application Launcher) y arrastrarlo al Panel. | Se añade un nuevo botón de menú (el K-Menu/Kickoff) al Panel. |
| Mover y Bloquear el Panel | 6.14.C | 1. Con el modo "Editar Panel" activado, hacer clic y arrastrar los elementos del Panel (como el reloj o el botón Kickoff) para cambiar su orden. 2. Hacer clic en el icono del candado ("Bloquear Widgets") para finalizar la edición. | El orden de los elementos cambia, y el modo de edición se desactiva. Propósito: Demostrar la extrema flexibilidad y control sobre el Panel de KDE. |

## Resumen de Diferencias Clave con GNOME

* **Filosofía:** KDE se enfoca en la configurabilidad total y la alta productividad (ventanas divididas, Kfind avanzado). GNOME se enfoca en el minimalismo, la simplicidad y un flujo de trabajo basado en la "Vista de Actividades" (Overview).
* **Gestión de Ventanas:** KDE (KWin) ofrece efectos visuales avanzados y mucha personalización (Wobbly Windows). GNOME usa extensiones para añadir la mayoría de las funcionalidades visuales.
* **Gestor de Archivos:** Dolphin (KDE) tiene funciones avanzadas integradas como el panel de terminal (F4) y la vista dividida (F3). Nautilus (GNOME) es más minimalista y simple.
* **Temas:** KDE tiene un sistema de temas global muy robusto que afecta a todo el entorno de forma inmediata.