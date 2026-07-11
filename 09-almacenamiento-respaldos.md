# 9. Almacenamiento y respaldos

## Objetivos

Al terminar este capítulo podrás:

- distinguir dispositivo, partición, sistema de archivos y punto de montaje;
- interpretar capacidad con `lsblk`, `findmnt`, `df` y `du`;
- explicar PV, VG y LV y construir un laboratorio LVM desechable;
- validar una entrada tipo `fstab` sin modificar `/etc/fstab`;
- respaldar fuera del volumen, verificar, restaurar y limpiar el laboratorio.

## Contexto, seguridad y directorio inicial

Ejecuta este módulo **en EC2 Ubuntu 24.04** como `ubuntu`. No se creará otro
EBS: un archivo disperso de 512 MiB dentro del volumen raíz simulará un disco.
El archivo empieza ocupando muy pocos bloques y crece sólo con los datos
escritos, por lo que es apropiado para el perfil Free Tier.

> **Límite de seguridad:** todos los comandos que escriben metadatos deben
> recibir un dispositivo `/dev/loopN` cuya ruta de respaldo coincida
> exactamente con `storage-lab.img`. Nunca sustituyas ese valor por
> `/dev/nvme...`, `/dev/xvd...`, `/dev/sd...` ni el dispositivo que contiene `/`.

Prepara las herramientas y el espacio de trabajo:

```bash
sudo apt update
sudo apt install -y lvm2 parted e2fsprogs

LAB="$HOME/consultor-linux-lab/modulo-09"
IMG="$LAB/storage-lab.img"
MNT="$LAB/mnt"
VG="vg_consultor_${UID}"
LV="lv_respaldos"

mkdir -p "$LAB" "$MNT" "$LAB"/{exportado,restaurado}
cd "$LAB"
printf 'LAB=%s\nIMG=%s\nVG=%s\nLV=%s\n' "$LAB" "$IMG" "$VG" "$LV"
```

`UID` es el identificador numérico del usuario y reduce colisiones entre
alumnos. Si cierras la terminal, vuelve a definir estas variables antes de
continuar.

## Modelo mental: de bloques a archivos

```text
archivo disperso storage-lab.img
              |
              v
dispositivo loop /dev/loopN
              |
              v
partición /dev/loopNp1
              |
              v
PV -- pertenece a --> VG -- entrega espacio a --> LV
                                                |
                                                v
                                      sistema de archivos ext4
                                                |
                                                v
                                      punto de montaje LAB/mnt
```

- Un **dispositivo de bloques** entrega sectores; no es todavía una carpeta.
- Una **partición** delimita una región del dispositivo.
- Un **sistema de archivos** organiza archivos, permisos y metadatos.
- **Montar** hace visible ese sistema de archivos en un directorio.
- Un **PV** aporta capacidad a un **VG**; uno o más **LV** consumen capacidad
  del grupo y se presentan como dispositivos de bloques.

LVM separa la capacidad física de los volúmenes usados por las aplicaciones.
No reemplaza un respaldo: borrar el VG puede destruir todos sus LV.

## Inventario seguro del sistema

Estos comandos son de lectura:

```bash
findmnt -no SOURCE,FSTYPE,SIZE,USED,AVAIL,TARGET /
lsblk -o NAME,TYPE,SIZE,FSTYPE,LABEL,MOUNTPOINTS
df -hT /
du -sh "$HOME"
```

Salida representativa de EC2:

```text
/dev/root ext4 19.2G 4.1G 15.0G /
NAME         TYPE  SIZE FSTYPE MOUNTPOINTS
nvme0n1      disk   20G
└─nvme0n1p1  part 19.9G ext4   /
```

Los nombres y cifras cambian según la instancia. `df` informa capacidad del
sistema de archivos; `du` suma bloques de archivos alcanzables desde una ruta.
No copies un nombre visto en `lsblk` para usarlo en comandos destructivos.

## Crear el disco simulado y asociar un loop

### Sintaxis parametrizada

```text
truncate -s <tamano> <archivo_imagen>
sudo losetup --find --show --partscan <archivo_imagen>
```

Valores del laboratorio:

| Parámetro | Valor | Propósito |
|---|---|---|
| `<tamano>` | `512M` | capacidad lógica máxima |
| `<archivo_imagen>` | `$LAB/storage-lab.img` | único respaldo permitido |

Antes de empezar, evita reutilizar por error un VG anterior:

```bash
if sudo vgs "$VG" > /dev/null 2>&1; then
  printf 'Ya existe %s; ejecuta primero la limpieza documentada\n' "$VG" >&2
  exit 1
fi

truncate -s 512M "$IMG"
ls -lh "$IMG"
du -h "$IMG"
LOOP=$(sudo losetup --find --show --partscan --nooverlap "$IMG")
printf '%s\n' "$LOOP" | tee "$LAB/loop-device"
```

`ls -lh` muestra tamaño lógico `512M`; `du` debe ser mucho menor al principio.
`losetup --find` elige un loop libre, `--show` imprime su nombre, `--partscan`
permite descubrir particiones y `--nooverlap` evita asociar dos loops al mismo
archivo.

### Guardia obligatoria

Copia y ejecuta esta función antes de particionar y nuevamente antes de limpiar:

```bash
validar_loop() {
  local loop=$1
  local esperado=$2
  local backing

  [[ "$loop" =~ ^/dev/loop[0-9]+$ ]] || {
    printf 'ERROR: no es un loop permitido: %s\n' "$loop" >&2
    return 1
  }
  [[ -b "$loop" ]] || {
    printf 'ERROR: no existe el dispositivo %s\n' "$loop" >&2
    return 1
  }

  backing=$(sudo losetup --list --noheadings --raw \
    --output BACK-FILE "$loop")
  [[ "$(readlink -f -- "$backing")" == "$(readlink -f -- "$esperado")" ]] || {
    printf 'ERROR: %s no pertenece a %s\n' "$loop" "$esperado" >&2
    return 1
  }
}

validar_loop "$LOOP" "$IMG" \
  && printf 'OK: %s pertenece a %s\n' "$LOOP" "$IMG"
```

No continúes si no aparece `OK`. La validación compara rutas canónicas, no
sólo un nombre que podría haber sido reasignado después de reiniciar.

## Particionar exclusivamente el loop

```bash
validar_loop "$LOOP" "$IMG" || exit 1
sudo parted --script "$LOOP" mklabel gpt
sudo parted --script "$LOOP" mkpart primary ext4 1MiB 100%
sudo partprobe "$LOOP"
sudo udevadm settle

PART="${LOOP}p1"
test -b "$PART" || {
  printf 'No apareció la partición %s\n' "$PART" >&2
  exit 1
}
lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINTS "$LOOP"
```

Salida representativa:

```text
NAME      TYPE  SIZE FSTYPE MOUNTPOINTS
loop7     loop  512M
└─loop7p1 part  511M
```

- `--script`: evita preguntas interactivas;
- `mklabel gpt`: crea la tabla de particiones dentro de la imagen;
- `1MiB`: deja alineación al comienzo;
- `partprobe` y `udevadm settle`: notifican al kernel y esperan dispositivos.

El número de loop es variable. `PART="${LOOP}p1"` lo deriva del loop que ya
fue validado; no lo escribas manualmente.

## Crear PV, VG, LV y ext4

### Sintaxis parametrizada

```text
sudo pvcreate <particion_loop>
sudo vgcreate <grupo> <PV>
sudo lvcreate --size <tamano> --name <volumen> <grupo>
sudo mkfs.ext4 -L <etiqueta> <ruta_LV>
```

Ejemplo concreto:

```bash
validar_loop "$LOOP" "$IMG" || exit 1
[[ "$(lsblk --noheadings --nodeps --output PKNAME "$PART" | xargs)" == "$(basename "$LOOP")" ]] || {
  printf 'ERROR: %s no es partición de %s\n' "$PART" "$LOOP" >&2
  exit 1
}

sudo pvcreate "$PART"
sudo vgcreate "$VG" "$PART"
sudo lvcreate --size 320M --name "$LV" "$VG"

LV_PATH="/dev/$VG/$LV"
sudo mkfs.ext4 -L CONSULTOR_LAB "$LV_PATH"

sudo pvs --units m
sudo vgs "$VG" --units m
sudo lvs "$VG/$LV" --units m -o lv_name,vg_name,lv_size,lv_attr
```

- `pvcreate`: escribe metadatos LVM en la partición validada;
- `vgcreate`: agrupa capacidad;
- `lvcreate --size 320M`: reserva parte del VG y deja espacio sin asignar;
- `mkfs.ext4 -L`: crea ext4 y una etiqueta reconocible;
- `lv_attr` resume tipo, permisos y estado del LV.

La salida debe mostrar `vg_consultor_<UID>` y `lv_respaldos`. Si aparece otro
dispositivo como PV, detente y revisa las variables.

## Montar, usar y comprobar

```bash
mkdir -p "$MNT"
sudo mount "$LV_PATH" "$MNT"
sudo chown "$USER":"$(id -gn)" "$MNT"

printf 'evidencia almacenada en LVM\n' > "$MNT/evidencia.txt"
sync

findmnt --mountpoint "$MNT" -o SOURCE,FSTYPE,SIZE,USED,AVAIL,TARGET
df -hT "$MNT"
sudo du -sh "$MNT"
```

Salida representativa:

```text
SOURCE                                      FSTYPE SIZE USED AVAIL TARGET
/dev/mapper/vg_consultor_1000-lv_respaldos ext4   286M ...  ...  .../mnt
```

El tamaño utilizable puede ser menor que 320 MiB por metadatos. `chown` cambia
la raíz **del sistema de archivos de laboratorio**, no el directorio personal.

## `fstab` aislado: documentar sin tocar el arranque

`/etc/fstab` controla montajes de arranque. Una entrada incorrecta puede dejar
un servidor inaccesible, por lo que la práctica usa otro archivo:

```bash
UUID_LAB=$(sudo blkid -s UUID -o value "$LV_PATH")
printf 'UUID=%s %s ext4 defaults,nofail 0 2\n' \
  "$UUID_LAB" "$MNT" > "$LAB/fstab.example"

cat "$LAB/fstab.example"
findmnt --verify --tab-file "$LAB/fstab.example"
```

Una salida correcta termina aproximadamente con:

```text
0 parse errors, 0 errors, 0 warnings
```

- `UUID=` evita depender del nombre `/dev/mapper/...`;
- `defaults`: conjunto habitual de opciones;
- `nofail`: el arranque puede continuar si el dispositivo opcional no existe;
- `0`: no usar `dump`; `2`: orden de comprobación posterior a la raíz;
- `--tab-file`: obliga a `findmnt` a leer el archivo alternativo.

**No ejecutes** `sudo tee -a /etc/fstab` ni `mount -a` en esta práctica.

## Respaldar fuera del volumen

Si el respaldo vive sólo dentro del LV que protege, se pierde con el mismo
fallo. Empaqueta en `$LAB/exportado`, que pertenece al volumen raíz:

```bash
printf 'servicio=consultor-linux\n' > "$MNT/configuracion.ini"
ARCHIVO="$LAB/exportado/lv-respaldo-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"

tar --exclude='./lost+found' -czf "$ARCHIVO" -C "$MNT" .
gzip -t "$ARCHIVO"
(
  cd "$LAB/exportado"
  sha256sum "$(basename "$ARCHIVO")" \
    > "$(basename "$ARCHIVO").sha256"
  sha256sum -c "$(basename "$ARCHIVO").sha256"
)
tar -tzf "$ARCHIVO"
```

La verificación debe mostrar `[nombre].tar.gz: OK`. Descarga después el
archivo y su `.sha256` a tu equipo con SCP, como en el módulo 6.

Regla 3-2-1 como objetivo operativo: tres copias, en dos medios o ubicaciones,
y una fuera del servidor. Este laboratorio produce una copia local exportable;
no afirma cumplir 3-2-1 hasta descargarla y administrarla fuera de EC2.

Un snapshot LVM captura bloques de un LV en un instante y consume espacio del
VG conforme cambian datos. Es útil para consistencia temporal, pero comparte
el mismo almacenamiento y **no sustituye un respaldo**. No se creará aquí para
mantener el laboratorio dentro de 512 MiB.

## Práctica guiada resuelta: desmontar, montar y restaurar

Primero verifica que el punto contiene exactamente el LV del laboratorio:

```bash
ORIGEN_MONTADO=$(findmnt -rn -o SOURCE --mountpoint "$MNT")
[[ "$(readlink -f -- "$ORIGEN_MONTADO")" == "$(readlink -f -- "$LV_PATH")" ]] \
  || { printf 'Montaje inesperado; se cancela\n' >&2; exit 1; }

sudo umount "$MNT"
findmnt --mountpoint "$MNT" > /dev/null || printf 'OK: desmontado\n'

sudo mount "$LV_PATH" "$MNT"
cat "$MNT/evidencia.txt"
```

Salida esperada:

```text
OK: desmontado
evidencia almacenada en LVM
```

Esto prueba persistencia después de desmontar. Ahora prueba restauración en
una carpeta distinta, sin sobrescribir el origen:

```bash
rm -rf -- "$LAB/restaurado/contenido"
mkdir -p "$LAB/restaurado/contenido"
tar -xzf "$ARCHIVO" -C "$LAB/restaurado/contenido"
diff -ru --exclude=lost+found "$MNT" "$LAB/restaurado/contenido"
printf 'Estado de restauración: %s\n' "$?"
```

`diff` sin salida y estado `0` confirma igualdad en el momento de comparar.

## Fallo controlado: detectar un `fstab` inválido

La prueba no instala ni monta nada:

```bash
printf '%s\n' \
  'UUID=00000000-0000-0000-0000-000000000000 /ruta-que-no-existe ext4 defaults 0 2' \
  > "$LAB/fstab.invalid"

estado=0
findmnt --verify --tab-file "$LAB/fstab.invalid" \
  > "$LAB/fstab-invalid.out" 2>&1 || estado=$?

printf 'Estado esperado distinto de cero: %s\n' "$estado"
cat "$LAB/fstab-invalid.out"
```

`findmnt` debe informar origen y destino inaccesibles. La verificación previa
convierte un posible fallo de arranque en un error de laboratorio reversible.

## Verificación y reversión segura

Guarda primero el respaldo exportado y su hash. Después redefine las variables
por si abriste otra terminal y recupera el loop registrado:

```bash
LAB="$HOME/consultor-linux-lab/modulo-09"
IMG="$LAB/storage-lab.img"
MNT="$LAB/mnt"
VG="vg_consultor_${UID}"
LV="lv_respaldos"
LV_PATH="/dev/$VG/$LV"
LOOP=$(<"$LAB/loop-device")
PART="${LOOP}p1"
```

Redefine y ejecuta la guardia; se repite intencionalmente para que la limpieza
sea autocontenida:

```bash
validar_loop() {
  local loop=$1
  local esperado=$2
  local backing
  [[ "$loop" =~ ^/dev/loop[0-9]+$ ]] || return 1
  [[ -b "$loop" ]] || return 1
  backing=$(sudo losetup --list --noheadings --raw \
    --output BACK-FILE "$loop")
  [[ "$(readlink -f -- "$backing")" == "$(readlink -f -- "$esperado")" ]]
}

validar_loop "$LOOP" "$IMG" || {
  printf 'ABORTADO: el loop no pertenece a la imagen esperada\n' >&2
  exit 1
}
[[ "$(lsblk --noheadings --nodeps --output PKNAME "$PART" | xargs)" == "$(basename "$LOOP")" ]] || {
  printf 'ABORTADO: la partición no pertenece al loop\n' >&2
  exit 1
}
```

Sólo después de ambas validaciones, desmonta y elimina de adentro hacia afuera:

```bash
if findmnt -rn --mountpoint "$MNT" > /dev/null; then
  origen=$(findmnt -rn -o SOURCE --mountpoint "$MNT")
  [[ "$(readlink -f -- "$origen")" == "$(readlink -f -- "$LV_PATH")" ]] || {
    printf 'ABORTADO: %s contiene otro sistema de archivos\n' "$MNT" >&2
    exit 1
  }
  sudo umount "$MNT"
fi

sudo lvremove -y "$VG/$LV"
sudo vgremove -y "$VG"
sudo pvremove -y "$PART"

validar_loop "$LOOP" "$IMG" || exit 1
sudo losetup --detach "$LOOP"

if sudo losetup -j "$IMG" | grep -q .; then
  printf 'ERROR: la imagen aún está asociada\n' >&2
  exit 1
fi

rm -f -- "$IMG" "$LAB/loop-device"
rmdir "$MNT" 2>/dev/null || true
printf 'OK: laboratorio de bloques retirado; respaldo exportado conservado\n'
```

Verificación final:

```bash
sudo vgs "$VG" 2>/dev/null || printf 'VG eliminado\n'
test ! -e "$IMG" && printf 'Imagen eliminada\n'
find "$LAB/exportado" -maxdepth 1 -type f -printf '%f\n' | sort
```

No uses `losetup -D`, `vgremove` sin nombre ni comodines: podrían afectar
recursos ajenos al curso.

## Automatización de referencia con guardias

La ruta anterior es manual porque debes comprender cada capa antes de
automatizarla. El repositorio incluye después una implementación repetible con
los mismos valores (`512M`, `vg_consultor_<UID>`, `lv_respaldos` de `320M`).
Opera exclusivamente en `laboratorio/almacenamiento`, no en el laboratorio
manual de tu `HOME`:

```bash
cd "$HOME/linux-desde-cero"
bash scripts/preparar-lab.sh
less scripts/almacenamiento/crear-lab-lvm.sh
less scripts/almacenamiento/limpiar-lab-lvm.sh

bash scripts/almacenamiento/crear-lab-lvm.sh
bash scripts/almacenamiento/limpiar-lab-lvm.sh
```

Ejecuta los scripts como `ubuntu`, **sin** anteponer `sudo`; ellos elevan sólo
las operaciones de bloques. Ambos validan ruta, tipo loop, backing file,
partición y relación PV/VG antes de escribir o borrar. Si la creación falla,
intenta retirar sólo los recursos que ya quedaron ligados a la imagen. No
mezcles esta ruta automatizada con el laboratorio manual todavía activo.

## Reto 9: volumen desechable con recuperación

Después de completar la limpieza, crea en `$LAB/reto-09` una imagen dispersa
de `384M`, asóciala a un loop validado, crea una partición, el VG
`vg_reto_<UID>` y el LV `lv_datos` de `256M`. Monta ext4, crea tres archivos,
prepara y valida `fstab.reto` sin tocar `/etc/fstab`, exporta un respaldo con
hash, demuestra restauración y elimina por completo loop/LVM conservando el
respaldo fuera de la imagen.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-9)

### Criterios de éxito

- la guardia comprueba tipo `/dev/loopN`, backing file y parent de la partición;
- `pvs`, `vgs`, `lvs`, `findmnt`, `df` y `du` se usan para evidenciar capas;
- `findmnt --verify --tab-file` acepta `fstab.reto` y `/etc/fstab` no cambia;
- SHA-256 es válido y `diff -ru` confirma la restauración;
- al final no existen el VG, el loop ni la imagen, pero sí el respaldo exportado.

## Checklist

- [ ] Distingo bloques, partición, sistema de archivos y montaje.
- [ ] Interpreto `lsblk`, `findmnt`, `df` y `du` sin mezclar conceptos.
- [ ] Explico PV, VG y LV y por qué LVM no es un respaldo.
- [ ] Valido archivo, loop y parent antes de escribir o limpiar.
- [ ] Nunca usé un disco real ni modifiqué `/etc/fstab`.
- [ ] Verifiqué y restauré el respaldo fuera del volumen.
- [ ] Retiré todos los recursos del laboratorio de bloques.
