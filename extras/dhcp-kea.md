# Anexo — Validar DHCP con Kea

En una VPC, AWS administra DHCP. Por eso este curso **no inicia** otro servidor DHCP: hacerlo podría interferir con la conectividad. La práctica se limita a validar una configuración ficticia.

## Preparación

```bash
bash scripts/preparar-lab.sh
sudo apt-get update
sudo apt-get install -y kea-dhcp4-server
```

## Validación

Sintaxis general:

```bash
kea-dhcp4 -t <archivo_configuracion>
```

Ejemplo copiable:

```bash
kea-dhcp4 -t laboratorio/data/dhcp/kea-dhcp4.conf
echo "$?"
```

Salida esperada:

```text
0
```

- `-t` analiza la configuración y termina: no abre UDP/67.
- `interfaces: [ "lo" ]` limita el ejemplo a loopback; no selecciona la
  interfaz real de EC2.
- `dhcp-socket-type: "udp"` permite validar explícitamente loopback.
- `subnet4` define la red ficticia `192.0.2.0/24`.
- `pools` limita las direcciones que entregaría el servidor.
- El código `0` confirma que el JSON y las opciones son válidos.

No ejecutes `kea-dhcp4` sin `-t` en EC2.
