# 4. Permisos, usuarios y grupos

## Objetivos

Al terminar este capítulo podrás:

- interpretar propietarios, grupos y permisos `rwx`;
- aplicar modos simbólicos y octales sin usar permisos globales;
- explicar por qué los permisos de directorios difieren de los de archivos;
- administrar de forma consciente la membresía de `deploy` en `ops`;
- crear un directorio compartido con herencia de grupo;
- validar una política mínima de `sudo` sin instalarla;
- diagnosticar un `Permission denied` revisando toda la ruta.

## Contexto del laboratorio

| Identidad o ruta | Papel |
|---|---|
| `ubuntu` | administrador y propietario del proyecto |
| `deploy` | usuario operativo sin acceso general a `sudo` |
| `ops` | grupo autorizado para colaborar |
| `/srv/consultor-linux` | raíz del proyecto |
| `/srv/consultor-linux/laboratorios/04-permisos` | único árbol modificado en la práctica |

Trabajaremos con privilegio mínimo: una configuración puede ser legible por `deploy` sin ser modificable; un directorio de entregas sí puede permitir escritura al equipo.

Los valores entre `< >` son marcadores de una sintaxis general. No los copies literalmente: utiliza después el ejemplo completo con las identidades y rutas del curso.

## Modelo mental

```text
-rw-r----- 1 ubuntu ops 24 jul 04 10:00 app.conf
│└┬┘└┬┘└┬┘   └dueño └grupo
│ │  │  └── otros:  ---
│ │  └───── grupo:  r--
│ └──────── dueño:  rw-
└────────── archivo regular

solicitud de deploy
  ├─ ¿es dueño? no
  ├─ ¿pertenece a ops? sí → usa los bits del grupo
  └─ no se combinan bits de otras categorías
```

## 4.1 Identidades: UID, GID y grupos

```bash
whoami
id
id deploy
getent passwd deploy
getent group ops
sudo passwd -S deploy
```

Salida representativa:

```text
uid=1001(deploy) gid=1001(deploy) groups=1001(deploy),1002(ops)
deploy:x:1001:1001::/home/deploy:/bin/bash
ops:x:1002:deploy
deploy L ...
```

- UID y GID son las identidades numéricas que usa el kernel.
- `getent` consulta las fuentes configuradas por el sistema, no sólo archivos locales.
- `passwd -S` informa el estado; `L` indica contraseña bloqueada. La práctica usa `sudo -u deploy`, no una contraseña compartida.

Si `ops` no aparece en `id deploy`, la sintaxis es:

```bash
sudo usermod -aG <grupo> <usuario>
```

Ejemplo concreto:

```bash
sudo usermod -aG ops deploy
id deploy
```

- `-G` define grupos secundarios.
- `-a` significa *append*: conserva membresías existentes. Omitirlo puede reemplazar la lista.
- Una sesión ya abierta no adopta grupos nuevos; hay que iniciar una sesión nueva. `sudo -u deploy` crea un proceso nuevo y permite comprobarlos.

No agregues `deploy` a `sudo`: su función es operar sólo los recursos que se le deleguen.

## 4.2 Significado de `r`, `w` y `x`

| Permiso | En un archivo | En un directorio | Valor |
|---|---|---|---:|
| `r` | leer contenido | listar nombres | 4 |
| `w` | modificar contenido | crear, borrar o renombrar entradas | 2 |
| `x` | ejecutarlo | atravesarlo y acceder a entradas conocidas | 1 |

En un directorio, `r` sin `x` permite ver nombres pero impide acceder normalmente a sus metadatos o contenidos. Para colaborar suelen necesitarse `rwx` en el directorio, pero no `x` en todos los archivos.

### Modos octales frecuentes

| Modo | Expansión | Uso típico |
|---:|---|---|
| `0600` | `rw-------` | secreto de un solo usuario |
| `0640` | `rw-r-----` | configuración legible por un equipo |
| `0660` | `rw-rw----` | archivo editable por el equipo |
| `0750` | `rwxr-x---` | script o directorio privado para un equipo |
| `2775` | `rwxrwsr-x` | directorio compartido con herencia de grupo |

El cero inicial deja claro que el número representa un modo. `2` en la cuarta posición activa **setgid** en un directorio: los objetos nuevos heredan su grupo.

## 4.3 `chmod`, `chown` y `chgrp`

Sintaxis parametrizada:

```bash
chmod <modo> <ruta>
sudo chown <usuario>:<grupo> <ruta>
sudo chgrp <grupo> <ruta>
```

| Marcador | Valor del ejemplo | Resultado |
|---|---|---|
| `<modo>` | `0640` | dueño lee/escribe; grupo lee; otros nada |
| `<usuario>` | `ubuntu` | propietario administrativo |
| `<grupo>` | `ops` | equipo autorizado |
| `<ruta>` | `/srv/consultor-linux/laboratorios/04-permisos/app.conf` | archivo de configuración |

Prepara el árbol de forma explícita:

```bash
BASE=/srv/consultor-linux/laboratorios/04-permisos
sudo install -d -o ubuntu -g ops -m 0750 "$BASE"
sudo install -o ubuntu -g ops -m 0640 /dev/null "$BASE/app.conf"
printf 'APP=portal\nPORT=8080\n' | sudo tee "$BASE/app.conf" >/dev/null
sudo chmod 0640 "$BASE/app.conf"

ls -ld "$BASE"
ls -l "$BASE/app.conf"
stat -c 'modo=%A (%a) dueño=%U grupo=%G ruta=%n' "$BASE/app.conf"
```

`BASE` existe sólo en el shell actual. Si abres otra terminal o reanudas la práctica otro día, ejecuta otra vez `BASE=/srv/consultor-linux/laboratorios/04-permisos` antes de copiar un bloque que use `"$BASE"`.

Salida esperada:

```text
modo=-rw-r----- (640) dueño=ubuntu grupo=ops ruta=.../app.conf
```

El mismo permiso puede expresarse simbólicamente:

```bash
chmod u=rw,g=r,o= "$BASE/app.conf"
```

- `u`, `g`, `o`: dueño, grupo y otros.
- `=` reemplaza exactamente los permisos de esa categoría.
- `+` agrega y `-` retira bits concretos.
- `chown`: cambia dueño y opcionalmente grupo; normalmente requiere `sudo`.
- `chgrp`: cambia únicamente el grupo.

Evita `chmod -R`: archivos, directorios y scripts no necesitan el mismo modo.

## 4.4 Directorio compartido con setgid

Sintaxis parametrizada:

```bash
sudo install -d -o <dueño> -g <grupo> -m 2775 <directorio_compartido>
```

Ejemplo copiable:

```bash
sudo install -d -o ubuntu -g ops -m 2775 "$BASE/compartido"

sudo -u deploy bash -c \
  'umask 0002; printf "estado=operativo\n" > \
  /srv/consultor-linux/laboratorios/04-permisos/compartido/reporte-deploy.txt'

stat -c 'modo=%A (%a) dueño=%U grupo=%G ruta=%n' \
  "$BASE/compartido" \
  "$BASE/compartido/reporte-deploy.txt"
```

Salida representativa:

```text
modo=drwxrwsr-x (2775) dueño=ubuntu grupo=ops ruta=.../compartido
modo=-rw-rw-r-- (664) dueño=deploy grupo=ops ruta=.../reporte-deploy.txt
```

Qué ocurrió:

1. `deploy` pudo crear el archivo porque pertenece a `ops` y el grupo tiene `rwx` en el directorio.
2. El setgid hizo que el archivo heredara `ops`, aunque el grupo principal de `deploy` se llame `deploy`.
3. `umask 0002` retiró escritura a “otros”, no al grupo; por eso el modo resultó `0664`.
4. `bash -c` es necesario para que tanto `printf` como la redirección `>` se ejecuten como `deploy`.

Para datos que no deben ser visibles fuera del equipo, usa una umask más restrictiva:

```bash
sudo -u deploy bash -c \
  'umask 0007; touch /srv/consultor-linux/laboratorios/04-permisos/compartido/privado.txt'
stat -c '%A %a %U %G %n' "$BASE/compartido/privado.txt"
```

El modo esperado es `660`: dueño y grupo pueden leer/escribir; otros no tienen acceso.

## 4.5 `sudo` y políticas de acceso

`sudo` no significa “convertir a todos en root”. Evalúa una política para ejecutar un comando como otra identidad y deja registro de la solicitud.

```bash
sudo -l
sudo -l -U deploy
```

`sudo -l` lista lo permitido para la cuenta actual. En condiciones normales, `deploy` no tendrá comandos administrativos autorizados.

Una regla de mínimo privilegio puede limitar ejecutable y argumentos. La siguiente práctica sólo crea un archivo temporal y valida su sintaxis; **no instala la política**:

```bash
POLITICA=/tmp/consultor-linux-ops.sudoers
printf '%s\n' \
  '%ops ALL=(root) NOPASSWD: /usr/bin/systemctl is-active nginx' \
  | sudo tee "$POLITICA" >/dev/null
sudo chmod 0440 "$POLITICA"
sudo visudo -cf "$POLITICA"
sudo rm -i -- "$POLITICA"
```

Salida esperada de la validación:

```text
/tmp/consultor-linux-ops.sudoers: parsed OK
```

- `%ops`: la regla se aplica al grupo, no a un usuario aislado.
- `ALL`: desde cualquier host cubierto por este archivo local.
- `(root)`: identidad de destino.
- `NOPASSWD` es razonable aquí sólo porque la cuenta está bloqueada y el comando permitido es una consulta concreta.
- La ruta absoluta y los argumentos limitan la autorización a `systemctl is-active nginx`, sin pager interactivo.
- `visudo -c`: valida sintaxis. Nunca edites `/etc/sudoers` con un editor común.

Como la política no se instala en `/etc/sudoers.d`, no cambia los permisos reales del sistema.

## Práctica guiada resuelta — Configuración protegida y entregas compartidas

Objetivo: `deploy` debe leer la configuración sin modificarla y debe poder escribir reportes compartidos.

```bash
# 1. Comprobar identidades y permisos de la ruta completa.
id deploy
namei -l "$BASE/app.conf"

# 2. Lectura permitida de la configuración.
sudo -u deploy cat "$BASE/app.conf"

# 3. Escritura permitida sólo en el directorio compartido.
sudo -u deploy bash -c \
  'umask 0007; printf "resultado=OK\n" > \
  /srv/consultor-linux/laboratorios/04-permisos/compartido/validacion.txt'

# 4. Verificar propietario, grupo y modos.
stat -c '%A %a %U %G %n' \
  "$BASE/app.conf" \
  "$BASE/compartido" \
  "$BASE/compartido/validacion.txt"

# 5. Comprobar el contenido con la identidad operativa.
sudo -u deploy cat "$BASE/compartido/validacion.txt"
```

Resultados esperados:

- `app.conf`: `640 ubuntu ops`;
- `compartido`: `2775 ubuntu ops`;
- `validacion.txt`: `660 deploy ops`;
- ambas lecturas muestran contenido y ninguna requiere hacer a `deploy` administrador.

## Fallo controlado — `sudo` no incluye la redirección

Primero demuestra que `deploy` no puede modificar la configuración:

```bash
sudo -u deploy bash -c \
  'printf "DEBUG=true\n" >> /srv/consultor-linux/laboratorios/04-permisos/app.conf'
printf 'código=%s\n' "$?"
```

Salida esperada:

```text
bash: .../app.conf: Permission denied
código=1
```

Diagnóstico:

```bash
namei -l "$BASE/app.conf"
stat -c '%A %a %U %G %n' "$BASE/app.conf"
id deploy
```

El grupo tiene lectura, pero no escritura. Eso protege la configuración. Si una tarea autorizada exigiera edición temporal, el administrador podría concederla y revertirla explícitamente:

```bash
sudo chmod g+w "$BASE/app.conf"
sudo -u deploy bash -c \
  'printf "DEBUG=false\n" >> /srv/consultor-linux/laboratorios/04-permisos/app.conf'
sudo chmod g-w "$BASE/app.conf"
stat -c '%A %a %U %G %n' "$BASE/app.conf"
```

El modo final vuelve a `640`. No uses `chmod 777`: habría concedido lectura, escritura y ejecución a cualquiera sin resolver qué acceso necesita cada rol.

Una trampa relacionada es:

```bash
# No ejecutar: ejemplo conceptual de una redirección mal elevada.
sudo printf 'texto\n' > /ruta/protegida
```

`sudo` sólo afecta a `printf`; la redirección la abre el shell original. Para escrituras administrativas deliberadas usa `sudo tee` o `sudo sh -c`, después de verificar la ruta.

## Comprobación y reversión

Audita el árbol sin cambiarlo:

```bash
find "$BASE" -maxdepth 2 -printf '%M %m %u %g %p\n' | sort
sudo -u deploy test -r "$BASE/app.conf" \
  && echo "deploy puede leer app.conf"
sudo -u deploy test ! -w "$BASE/app.conf" \
  && echo "deploy no puede modificar app.conf"
sudo -u deploy test -w "$BASE/compartido" \
  && echo "deploy puede entregar reportes"
```

Los archivos forman parte de las evidencias del curso y no se eliminan ahora. Para revertir una concesión accidental sobre la configuración:

```bash
sudo chown ubuntu:ops "$BASE/app.conf"
sudo chmod 0640 "$BASE/app.conf"
```

Estos comandos afectan una ruta concreta y restauran el estado documentado.

## Reto 4 — Área de operación con mínimo privilegio

Crea dentro de `$BASE/reto` tres zonas: `config`, `entregas` y `secretos`. `deploy` debe poder leer, pero no editar, `config/app.env`; crear archivos de grupo en `entregas`; y no debe poder leer `secretos/credencial.txt`. Los archivos creados en `entregas` deben heredar el grupo `ops`.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-4)

### Criterios de éxito

- `stat` muestra dueño, grupo y modos diferentes según la necesidad.
- `sudo -u deploy test -r` confirma lectura de la configuración.
- `sudo -u deploy test ! -w` confirma que la configuración no es editable.
- Un archivo creado por `deploy` en `entregas` pertenece a `ops`.
- `sudo -u deploy cat` sobre el secreto falla con `Permission denied`.
- No se usa `777`, no se agrega `deploy` a `sudo` y no se modifica `/etc/sudoers`.

## Checklist

- [ ] Interpreto los diez caracteres iniciales de `ls -l`.
- [ ] Distingo `rwx` en archivos y directorios.
- [ ] Puedo traducir entre modo simbólico y octal.
- [ ] Uso `usermod -aG` sin reemplazar grupos existentes.
- [ ] Creo un directorio setgid con grupo heredado.
- [ ] Diagnostico toda la ruta con `namei -l`.
- [ ] Delego el mínimo privilegio y valido políticas con `visudo`.
- [ ] Sé revertir permisos concretos sin aplicar cambios recursivos.
