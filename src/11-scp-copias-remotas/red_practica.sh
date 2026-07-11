#!/usr/bin/env bash
set -o nounset

host=${1:-example.com}

printf '== Interfaces ==\n'
ip -brief address
printf '\n== Ruta por defecto ==\n'
ip route show default
printf '\n== Resolución ==\n'
getent hosts "$host"
printf '\n== HTTP ==\n'
curl --fail --silent --show-error --head "https://$host" | head
printf '\n== Puertos locales en escucha ==\n'
ss -tuln
