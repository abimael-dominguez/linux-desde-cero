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
lv_path="/dev/$vg_name/$lv_name"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

(( EUID != 0 )) || die 'Ejecuta el script como el mismo usuario normal; él solicitará sudo.'
[[ -f $repo_dir/README.md ]] || die 'No se identificó la raíz del curso.'
[[ $(realpath --canonicalize-missing "$image") == "$repo_dir/laboratorio/almacenamiento/storage-lab.img" ]] \
  || die 'La imagen no apunta al laboratorio esperado.'

if [[ ! -e $image && ! -e $state_file ]]; then
  printf 'No existe una imagen LVM del curso; no hay nada que limpiar.\n'
  exit 0
fi
[[ -e $image ]] || die 'Existe estado sin imagen; se requiere revisión manual.'
sudo true

mapfile -t associated_loops < <(
  sudo losetup --associated "$image" --noheadings --output NAME | xargs -n1
)
(( ${#associated_loops[@]} <= 1 )) \
  || die 'La imagen tiene más de un loop asociado; no se elegirá uno al azar.'

if (( ${#associated_loops[@]} == 0 )); then
  sudo vgs "$vg_name" >/dev/null 2>&1 \
    && die "$vg_name existe, pero la imagen no tiene loop; no se borrará nada."
  rm -f -- "$image" "$state_file"
  rmdir --ignore-fail-on-non-empty "$mount_dir" "$lab_dir" 2>/dev/null || true
  printf 'Se retiró una imagen parcial sin loop ni VG.\n'
  exit 0
fi

loop_device=${associated_loops[0]}
[[ $loop_device =~ ^/dev/loop[0-9]+$ && -b $loop_device ]] \
  || die 'El objetivo no es un dispositivo /dev/loopN válido.'
[[ $(lsblk --noheadings --nodeps --output TYPE "$loop_device" | xargs) == loop ]] \
  || die 'El dispositivo asociado no es de tipo loop.'
backing_file=$(sudo losetup --noheadings --output BACK-FILE "$loop_device" | xargs)
[[ $(realpath -- "$backing_file") == $(realpath -- "$image") ]] \
  || die 'El loop no pertenece a la imagen esperada.'

partition="${loop_device}p1"
if [[ -b $partition ]]; then
  parent=$(lsblk --noheadings --nodeps --output PKNAME "$partition" | xargs)
  [[ $parent == $(basename -- "$loop_device") ]] \
    || die 'La partición no pertenece al loop del curso.'
fi

if findmnt --mountpoint "$mount_dir" >/dev/null 2>&1; then
  mounted_source=$(findmnt --noheadings --raw --output SOURCE --mountpoint "$mount_dir")
  [[ $(readlink -f -- "$mounted_source") == $(readlink -f -- "$lv_path") ]] \
    || die 'El punto de montaje contiene otro dispositivo; no se desmontará.'
  sudo umount "$mount_dir"
fi

if sudo vgs "$vg_name" >/dev/null 2>&1; then
  [[ -b $partition ]] || die "$vg_name existe, pero falta la partición esperada."
  pv_device=$(sudo pvs --noheadings --options pv_name,vg_name 2>/dev/null \
    | awk -v vg="$vg_name" '$2 == vg {print $1}')
  [[ -n $pv_device && $(readlink -f -- "$pv_device") == $(readlink -f -- "$partition") ]] \
    || die "El PV de $vg_name no es la partición del loop verificado."

  other_lvs=$(sudo lvs --noheadings --options lv_name "$vg_name" 2>/dev/null \
    | awk -v expected="$lv_name" '$1 != expected {print $1}')
  [[ -z $other_lvs ]] || die "$vg_name contiene otros LV; no se eliminará."
  if sudo lvs "$vg_name/$lv_name" >/dev/null 2>&1; then
    sudo lvremove --yes "$vg_name/$lv_name"
  fi
  sudo vgremove --yes "$vg_name"
  sudo pvremove --yes "$pv_device"
elif [[ -b $partition ]] && sudo pvs "$partition" >/dev/null 2>&1; then
  partial_vg=$(sudo pvs --noheadings --options vg_name "$partition" | xargs)
  [[ -z $partial_vg ]] || die "La partición pertenece al VG inesperado $partial_vg."
  sudo pvremove --yes "$partition"
fi

backing_file=$(sudo losetup --noheadings --output BACK-FILE "$loop_device" | xargs)
[[ $(realpath -- "$backing_file") == $(realpath -- "$image") ]] \
  || die 'El backing file cambió antes de liberar el loop.'
sudo losetup --detach "$loop_device"

if sudo losetup --associated "$image" --noheadings --output NAME | grep -q .; then
  die 'La imagen continúa asociada; no se eliminará.'
fi

rm -f -- "$image" "$state_file"
rmdir --ignore-fail-on-non-empty "$mount_dir" "$lab_dir" 2>/dev/null || true
printf 'Laboratorio LVM eliminado; no se modificaron discos físicos.\n'
