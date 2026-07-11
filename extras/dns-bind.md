# Anexo — Validar una zona DNS con BIND

Este laboratorio valida una configuración autoritativa sin ocupar el puerto 53 de EC2 ni modificar su resolvedor.

## Preparación

Desde la raíz del curso:

```bash
bash scripts/preparar-lab.sh
if systemctl is-active --quiet named 2>/dev/null; then
  printf 'Ya existe un DNS activo; este anexo no lo sustituirá\n' >&2
  exit 1
fi
sudo apt-get update
sudo apt-get install -y bind9 bind9-utils
sudo systemctl disable --now named
```

Si `named` ya estaba activo **antes** del anexo, no lo detengas: existe otro
servicio que el laboratorio no debe sustituir. El ejemplo se realiza sólo en
la EC2 desechable del curso. Después de instalar, `named` queda deshabilitado y
la práctica iniciará otra instancia manual exclusivamente en loopback:1053.

El archivo de zona es `laboratorio/data/dns/db.curso.test`. Sus direcciones pertenecen a rangos reservados para documentación y no representan servidores reales.

## Comando parametrizado

```bash
named-checkzone <nombre_zona> <archivo_zona>
```

Ejemplo copiable:

```bash
named-checkzone curso.test laboratorio/data/dns/db.curso.test
```

Salida esperada:

```text
zone curso.test/IN: loaded serial 2026071101
OK
```

- `curso.test` es la zona que BIND debe interpretar.
- `named-checkzone` revisa sintaxis, SOA y registros; no inicia un servidor.
- El serial debe aumentar cada vez que se publique una nueva versión de la zona.

Fallo controlado: copia el archivo al laboratorio, elimina el punto final de `ns1.curso.test.` y vuelve a validar. BIND mostrará por qué los nombres absolutos terminan con punto.

## Servidor autoritativo aislado en `127.0.0.1:1053`

Prepara rutas permitidas por la instalación de BIND. `CACHE`, `CONF` y `ZONE`
son valores concretos, no marcadores:

```bash
cd "$HOME/linux-desde-cero"
CACHE=/var/cache/bind/curso-lab
CONF=/etc/bind/named.conf.curso-lab
ZONE="$CACHE/db.curso.test"
LOG="$HOME/consultor-linux-lab/bind-1053.log"

mkdir -p "$(dirname "$LOG")"
sudo install -d -o bind -g bind -m 0750 "$CACHE"
sudo install -o bind -g bind -m 0640 \
  laboratorio/data/dns/db.curso.test "$ZONE"
```

Crea una configuración que no escuche en ninguna interfaz real y que rechace
recursión, transferencias y actualizaciones:

```bash
sudo tee "$CONF" > /dev/null <<'BIND'
options {
  directory "/var/cache/bind/curso-lab";
  listen-on port 1053 { 127.0.0.1; };
  listen-on-v6 { none; };
  recursion no;
  allow-query { 127.0.0.1; };
  allow-transfer { none; };
  dnssec-validation no;
  pid-file "/var/cache/bind/curso-lab/named.pid";
};

controls {};

zone "curso.test" IN {
  type primary;
  file "db.curso.test";
  notify no;
  allow-update { none; };
};
BIND

sudo chmod 0644 "$CONF"
named-checkconf -z "$CONF"
```

- `listen-on port 1053`: evita el puerto privilegiado 53 y liga sólo loopback;
- `recursion no`: este proceso responde por su zona, no resuelve Internet;
- `controls {}`: no abre el puerto de control 953;
- `type primary`: carga la copia local de `curso.test`;
- `notify no` y `allow-update { none; }`: no envía notificaciones ni acepta
  cambios de red.

Inicia en primer plano lógico, pero como job del shell, y espera una respuesta:

```bash
sudo -u bind /usr/sbin/named -g -n 1 -c "$CONF" > "$LOG" 2>&1 &
NAMED_LAUNCHER_PID=$!

for intento in {1..20}; do
  if dig @127.0.0.1 -p 1053 web.curso.test A +short \
    | grep -qxF '192.0.2.80'; then
    break
  fi
  sleep 0.25
done

dig @127.0.0.1 -p 1053 web.curso.test A +noall +comments +answer
dig @127.0.0.1 -p 1053 example.com A +noall +comments
sudo ss -lunt '( sport = :1053 )'
```

La primera consulta contiene `192.0.2.80` y la bandera `aa` (*authoritative
answer*). La consulta externa termina `REFUSED`. `ss` debe mostrar únicamente
`127.0.0.1:1053`, en TCP y UDP; nunca `0.0.0.0:1053` ni `[::]:1053`.

## Limpieza comprobada

No mates un PID sólo porque aparece en un archivo. Valida número, comando y
configuración antes de enviar `TERM`:

```bash
PID_FILE="$CACHE/named.pid"
NAMED_PID=$(sudo cat "$PID_FILE")
[[ $NAMED_PID =~ ^[0-9]+$ ]] || {
  printf 'PID inválido; limpieza cancelada\n' >&2
  exit 1
}

ARGS=$(ps -p "$NAMED_PID" -o args=)
case "$ARGS" in
  *named.conf.curso-lab*) sudo kill -TERM "$NAMED_PID" ;;
  *) printf 'El PID no pertenece al laboratorio: %s\n' "$ARGS" >&2; exit 1 ;;
esac

wait "$NAMED_LAUNCHER_PID" 2>/dev/null || true
sudo ss -lunt '( sport = :1053 )'

EXPECTED_CACHE=/var/cache/bind/curso-lab
if [[ $CACHE == "$EXPECTED_CACHE" ]]; then
  sudo find "$CACHE" -mindepth 1 -maxdepth 1 -delete
  sudo rmdir "$CACHE"
  sudo rm -f -- "$CONF"
else
  printf 'Ruta inesperada; no se elimina: %s\n' "$CACHE" >&2
  exit 1
fi
```

La última consulta `ss` no debe mostrar sockets. El paquete puede permanecer
instalado, pero `systemctl is-enabled named` debe seguir mostrando `disabled`.
No abras 53 ni 1053 en el Security Group.
