# Prerrequisitos — AWS Free Tier y Ubuntu 24.04

Completa esta guía antes de la primera clase. El curso utiliza una sola EC2; no requiere RDS, balanceadores, Route 53, NAT Gateway, Elastic IP ni discos adicionales.

> **Condición importante:** AWS gratuito significa **cuenta elegible y límites vigentes**. Una cuenta antigua cuyo beneficio terminó puede generar cargos. En ese caso usa el [fallback con VirtualBox](extras/virtualbox-fallback.md).

## Resultado esperado

Antes de clase debes poder:

- entrar a una EC2 Ubuntu 24.04 mediante SSH;
- confirmar el tipo de instancia y los recursos disponibles;
- clonar este repositorio;
- ejecutar `scripts/verificar-entorno.sh` sin errores;
- detener la instancia y encontrarla nuevamente en la consola.

## 1. Identifica tu modalidad Free Tier

AWS distingue las cuentas creadas antes y después del 15 de julio de 2025.

| Cuenta | Perfil del curso | Condición |
|---|---|---|
| Nueva, con **Free account plan** activo | `t3.small`, 2 GiB | Al menos USD 10 en créditos y 30 días de vigencia |
| Free Tier anterior todavía vigente | `t3.micro`, 1 GiB + swap | Debe seguir dentro de sus primeros 12 meses |
| Sin beneficio activo | VirtualBox | No crear EC2 esperando que sea gratuita |

Los USD 10 y 30 días son un **gate conservador del curso**, no un requisito de
elegibilidad definido por AWS. Dejan margen para cuatro clases y posibles
retrasos de limpieza; si no lo cumples, usa VirtualBox aunque la consola aún
muestre algún crédito.

Las cuentas nuevas reciben créditos y el Free account plan termina a los seis meses o al agotar esos créditos. Consulta siempre el panel **Billing and Cost Management**, no una captura antigua del curso.

Fuentes: [planes actuales de AWS Free Tier](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-plans.html) y [tipos EC2 elegibles](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html).

### Comprobación obligatoria

En la consola de AWS:

1. Abre **Billing and Cost Management**.
2. Confirma el tipo de plan, saldo y fecha de expiración.
3. Activa las alertas de Free Tier.
4. Crea un presupuesto de USD 5 para el curso.
5. Configura avisos al 50 %, 80 % y 100 %.
6. Excluye los créditos en el cálculo del presupuesto si quieres observar el consumo bruto.

Un presupuesto **avisa**, pero no detiene recursos inmediatamente. AWS puede tardar varias horas en actualizar sus datos.

Referencias para revisar antes de cada grupo:

- [seguimiento de uso de AWS Free Tier](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/tracking-free-tier-usage.html);
- [precios de EBS](https://aws.amazon.com/ebs/pricing/), porque el volumen sigue
  existiendo mientras la EC2 está detenida;
- [créditos CPU T3 y modo Unlimited](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-unlimited-mode-concepts.html),
  que explica cuándo los créditos excedentes pueden generar cargos.

## 2. Protege la cuenta

- Activa MFA para el usuario raíz.
- No guardes Access Keys en la EC2 ni en este repositorio.
- No conviertas el Free account plan a Paid durante el curso.
- No unas la cuenta a AWS Organizations o Control Tower.
- Conserva la clave privada SSH únicamente en tu computadora.

## 3. Crea la instancia

En **EC2 → Instances → Launch instance** utiliza estos valores:

| Campo | Valor del curso | Por qué |
|---|---|---|
| Nombre | `consultor-linux` | Identificación y limpieza |
| Región | `us-east-1` | Entorno común para el grupo |
| AMI | Ubuntu Server 24.04 LTS x86-64 | Referencia del curso |
| Tipo recomendado | `t3.small` | 2 GiB para Docker |
| Compatibilidad | `t3.micro` | Requiere 2 GiB de swap |
| Volumen raíz | 20 GiB `gp3`, cifrado | Sistema, imágenes y laboratorios |
| IP pública | Automática | Cambiará al detener/iniciar |
| Créditos T3 | `standard` | Evita CPU excedente facturable |
| Shutdown behavior | `Stop` | `shutdown` debe detener, no terminar |

La AMI y el tipo deben mostrar la marca **Free tier eligible** correspondiente a tu plan. No selecciones una AMI de Marketplace.

La IPv4 pública automática no equivale por sí sola a “sin costo”. AWS publica
un precio de USD 0.005 por hora cuando la dirección no queda cubierta por Free
Tier o créditos; 30 horas representarían aproximadamente USD 0.15 antes de esa
cobertura. Al detener la EC2 se libera esa dirección y al iniciar recibirás
otra. No reserves una Elastic IP. Verifica la tarifa vigente en
[Amazon VPC Pricing](https://aws.amazon.com/vpc/pricing/).

### Etiquetas

Agrega:

| Clave | Valor de ejemplo |
|---|---|
| `Course` | `consultor-linux` |
| `Owner` | `tu-nombre` |
| `DeleteAfter` | fecha del último día del curso |

`<fecha>` o `tu-nombre` son marcadores explicativos; escribe tus valores reales en la consola.

## 4. Clave y Security Group

Crea un par de claves tipo ED25519 o RSA y descarga el `.pem` una sola vez.

El Security Group tendrá una única regla entrante:

| Tipo | Puerto | Origen |
|---|---:|---|
| SSH | 22/TCP | **My IP**, una dirección `/32` |

No uses `0.0.0.0/0`. Tampoco abras 80, 443 o 3306: WordPress se consultará mediante un túnel SSH.

Confirma que el volumen raíz tiene activada la eliminación al terminar la instancia (`DeleteOnTermination=true`).

## 5. Protege la clave local

En Linux, macOS o WSL, primero identifica el nombre descargado:

```bash
ls -l ~/Downloads/*.pem
```

Sintaxis general:

```bash
mkdir -p ~/.ssh
mv <clave_descargada> ~/.ssh/<nombre_clave>
chmod 400 ~/.ssh/<nombre_clave>
```

Ejemplo copiable cuando la descarga se llama `consultor-linux.pem`:

```bash
mkdir -p ~/.ssh
mv ~/Downloads/consultor-linux.pem ~/.ssh/consultor-linux.pem
chmod 400 ~/.ssh/consultor-linux.pem
```

- `chmod 400` permite lectura únicamente al propietario.
- `~/.ssh/consultor-linux.pem` es la ruta concreta que usará el curso.
- Si tu archivo tiene otro nombre, adapta el ejemplo; no escribas `<nombre_clave>` literalmente.

En PowerShell puedes conservar la clave en `$HOME\Downloads`; no publiques esa ruta ni su contenido.

## 6. Conexión SSH

Necesitas tres valores:

| Dato | Valor del ejemplo | Tu valor |
|---|---|---|
| Usuario remoto | `ubuntu` | `ubuntu` |
| Clave | `~/.ssh/consultor-linux.pem` | ruta de tu `.pem` |
| IP pública | `203.0.113.10` | dirección de la consola EC2 |

`203.0.113.10` es una IP reservada para documentación; **no responderá**.

Sintaxis general:

```bash
ssh -i <ruta_clave> <usuario>@<IP_PUBLICA>
```

Ejemplo parametrizado; sustituye únicamente la IP:

```bash
CLAVE="$HOME/.ssh/consultor-linux.pem"
USUARIO_REMOTO="ubuntu"
EC2_HOST="203.0.113.10"  # Sustituye por la IP pública real

ssh -i "$CLAVE" "${USUARIO_REMOTO}@${EC2_HOST}"
```

La primera conexión muestra una huella. Comprueba que la IP coincide con la consola antes de responder `yes`.

### Windows PowerShell

```powershell
$Key = "$HOME\Downloads\consultor-linux.pem"
$HostIp = "203.0.113.10" # Sustituye por la IP pública real
ssh -i $Key "ubuntu@$HostIp"
```

## 7. Prepara Ubuntu

Ya dentro de EC2:

```bash
whoami
cat /etc/os-release
uname -m
free -h
df -h /
```

Salida representativa:

```text
ubuntu
PRETTY_NAME="Ubuntu 24.04.x LTS"
x86_64
```

Los tamaños, kernel, hostname e IP pueden cambiar.

Clona el repositorio y ejecuta la preparación:

```bash
git clone <URL_DEL_REPOSITORIO> linux-desde-cero
cd linux-desde-cero
bash scripts/bootstrap-ubuntu.sh
bash scripts/verificar-entorno.sh
```

`<URL_DEL_REPOSITORIO>` debe sustituirse por la URL entregada por el instructor. El bootstrap instala únicamente las herramientas del curso; no ejecuta una actualización completa del sistema ni abre puertos.

### Sólo para `t3.micro`

```bash
sudo bash scripts/configurar-swap.sh 2
bash scripts/verificar-entorno.sh
```

El `2` significa 2 GiB. El script crea `/swapfile-consultor-linux`, ajusta `vm.swappiness=10` y valida el resultado.

## 8. Apagado de seguridad

Al comenzar cada clase:

```bash
bash scripts/programar-apagado.sh 360
```

- `360` son seis horas.
- Para cancelar: `sudo shutdown -c`.
- La consola debe indicar que el comportamiento iniciado por el sistema es **Stop**.

Al terminar:

```bash
sudo shutdown -h now
```

Después confirma en la consola que el estado sea `Stopped`. Detener elimina el costo de cómputo, pero el EBS continúa existiendo. Al iniciar de nuevo probablemente recibirás otra IP pública; actualiza `EC2_HOST`.

## 9. Túnel del proyecto web

Durante la cuarta sesión, desde tu computadora local:

```bash
ssh -i "$CLAVE" \
  -L 8080:127.0.0.1:8080 \
  "${USUARIO_REMOTO}@${EC2_HOST}"
```

Mientras esa sesión permanezca abierta visita `http://127.0.0.1:8080`. El puerto 8080 pertenece a tu computadora; Nginx no queda expuesto públicamente.

## 10. Limpieza final de AWS

No basta con apagar la instancia. Después de descargar el respaldo final:

1. Termina `consultor-linux`.
2. Confirma que el volumen raíz fue eliminado.
3. Revisa que no existan snapshots ni Elastic IP.
4. Elimina el Security Group del curso.
5. Elimina el Key Pair de AWS; conserva o destruye localmente el `.pem` según tu política.
6. Revisa EC2 Global View y Billing al día siguiente.

## Problemas frecuentes

| Síntoma | Revisión |
|---|---|
| `Permission denied (publickey)` | Usuario `ubuntu`, clave asociada y ruta de la `.pem` |
| Timeout | IP nueva, instancia encendida y regla SSH desde tu IP actual |
| `UNPROTECTED PRIVATE KEY FILE` | Ejecuta `chmod 400` sobre la clave |
| Docker se queda sin memoria | Confirma swap y perfil mediante `verificar-entorno.sh` |
| La IP dejó de funcionar | Copia la nueva IPv4 después de iniciar EC2 |
| La cuenta no muestra Free Tier | No continúes: usa VirtualBox o revisa elegibilidad |

## Checklist

- [ ] Confirmé que mi plan Free Tier está vigente.
- [ ] Configuré MFA y alertas de presupuesto.
- [ ] Elegí una AMI Ubuntu 24.04 marcada como elegible.
- [ ] Configuré `t3.small` o el perfil `t3.micro` con swap.
- [ ] Seleccioné CPU credits `standard`.
- [ ] Dejé sólo SSH desde mi IP `/32`.
- [ ] Verifiqué 20 GiB `gp3` y `DeleteOnTermination=true`.
- [ ] Puedo conectarme como `ubuntu`.
- [ ] `scripts/verificar-entorno.sh` no reporta errores.
- [ ] Sé detener y terminar la instancia.
