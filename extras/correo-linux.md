# Anexo — Correo en Linux sin desplegar un servidor público

Operar correo real exige reputación IP, DNS directo e inverso, SPF, DKIM, DMARC, antispam y monitoreo. No cabe de forma responsable en un curso inicial ni debe improvisarse en Free Tier.

## Modelo mínimo

```text
MUA del usuario -> SMTP/MTA -> MTA del destinatario -> buzón -> IMAP/MUA
```

- **MUA:** cliente como Thunderbird o una aplicación web.
- **MTA:** servidor que transfiere mensajes, por ejemplo Postfix.
- **SMTP:** entrega o retransmisión.
- **IMAP:** consulta del buzón.
- **MX:** registro DNS que anuncia los servidores receptores.

## Consulta práctica

Sintaxis general:

```bash
dig +short MX <dominio>
```

Ejemplo copiable:

```bash
dig +short MX ubuntu.com
```

La prioridad y los nombres pueden cambiar. Un número menor indica mayor preferencia. Después relaciona cada nombre con sus direcciones:

```bash
getent ahosts <servidor_mx>
```

No se abrirá el puerto 25 ni se enviará correo desde EC2; AWS limita además ese tráfico en numerosos escenarios.
