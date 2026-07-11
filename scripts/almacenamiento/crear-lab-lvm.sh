#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/../.." && pwd)
lab_dir="$repo_dir/laboratorio/almacenamiento"
image="$lab_dir/storage-lab.img"
mount_dir="$lab_dir/mnt"
state_file="$lab_dir/estado.txt"
vg_name="vg_consultor_$(id -u)"
readonly lv_name=lv_respaldos

completed=false
cleanup_authorized=false

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup_on_exit() {
  local status=$?
  trap - EXIT INT TERM
  if [[ $completed != true && $cleanup_authorized == true ]]; then
    printf 'La creación no terminó; se intentará retirar sólo el laboratorio verificado.\n' >&2
    if ! bash "$script_dir/limpiar-lab-lvm.sh"; then
      printf 'La limpieza automática se detuvo por una guardia. Revisa el estado sin usar discos reales.\n' >&2
    fi
  fi
  exit "$status"
}

trap cleanup_on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

(( EUID != 0 )) || die 'Ejecuta el script como tu usuario normal; él solicitará sudo.'
[[ -f $repo_dir/README.md ]] || die 'No se identificó la raíz del curso.'
[[ $(realpath --canonicalize-missing "$image") == "$repo_dir/laboratorio/almacenamiento/storage-lab.img" ]] \
  || die 'La imagen no apunta al laboratorio esperado.'

for command_name in losetup parted partprobe udevadm pvcreate vgcreate lvcreate mkfs.ext4; do
  command -v "$command_name" >/dev/null 2>&1 \
    || die "Falta $command_name; ejecuta scripts/bootstrap-ubuntu.sh."
done

sudo true
if sudo vgs "$vg_name" >/dev/null 2>&1; then
  die "Ya existe $vg_name. Ejecuta primero el limpiador y revisa su resultado."
fi
[[ ! -e $image && ! -e $state_file ]] \
  || die 'Ya existe una imagen o estado anterior; no se sobrescribirá.'

validar_loop() {
  local loop=$1 backing tipo
  [[ $loop =~ ^/dev/loop[0-9]+$ && -b $loop ]] || return 1
  tipo=$(lsblk --noheadings --nodeps --output TYPE "$loop" | xargs)
  [[ $tipo == loop ]] || return 1
  backing=$(sudo losetup --noheadings --output BACK-FILE "$loop" | xargs)
  [[ $(realpath -- "$backing") == $(realpath -- "$image") ]]
}

validar_particion() {
  local part=$1 loop=$2 parent
  [[ $part == "${loop}p1" && -b $part ]] || return 1
  parent=$(lsblk --noheadings --nodeps --output PKNAME "$part" | xargs)
  [[ $parent == $(basename -- "$loop") ]]
}

mkdir -p -- "$lab_dir" "$mount_dir"
cleanup_authorized=true
truncate --size 512M "$image"
loop_device=$(sudo losetup --find --show --partscan --nooverlap "$image")
printf 'IMAGE=%s\nLOOP=%s\nVG=%s\nLV=%s\nMOUNT=%s\n' \
  "$image" "$loop_device" "$vg_name" "$lv_name" "$mount_dir" > "$state_file"

validar_loop "$loop_device" || die 'El loop no pertenece a la imagen del curso.'
sudo parted --script "$loop_device" \
  mklabel gpt \
  mkpart primary 1MiB 100% \
  set 1 lvm on
sudo partprobe "$loop_device"
sudo udevadm settle

partition="${loop_device}p1"
for _ in {1..30}; do
  [[ -b $partition ]] && break
  sleep 0.1
done
validar_loop "$loop_device" || die 'El backing file cambió durante la práctica.'
validar_particion "$partition" "$loop_device" \
  || die 'La partición no pertenece al loop verificado.'

sudo pvcreate "$partition"
sudo vgcreate "$vg_name" "$partition"
sudo lvcreate --size 320M --name "$lv_name" "$vg_name"
sudo mkfs.ext4 -q -L CONSULTOR_LAB "/dev/$vg_name/$lv_name"
sudo mount "/dev/$vg_name/$lv_name" "$mount_dir"
sudo chown "$(id -u):$(id -g)" "$mount_dir"
printf 'evidencia almacenada en LVM\n' > "$mount_dir/evidencia.txt"
sync

completed=true
trap - EXIT INT TERM
printf 'Laboratorio LVM creado de forma aislada.\n'
lsblk --fs "$loop_device"
printf '\nPunto de montaje:\n'
findmnt --mountpoint "$mount_dir"
printf '\nPara limpiar, como el mismo usuario:\n'
printf '  bash scripts/almacenamiento/limpiar-lab-lvm.sh\n'
