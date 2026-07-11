# 12. Seguridad y hardening inicial

## Objetivos

Al terminar este capítulo podrás:

- aplicar defensa en profundidad a una EC2 sin perder el acceso SSH;
- reducir superficie mediante actualizaciones, servicios mínimos y privilegio mínimo;
- relacionar Security Groups, UFW, sockets y publicaciones de Docker;
- validar y endurecer OpenSSH con un archivo independiente y reversible;
- inspeccionar AppArmor, permisos, logs y consumo de recursos;
- comprobar que un respaldo existe, es íntegro y puede restaurarse.

## Antes de empezar

Seguridad no es ejecutar una lista de comandos de Internet. Primero identifica:

| Elemento | Valor del curso |
|---|---|
| Activo | EC2, datos de WordPress, claves SSH y respaldo |
| Administrador | usuario `ubuntu` con `sudo` |
| Usuario operativo | `deploy`, creado en capítulos anteriores |
| Entrada pública | únicamente TCP/22 desde la IP del alumno `/32` |
| Aplicación web | `127.0.0.1:8080`, accesible mediante túnel SSH |
| Base de datos | sólo red interna de Docker |
| Riesgos principales | credenciales expuestas, permisos excesivos, puertos públicos, pérdida de datos y costos olvidados |

Mantén abierta tu sesión SSH actual durante la sección de OpenSSH y abre una segunda terminal para probar. Nunca cierres la única conexión antes de verificar la nueva configuración.

Sitúate en el repositorio y comprueba el estado preparado en el capítulo 11:

```bash
cd ~/linux-desde-cero
sudo docker compose -f proyecto-compose/compose.yaml ps
```

Debes ver `db`, `wordpress` y `proxy` en ejecución y saludables. Si todavía no preparaste el stack o falta algún servicio, ejecuta `bash scripts/preparar-proyecto.sh`: ese script genera los secretos, descarga las imágenes e inicia los servicios en orden. No necesitas repetir manualmente `pull` y `up`.

## 12.1 Modelo de defensa en profundidad

```text
cuenta AWS con MFA y presupuesto
        ↓
Security Group: sólo SSH desde una IP /32
        ↓
Ubuntu actualizado + UFW + AppArmor
        ↓
OpenSSH con claves y sin acceso root
        ↓
Docker: loopback, redes internas, límites y secretos
        ↓
aplicación, datos, logs, respaldo y restauración probada
```

Ninguna capa sustituye a las demás:

- UFW no corrige un Security Group abierto a todo Internet.
- Un Security Group correcto no protege una contraseña versionada en Git.
- Un contenedor no convierte automáticamente una aplicación en segura.
- Un archivo de respaldo no sirve si nunca se verificó ni restauró.
- Un presupuesto avisa; no necesariamente detiene recursos.

## 12.2 Inventario antes de cambiar

Ejecuta primero consultas de sólo lectura:

```bash
printf '%s\n' '--- identidad ---'
id
sudo -l

printf '%s\n' '--- sistema ---'
uname -r
apt list --upgradable 2>/dev/null

printf '%s\n' '--- servicios activos ---'
systemctl --type=service --state=running --no-pager

printf '%s\n' '--- sockets ---'
sudo ss -lntup

printf '%s\n' '--- contenedores ---'
sudo docker compose -f proyecto-compose/compose.yaml ps
```

No necesitas entender todas las líneas todavía. Busca excepciones:

- un servicio que no reconoces;
- un socket en `0.0.0.0` o `[::]` que no necesitas;
- un paquete actualizable relacionado con seguridad;
- un contenedor reiniciando o no saludable.

### Escuchar no es lo mismo que estar expuesto

```text
proceso escucha → firewall del host permite → Security Group permite → ruta de red alcanza
```

Para que un cliente externo llegue, toda la cadena debe permitirlo. Aun así, el objetivo es reducir exposición en cada capa y no depender de un único filtro.

## 12.3 Actualizaciones con criterio

Actualiza el índice y observa el cambio propuesto:

```bash
sudo apt update
apt list --upgradable
```

La mejor ventana del curso es **antes** del primer despliegue. Si ya llegaste a
este capítulo con el stack activo, no actualices Docker por debajo de los
contenedores. Crea primero un respaldo verificable y realiza una parada no
destructiva:

```bash
bash scripts/respaldo-proyecto.sh
bash scripts/limpiar-proyecto.sh
sudo apt upgrade
```

El limpiador conserva volúmenes y secretos; el respaldo protege además contra
una actualización fallida. Lee el resumen de APT y confirma de forma
interactiva. Después comprueba si el sistema recomienda reiniciar:

```bash
if [[ -f /var/run/reboot-required ]]; then
  cat /var/run/reboot-required
else
  echo "No se solicita reinicio"
fi
```

No reinicies en medio de la clase si aún no guardaste evidencia ni confirmaste
cómo recuperar la IPv4. Si no se requiere reinicio, vuelve a levantar y probar:

```bash
bash scripts/preparar-proyecto.sh
curl --fail http://127.0.0.1:8080/healthz
```

Si se requiere reinicio, registra la IP actual, termina la ventana, reinicia,
obtén la nueva IP, corrige la regla `/32` si cambió y entonces ejecuta esas dos
comprobaciones. En producción se prueban parches, se programa una ventana y se
verifica el servicio después.

## 12.4 Usuarios, sudo y permisos mínimos

### Consultar identidades desde la fuente configurada

```bash
getent passwd ubuntu
getent passwd deploy
getent group ops
```

Si `deploy` o `ops` no aparecen, regresa a la práctica de usuarios; no recrees cuentas con opciones improvisadas.

### Revisar sudo

```bash
sudo -l -U ubuntu
sudo -l -U deploy
```

`sudo -l` lista lo que una identidad puede ejecutar con privilegios. El usuario de despliegue no necesita administración total sólo por operar archivos de una aplicación.

No edites `/etc/sudoers` con un editor común. Si un laboratorio requiere una regla, crea un archivo en `/etc/sudoers.d/` mediante `visudo` y valida antes de cerrar la sesión:

```bash
sudo visudo -c
```

La salida esperada termina en `parsed OK`.

### Auditar secretos sin revelarlos

```bash
find proyecto-compose/secrets -maxdepth 1 -type f \
  -printf '%m %u:%g %p\n'
git check-ignore proyecto-compose/secrets/*.txt
```

Resultado esperado: modo `600`, propietario del alumno y ambas rutas ignoradas. La confidencialidad se comprueba con metadatos; no es necesario imprimir la contraseña.

## 12.5 Security Group y UFW

### Límite externo en AWS

En la consola de EC2, el Security Group del curso debe tener una única regla de entrada:

| Tipo | Protocolo | Puerto | Origen |
|---|---|---:|---|
| SSH | TCP | 22 | IPv4 pública actual del alumno `/32` |

`0.0.0.0/0` significa cualquier IPv4 y **no** es válido para SSH en este curso. No agregues reglas 80, 443, 8080 ni 3306.

### Límite local con UFW

Comprueba que el perfil SSH existe antes de cambiar el firewall:

```bash
sudo ufw app info OpenSSH
sudo ufw status verbose
```

Secuencia segura y copiable:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status verbose
```

- `default deny incoming`: rechaza entradas que no tengan regla.
- `default allow outgoing`: permite que el host consulte repositorios, DNS e imágenes.
- `allow OpenSSH`: permite el perfil del puerto SSH **antes** de activar UFW.
- `enable`: activa las reglas y puede cambiar conectividad; por eso se prepara primero SSH.

Salida representativa:

```text
Status: active
Default: deny (incoming), allow (outgoing), disabled (routed)
22/tcp (OpenSSH)          ALLOW IN    Anywhere
```

La salida puede incluir una regla IPv6 equivalente.

### UFW, iptables y nftables

Son capas relacionadas, no tres firewalls que debas configurar por separado:

```text
reglas declaradas con UFW
          ↓
compatibilidad de iptables
          ↓
motor nftables del kernel moderno
```

En Ubuntu 24.04, `iptables` suele operar mediante el backend nftables. Puedes observarlo sin cambiar reglas:

```bash
sudo iptables --version
sudo iptables -S
if command -v nft > /dev/null; then
  sudo nft list ruleset
fi
```

- `iptables -S`: imprime reglas con sintaxis parecida a comandos.
- `nft list ruleset`: muestra el conjunto efectivo de nftables.
- La salida puede ser extensa porque UFW y Docker generan cadenas propias.

Para este laboratorio, declara la política del host con UFW y usa las consultas anteriores sólo para diagnóstico. Agregar reglas manuales con `iptables` o `nft` puede duplicar, contradecir o desaparecer frente a la administración de otras herramientas.

### Docker y UFW

Docker administra reglas de red propias; un puerto publicado en todas las interfaces puede no comportarse como alguien espera al leer sólo UFW. Por ello el proyecto no depende de UFW para ocultar la aplicación: liga Nginx a loopback.

```bash
sudo docker compose -f proyecto-compose/compose.yaml port proxy 80
sudo ss -lnt '( sport = :8080 )'
```

Ambos deben mostrar `127.0.0.1:8080`, nunca `0.0.0.0:8080` ni `[::]:8080`.

### Reversión de UFW

Si el instructor indica volver al estado inicial, hazlo desde una conexión que ya comprobaste:

```bash
sudo ufw disable
```

No uses `ufw reset` como atajo: borra reglas que quizá no pertenecen al curso.

## 12.6 Hardening seguro de OpenSSH

### Paso 1. Confirmar acceso por clave

En tu computadora conserva la sesión actual y abre otra:

```bash
ssh -i <ruta_clave.pem> ubuntu@<ipv4_ec2>
```

No continúes si la segunda conexión no funciona.

### Paso 2. Inspeccionar configuración efectiva

En EC2:

```bash
sudo sshd -T | grep -E \
  '^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin|x11forwarding|allowtcpforwarding|maxauthtries) '
```

`sshd -T` presenta la configuración efectiva. Es más fiable que buscar una línea aislada, porque OpenSSH combina el archivo principal y sus fragmentos.

### Paso 3. Crear un fragmento identificable

Crearemos `/etc/ssh/sshd_config.d/10-consultor-linux.conf`. El prefijo permite encontrar y revertir únicamente los cambios del curso.

```bash
ARCHIVO_SSH="/etc/ssh/sshd_config.d/10-consultor-linux.conf"
TEMPORAL="$(mktemp)"

cat > "$TEMPORAL" <<'EOF'
# Hardening del laboratorio Consultor Linux
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
MaxAuthTries 3
X11Forwarding no
AllowTcpForwarding local
EOF

sudo install -o root -g root -m 600 "$TEMPORAL" "$ARCHIVO_SSH"
rm -f "$TEMPORAL"
```

- `PasswordAuthentication no`: no acepta contraseña SSH.
- `KbdInteractiveAuthentication no`: desactiva autenticación interactiva basada en teclado.
- `PermitRootLogin no`: impide iniciar directamente como `root`.
- `MaxAuthTries 3`: limita intentos por conexión.
- `X11Forwarding no`: no necesitamos aplicaciones gráficas remotas.
- `AllowTcpForwarding local`: conserva el túnel local hacia Nginx, pero no habilita reenvíos remotos.

### Paso 4. Validar antes de recargar

```bash
if sudo sshd -t; then
  echo "Sintaxis SSH válida"
  sudo systemctl reload ssh
else
  echo "Configuración inválida; se retira el fragmento"
  sudo rm -f /etc/ssh/sshd_config.d/10-consultor-linux.conf
fi
```

`sshd -t` no imprime nada cuando la sintaxis es válida. `reload` conserva el proceso sin un reinicio completo.

### Paso 5. Comprobar el resultado

```bash
sudo sshd -T | grep -E \
  '^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin|x11forwarding|allowtcpforwarding|maxauthtries) '
systemctl is-active ssh
sudo journalctl -u ssh --since '-10 minutes' --no-pager
```

Luego abre una **tercera** conexión con clave desde tu computadora. Sólo después de comprobarla puedes cerrar la sesión anterior.

### Reversión del fragmento

```bash
sudo rm -f /etc/ssh/sshd_config.d/10-consultor-linux.conf
sudo sshd -t && sudo systemctl reload ssh
```

Esto retira exclusivamente la política del curso y vuelve a la configuración de la imagen de Ubuntu.

## 12.7 AppArmor y aislamiento

AppArmor limita operaciones de programas mediante perfiles cargados por el kernel.

```bash
systemctl is-active apparmor
sudo aa-status
```

Salida representativa:

```text
active
apparmor module is loaded.
... profiles are loaded.
... profiles are in enforce mode.
```

Estados principales:

- `enforce`: aplica la política y registra denegaciones;
- `complain`: registra, pero no bloquea;
- `unconfined`: el proceso no está limitado por un perfil de AppArmor.

En este curso inspeccionamos AppArmor, pero no diseñamos un perfil en vivo. Un perfil incorrecto puede interrumpir SSH, Docker o el servicio web. Para diagnosticar denegaciones:

```bash
sudo journalctl -k --since '-30 minutes' --no-pager \
  | grep -i apparmor || true
```

## 12.8 Reducir superficie y observar eventos

### Servicios habilitados

```bash
systemctl list-unit-files --type=service --state=enabled --no-pager
```

Antes de deshabilitar algo responde:

1. ¿quién depende del servicio?;
2. ¿es parte de la imagen de AWS?;
3. ¿cómo se recuperará el acceso si falla?;
4. ¿qué evidencia demostrará que el cambio funcionó?

El curso no propone una lista ciega de servicios para borrar.

### Eventos relevantes

```bash
sudo journalctl -p warning --since today --no-pager
sudo journalctl -u ssh --since today --no-pager
sudo docker compose -f proyecto-compose/compose.yaml logs \
  --tail 30 --timestamps proxy wordpress db
```

- `-p warning`: prioridad warning y más grave.
- `--since today`: limita el intervalo.
- Los logs son evidencia, no una explicación automática; correlaciona hora, servicio y acción.

### Recursos del Free Tier

```bash
free -m
df -h /
sudo docker stats --no-stream
sudo docker system df
```

En `t3.micro`, detén el proyecto si quedan menos de 100 MiB disponibles de forma sostenida, existe un `OOMKilled` o el disco supera 70 %.

```bash
for ID in $(sudo docker compose -f proyecto-compose/compose.yaml ps -q); do
  sudo docker inspect --format \
    '{{.Name}} OOMKilled={{.State.OOMKilled}} RestartCount={{.RestartCount}}' "$ID"
done
```

Todos deben mostrar `OOMKilled=false`.

## 12.9 Respaldos como control de seguridad

La disponibilidad exige poder recuperar los datos. El script del curso:

- obtiene un dump consistente de MariaDB;
- respalda los archivos persistentes de WordPress;
- crea un archivo comprimido con marca de tiempo;
- genera un SHA-256 al lado;
- no copia las contraseñas dentro del respaldo.

Ejecuta desde la raíz del repositorio:

```bash
bash scripts/respaldo-proyecto.sh
```

Salida representativa:

```text
Respaldo creado:
  /home/ubuntu/linux-desde-cero/backups/consultor-linux-20260725T123000Z.tar.gz
Checksum:
  /home/ubuntu/linux-desde-cero/backups/consultor-linux-20260725T123000Z.tar.gz.sha256
```

Localiza el más reciente sin asumir la fecha:

```bash
RESPALDO="$(find backups -maxdepth 1 -type f \
  -name 'consultor-linux-*.tar.gz' -printf '%T@ %p\n' \
  | sort -nr | head -n 1 | cut -d' ' -f2-)"
printf 'Respaldo seleccionado: %s\n' "$RESPALDO"
(cd "$(dirname "$RESPALDO")" \
  && sha256sum --check "$(basename "$RESPALDO").sha256")
tar -tzf "$RESPALDO" | sed -n '1,20p'
```

- `-printf '%T@ %p\n'`: fecha de modificación numérica y ruta.
- `sort -nr`: más reciente primero.
- `sha256sum --check`: compara el archivo con su checksum.
- `tar -tzf`: lista sin extraer.

`OK` demuestra integridad desde que se generó el checksum; todavía falta la prueba de restauración del capítulo 13.

## 12.10 Fallo controlado: un secreto queda demasiado abierto

Guarda el modo original y provoca una configuración insegura sobre **un archivo de laboratorio**, no sobre una clave real:

```bash
SECRETO="proyecto-compose/secrets/db_password.txt"
MODO_ORIGINAL="$(stat -c '%a' "$SECRETO")"
printf 'Modo inicial: %s\n' "$MODO_ORIGINAL"
chmod 644 "$SECRETO"
stat -c '%a %U:%G %n' "$SECRETO"
```

Detecta el problema:

```bash
if find "$SECRETO" -perm /077 -print | grep -q .; then
  echo "FALLO: grupo u otros tienen permisos sobre el secreto"
fi
```

`/077` busca cualquiera de los bits de lectura, escritura o ejecución para grupo u otros.

Corrige y comprueba:

```bash
chmod 600 "$SECRETO"
test "$(stat -c '%a' "$SECRETO")" = "600" \
  && echo "Permisos corregidos"
```

No dejes el modo en `644`, aunque ése haya sido el valor guardado en una ejecución anterior incorrecta.

## 12.11 Práctica resuelta: informe de hardening sin secretos

Crea una fotografía auditable:

```bash
mkdir -p /srv/consultor-linux/evidencias
INFORME="/srv/consultor-linux/evidencias/hardening.txt"

{
  echo '# Informe de hardening'
  date --iso-8601=seconds
  echo
  echo '## Identidad'
  id
  echo
  echo '## SSH efectivo'
  sudo sshd -T | grep -E \
    '^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin|x11forwarding|allowtcpforwarding|maxauthtries) '
  echo
  echo '## UFW'
  sudo ufw status verbose
  echo
  echo '## Sockets TCP'
  sudo ss -lntp
  echo
  echo '## Publicación Compose'
  sudo docker compose -f proyecto-compose/compose.yaml port proxy 80
  echo
  echo '## Secretos: sólo metadatos'
  find proyecto-compose/secrets -maxdepth 1 -type f \
    -printf '%m %u:%g %p\n'
  echo
  echo '## AppArmor'
  systemctl is-active apparmor
  echo
  echo '## Recursos'
  free -h
  df -h /
} | tee "$INFORME"

test -s "$INFORME" && echo "Informe creado: $INFORME"
```

Revisa manualmente que el informe no contenga contraseñas, claves privadas ni tokens.

## 12.12 Errores frecuentes

- **Activar UFW antes de permitir OpenSSH.** Puede cortar la conexión.
- **Cerrar la única sesión después de tocar `sshd`.** Conserva una y prueba otra.
- **Reiniciar SSH sin `sshd -t`.** Una sintaxis inválida puede bloquear nuevos accesos.
- **Conceder `NOPASSWD: ALL` a `deploy`.** Elimina la separación que intentabas crear.
- **Considerar el grupo `docker` como un permiso menor.** Permite control casi total del host.
- **Confiar únicamente en UFW para puertos Docker.** Liga explícitamente a loopback.
- **Imprimir secretos en una evidencia.** Registra rutas, propietario y modo, no contenido.
- **Desactivar AppArmor ante el primer error.** Investiga la denegación y el perfil.
- **Confundir checksum con respaldo recuperable.** También hay que restaurar.
- **Creer que `Stopped` elimina costos.** El volumen EBS continúa existiendo hasta terminar la instancia.

## 12.13 Reto: auditoría con resultado aprobado o rechazado

Crea `/srv/consultor-linux/evidencias/auditoria-seguridad.txt`. Cada control debe terminar en `OK` o `FALLO`:

1. SSH por contraseña desactivado;
2. inicio SSH directo de `root` desactivado;
3. UFW activo con OpenSSH permitido;
4. Nginx de Compose ligado a `127.0.0.1:8080`;
5. MariaDB sin puerto publicado;
6. secretos en modo `600` e ignorados por Git;
7. AppArmor activo;
8. ningún contenedor con `OOMKilled=true`;
9. checksum del respaldo más reciente válido.

No corrijas silenciosamente un control durante la auditoría: primero registra `FALLO`, aplica la corrección de forma separada y vuelve a generar el informe.

### Pistas

- Los comandos dentro de `if` pueden decidir entre `OK` y `FALLO` mediante su código de salida.
- `sshd -T` muestra valores efectivos en minúsculas.
- Usa `sudo docker compose -f proyecto-compose/compose.yaml port db 3306` para el control de MariaDB. Un estado distinto de cero es el resultado esperado.
- No deduzcas ese control con `ss`: el host podría tener otro proceso, ajeno a Compose, escuchando en 3306.
- Usa `find ... -perm /077` para localizar permisos excesivos sin leer el archivo.

### Criterios de éxito

- Existen exactamente nueve controles identificables.
- Todos terminan en `OK` en la entrega final.
- No aparece el contenido de ningún secreto.
- El archivo incluye fecha, hostname y usuario que ejecutó la revisión.
- El stack continúa respondiendo por el túnel SSH.

[Ver respuesta](instructor/soluciones.md#respuesta-reto-12)

## Resumen y checklist

- [ ] Identifiqué activos, entradas y riesgos antes de cambiar configuración.
- [ ] Revisé actualizaciones, servicios, sockets y usuarios.
- [ ] Security Group permite sólo SSH desde mi `/32`.
- [ ] Activé UFW después de permitir OpenSSH.
- [ ] Validé OpenSSH antes de recargar y probé otra conexión.
- [ ] Conservé el túnel local con `AllowTcpForwarding local`.
- [ ] Confirmé `127.0.0.1:8080` y ninguna publicación de MariaDB.
- [ ] Audité secretos sin imprimirlos.
- [ ] Inspeccioné AppArmor y logs.
- [ ] Generé y validé un respaldo.
- [ ] Sé que aún debo demostrar la restauración.
