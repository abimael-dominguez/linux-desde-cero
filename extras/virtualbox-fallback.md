# Anexo — VirtualBox como laboratorio alternativo

Usa esta ruta si no puedes comprobar un Free Tier vigente. Las prácticas no
cambian: Ubuntu corre en tu computadora y no se crea ningún recurso AWS.

## Resultado esperado

Al terminar tendrás una VM Ubuntu Server 24.04 x86-64 con:

- 2 vCPU, 2 GiB de RAM y un disco dinámico de 20 GiB;
- red NAT, sin modo puente;
- SSH accesible sólo desde el host por `127.0.0.1:2222`;
- el mismo repositorio, usuarios, rutas y stack Docker del curso.

El perfil mínimo de 1 GiB requiere 2 GiB de swap. Si el host no puede reservar
al menos 2 GiB para la VM, no ejecutes el stack completo durante la clase.

## 1. Instalar VirtualBox

Descarga el paquete para tu sistema desde [Oracle VirtualBox](https://www.virtualbox.org/wiki/Downloads).
La edición base basta: el Extension Pack no es requisito del curso.

En un host Ubuntu también puedes usar el paquete de su repositorio:

```bash
sudo apt update
sudo apt install -y virtualbox
VBoxManage --version
```

En Windows o macOS, ejecuta el instalador oficial y reinicia si solicita cargar
controladores. No abras VirtualBox como `root` ni como administrador para el
uso cotidiano.

## 2. Descargar y verificar Ubuntu Server

La imagen de referencia es Ubuntu Server 24.04.4 LTS para AMD64. En Linux,
macOS o WSL, usa un directorio de descargas:

```bash
mkdir -p "$HOME/Downloads/ubuntu-consultor"
cd "$HOME/Downloads/ubuntu-consultor"

BASE_URL=https://releases.ubuntu.com/noble
ISO=ubuntu-24.04.4-live-server-amd64.iso

curl --fail --location --remote-name "$BASE_URL/$ISO"
curl --fail --location --remote-name "$BASE_URL/SHA256SUMS"
sha256sum --ignore-missing --check SHA256SUMS
```

La salida debe incluir:

```text
ubuntu-24.04.4-live-server-amd64.iso: OK
```

`ISO` es el nombre concreto; no escribas `<archivo.iso>`. Si Ubuntu publica una
revisión 24.04 posterior, toma el nombre y `SHA256SUMS` de la misma página y no
mezcles archivos de dos revisiones.

En PowerShell, después de descargar ambos archivos desde el sitio oficial:

```powershell
$Iso = "$HOME\Downloads\ubuntu-24.04.4-live-server-amd64.iso"
Get-FileHash -Algorithm SHA256 $Iso
```

Compara el valor completo con la línea correspondiente de `SHA256SUMS`.

## 3. Crear la VM

En VirtualBox selecciona **Nueva** y utiliza estos valores:

| Campo | Valor |
|---|---|
| Nombre | `consultor-linux` |
| Tipo/versión | Linux / Ubuntu (64-bit) |
| ISO | la imagen verificada |
| CPU | 2 procesadores |
| Memoria | 2048 MiB |
| Disco | VDI dinámico de 20 GiB |
| Red | NAT |

No elijas red puente: expondría la VM directamente a la red física. Si
VirtualBox no ofrece sistemas de 64 bits, habilita VT-x/AMD-V en firmware y
evita ejecutar simultáneamente otro hipervisor.

## 4. Instalar Ubuntu sin ambigüedad

Inicia la VM y completa el instalador:

1. selecciona idioma y teclado;
2. conserva la red por DHCP y el disco virtual completo;
3. crea el usuario `ubuntu` y anota su contraseña local;
4. nombra el servidor `consultor-linux`;
5. marca **Install OpenSSH server**;
6. no importes una clave externa ni selecciones paquetes adicionales;
7. reinicia y expulsa la ISO cuando el instalador lo solicite.

Aquí `ubuntu` es el usuario concreto que usarán los ejemplos. Si ya instalaste
la VM con otro nombre, sustituye ese valor en todos los comandos.

Desde la consola de la VM comprueba:

```bash
whoami
cat /etc/os-release
uname -m
systemctl is-active ssh
```

Se espera `ubuntu`, Ubuntu `24.04`, `x86_64` y `active`. Si olvidaste instalar
SSH:

```bash
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```

## 5. Crear el reenvío SSH seguro

Apaga la VM y abre **Configuración → Red → Adaptador 1 → NAT → Avanzado →
Reenvío de puertos**. Agrega exactamente:

| Nombre | Protocolo | IP host | Puerto host | IP invitado | Puerto invitado |
|---|---|---|---:|---|---:|
| `ssh` | TCP | `127.0.0.1` | `2222` | vacío | `22` |

Vuelve a iniciar. Desde el host:

```bash
ssh -p 2222 ubuntu@127.0.0.1
```

La primera vez valida que el destino sea `127.0.0.1:2222` antes de aceptar la
huella. El login por contraseña existe sólo para esta VM local; en EC2 se usa
la clave administrada por AWS.

## 6. Preparar el curso

Dentro de la VM:

```bash
git clone <URL_DEL_REPOSITORIO> linux-desde-cero
cd linux-desde-cero
bash scripts/bootstrap-ubuntu.sh
bash scripts/verificar-entorno.sh
bash scripts/preparar-lab.sh
```

Sustituye `<URL_DEL_REPOSITORIO>` por la URL entregada por el instructor. Para
el perfil de 1 GiB:

```bash
sudo bash scripts/configurar-swap.sh 2
bash scripts/verificar-entorno.sh
```

## 7. Acceder al proyecto web

El proxy se liga al loopback de la VM. No agregues un reenvío de puerto web en
VirtualBox; usa el mismo túnel SSH del curso desde el host:

```bash
ssh -p 2222 \
  -L 8080:127.0.0.1:8080 \
  ubuntu@127.0.0.1
```

Mientras esa conexión siga abierta visita `http://127.0.0.1:8080` en el host.

## 8. Snapshot, parada y eliminación

Después del bootstrap y con la VM apagada, crea un snapshot llamado
`ubuntu-limpio`. Un snapshot facilita repetir prácticas, pero ocupa disco del
host y no sustituye el respaldo del proyecto.

Al terminar una clase, dentro de la VM:

```bash
sudo shutdown -h now
```

Al concluir el curso:

1. descarga o copia fuera de la VM el respaldo y verifica SHA-256;
2. apaga Ubuntu;
3. en VirtualBox selecciona **Eliminar → Borrar todos los archivos**;
4. confirma que desaparecieron el disco virtual y los snapshots;
5. elimina la ISO sólo si ya no la necesitas.

No agregues carpetas compartidas que contengan claves SSH, credenciales o todo
tu directorio personal.

## Problemas frecuentes

| Síntoma | Comprobación |
|---|---|
| No conecta `127.0.0.1:2222` | VM encendida, regla NAT y `systemctl is-active ssh` |
| Puerto 2222 ocupado | cambia sólo el puerto host, por ejemplo a `2223`, y adapta `ssh -p` |
| VM sin Internet | adaptador 1 habilitado en modo NAT y DHCP dentro de Ubuntu |
| Docker se queda sin memoria | 2 GiB recomendados o 1 GiB más swap verificada |
| El navegador no abre | stack sano, túnel SSH abierto y puerto local 8080 libre |

## Checklist

- [ ] Verifiqué el hash de la ISO.
- [ ] La VM usa NAT, no red puente.
- [ ] Creé el usuario concreto `ubuntu` y habilité OpenSSH.
- [ ] SSH sólo se reenvía por `127.0.0.1:2222`.
- [ ] `verificar-entorno.sh` no reporta errores.
- [ ] Sé abrir el túnel web y apagar la VM.
- [ ] Sé exportar el respaldo antes de borrar todos los archivos de la VM.
