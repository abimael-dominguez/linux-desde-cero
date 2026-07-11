# 5. GNOME

## Objetivos

- Reconocer los elementos principales de GNOME.
- Administrar archivos con Files/Nautilus y relacionar acciones con comandos.
- Usar terminal, búsqueda y configuración básica.
- Comprender el proceso de instalación sin consumir la clase descargando un escritorio.

## Antes de empezar

Usa la VM gráfica del instructor o una Ubuntu Desktop. Los ejemplos crearán `~/curso-gui`; `~` representa el home del usuario que inició la sesión gráfica.

Prepara la carpeta de práctica:

```bash
mkdir -p ~/curso-gui/entrada
```

`mkdir -p` conserva lo que ya exista. Si repetiste la práctica, puedes usar otros nombres o revisar los archivos antes de sobrescribirlos.

## 5.1 Iniciación a GNOME

GNOME prioriza un flujo simple basado en Activities, búsqueda, espacios de trabajo y aplicaciones integradas. Ubuntu Desktop incluye una adaptación de GNOME.

Elementos para la demostración:

- Activities Overview;
- panel superior y notificaciones;
- dock;
- espacios de trabajo;
- configuración rápida.

## 5.2 Aplicaciones auxiliares

Las aplicaciones útiles para este curso son Files, Terminal, Text Editor, Settings y System Monitor. El objetivo es ubicar herramientas, no recorrer todo el catálogo.

## 5.3 Files/Nautilus

Demostración en la VM:

1. Crear `~/curso-gui/entrada`.
2. Mostrar archivos ocultos con `Ctrl+H`.
3. Copiar, mover, renombrar y eliminar un archivo.
4. Abrir Properties y revisar tipo, tamaño y permisos.
5. Repetir en terminal:

```bash
mkdir -p ~/curso-gui/entrada
printf 'estado=ok\n' > ~/curso-gui/entrada/servicio.conf
cp ~/curso-gui/entrada/servicio.conf ~/curso-gui/copia.conf
mv ~/curso-gui/copia.conf ~/curso-gui/config-actual.conf
ls -lah ~/curso-gui
```

`servicio.conf` es el archivo original, `copia.conf` es una copia temporal y `config-actual.conf` es el nombre final después de moverla.

## 5.4 Búsqueda

La búsqueda gráfica es apropiada cuando se exploran documentos. Para búsquedas reproducibles o servidores se usan comandos:

```bash
find ~/curso-gui -type f -name '*.conf'
grep -R "estado=" ~/curso-gui
```

## 5.5 Terminales

GNOME Terminal, Console y XTerm son emuladores de terminal. El shell puede ser Bash en cualquiera de ellos.

```bash
printf 'Terminal: %s\nShell: %s\n' "$TERM" "$SHELL"
```

`$TERM` describe capacidades de terminal; no debe usarse para decidir qué shell está activo.

## 5.6 Multimedia

El temario original incluye multimedia. Para este curso basta explicar que audio, video y cámaras dependen de servicios, permisos y aplicaciones del escritorio. No se dedicará una práctica a reproductores.

## 5.7 Instalación y configuración

La VM del instructor se prepara antes de clase. En Ubuntu se inspeccionan primero los paquetes disponibles:

```bash
apt search ubuntu-desktop
apt show ubuntu-desktop-minimal
```

`apt search` y `apt show` sólo consultan información. No instalan GNOME. La instalación real se prepara antes de clase porque puede descargar muchos paquetes y cambiar la pantalla de inicio de sesión.

La instalación de un escritorio descarga muchos paquetes y requiere reinicio/selección de sesión; no debe iniciarse en una EC2 de laboratorio. Durante la demostración se configuran pantalla, teclado, red, usuarios y accesibilidad desde Settings.

## Práctica guiada resuelta

Compara una operación gráfica con su evidencia CLI:

```bash
stat ~/curso-gui/config-actual.conf
sha256sum ~/curso-gui/entrada/servicio.conf ~/curso-gui/config-actual.conf
```

Si los hashes coinciden, la copia conserva el mismo contenido aunque el nombre y metadatos puedan ser distintos.

## Errores frecuentes

- Confundir el gestor de archivos con el sistema de archivos.
- Creer que mover a Trash elimina inmediatamente y sin recuperación.
- Cambiar permisos gráficamente sin interpretar usuario, grupo y otros.

## Reto 5 — GUI y CLI equivalentes

[Ver respuesta](instructor/soluciones.md#respuesta-reto-5)

Trabaja dentro de `~/curso-gui/reto5`. Realiza tres operaciones en Files y documenta en `evidencia.txt` los comandos equivalentes. Incluye una prueba que confirme contenido y otra que confirme permisos.

### Criterios de comprobación

- Incluye crear, mover o copiar y cambiar permisos.
- Usa una evidencia verificable, no sólo capturas.
- Explica qué metadato cambió en cada operación.

## Checklist

- [ ] Reconozco Activities, Files, Terminal y Settings.
- [ ] Relaciono operaciones gráficas con comandos.
- [ ] Sé por qué la instalación se demuestra en una VM preparada.
