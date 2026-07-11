# 6. KDE Plasma

## Objetivos

- Reconocer Plasma, Dolphin, Konsole y System Settings.
- Relacionar administración gráfica de archivos con comandos Linux.
- Contextualizar los nombres históricos del temario.

## Antes de empezar

Este capítulo continúa con los archivos creados en GNOME. Si abriste este documento directamente, prepara el mismo punto de partida desde Konsole:

```bash
mkdir -p ~/curso-gui/{entrada,kde-demo}
printf 'estado=ok\n' > ~/curso-gui/entrada/servicio.conf
cp ~/curso-gui/entrada/servicio.conf ~/curso-gui/config-actual.conf
```

Después existirán `servicio.conf`, `config-actual.conf` y el directorio vacío `kde-demo`.

## 6.1 Partes de la pantalla

KDE Plasma suele presentar panel, lanzador, bandeja, escritorio, widgets y actividades. Es altamente configurable, pero en este curso sólo se recorren elementos que ayudan a trabajar.

## 6.2 Administración de archivos con Dolphin

KFM fue un gestor antiguo de KDE. Su equivalente actual es Dolphin.

Funciones de la demostración:

- panel de lugares y ruta editable;
- vista dividida;
- archivos ocultos;
- terminal integrada;
- propiedades, tipo y permisos.

## 6.3 Navegación y contenido

En Dolphin navega a `~/curso-gui`. Abre la terminal integrada y comprueba:

```bash
pwd
ls -lah
file config-actual.conf
```

`~/curso-gui` significa la carpeta `curso-gui` dentro de tu home. Puedes escribir esa ruta en la barra de ubicación de Dolphin. Los comandos funcionan porque la terminal integrada se abre en la carpeta que Dolphin muestra; confirma que `pwd` termina en `/curso-gui`.

La GUI y la terminal observan el mismo sistema de archivos.

## 6.4 Crear directorios

Crear una carpeta desde Dolphin equivale a:

```bash
mkdir -p ~/curso-gui/kde-demo
```

`-p` crea padres faltantes y no falla si la ruta ya existe.

## 6.5 Copiar, borrar y mover

```bash
cp ~/curso-gui/config-actual.conf ~/curso-gui/kde-demo/
mv ~/curso-gui/kde-demo/config-actual.conf ~/curso-gui/kde-demo/app.conf
rm -i ~/curso-gui/kde-demo/app.conf
```

`rm -i` solicita confirmación. La terminal no tiene una papelera universal equivalente a Trash.

Cuando aparezca `remove regular file ...?`, responde `y` para borrar el archivo de práctica o `n` para conservarlo. Si respondes `y`, el enlace del siguiente apartado seguirá funcionando porque apunta a `servicio.conf`, no a `app.conf`.

## 6.6 Enlaces

Dolphin puede mostrar el destino de un enlace. La forma reproducible es:

```bash
ln -s ../entrada/servicio.conf ~/curso-gui/kde-demo/servicio-actual
readlink ~/curso-gui/kde-demo/servicio-actual
```

## 6.7 Tipos MIME

Las asociaciones de aplicaciones usan tipos MIME, no únicamente extensiones:

```bash
xdg-mime query filetype ~/curso-gui/config-actual.conf
```

## 6.8 Propiedades y permisos

Compara Properties con:

```bash
stat ~/curso-gui/config-actual.conf
namei -l ~/curso-gui/config-actual.conf
```

`namei -l` ayuda a encontrar permisos insuficientes en algún directorio de la ruta.

## 6.9–6.10 Aplicaciones esenciales

- Dolphin: archivos.
- Konsole: terminal.
- Kate: edición de texto; sustituye en la práctica a referencias antiguas como `kedit`/`kwrite`.
- KHelpCenter: ayuda gráfica.
- KFind o búsqueda de Dolphin: localización de archivos.

## 6.11–6.14 Configuración

“KDE Control Center” se denomina actualmente System Settings. Se demostrará configuración de pantalla, teclado, apariencia y panel. KMenuEdit y la personalización profunda quedan como exploración opcional.

## Práctica guiada resuelta

En Dolphin crea un archivo, abre la terminal integrada y ejecuta:

```bash
printf 'creado-desde=plasma\n' > ~/curso-gui/kde-demo/origen.txt
chmod 640 ~/curso-gui/kde-demo/origen.txt
stat -c '%A %a %U:%G %n' ~/curso-gui/kde-demo/origen.txt
```

Aunque el texto diga “crea un archivo”, la primera línea con `printf` ya lo crea y escribe su contenido; no necesitas crearlo antes con Dolphin.

Salida representativa:

```text
-rw-r----- 640 ubuntu:ubuntu /home/ubuntu/curso-gui/kde-demo/origen.txt
```

- `%A`: permisos simbólicos.
- `%a`: permisos octales.
- `%U:%G`: dueño y grupo.
- `%n`: nombre.

## Errores frecuentes

- Seguir tutoriales de KFM o KDE Control Center como si fueran herramientas actuales.
- Asociar una aplicación incorrecta a un tipo MIME globalmente.
- Confundir un enlace con una copia.

## Reto 6 — Diagnóstico desde Dolphin

[Ver respuesta](instructor/soluciones.md#respuesta-reto-6)

Crea `~/curso-gui/kde-demo/check.sh` con texto válido de Bash, pero sin permiso de ejecución. Usa Dolphin y Konsole para diagnosticarlo. Documenta tipo, permisos, propietario y ruta completa; corrige únicamente el permiso necesario.

### Criterios de comprobación

- No utiliza `chmod 777`.
- Explica la diferencia entre archivo no ejecutable y directorio no accesible.
- Confirma el modo antes y después.

## Checklist

- [ ] Reconozco Dolphin, Konsole, Kate y System Settings.
- [ ] Identifico nombres históricos del temario.
- [ ] Relaciono Properties con `stat` y `namei`.
