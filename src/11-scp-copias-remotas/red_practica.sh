#!/bin/bash
echo "== Diagnóstico de red =="
ping -c 2 8.8.8.8
echo
echo "== Interfaces de red =="
ip a
echo
echo "== Consulta DNS =="
nslookup google.com
echo
echo "== Descarga de archivo de prueba =="
wget -q --show-progress https://www.example.com/index.html -O /tmp/index.html
ls -lh /tmp/index.html
echo
echo "== (Opcional) Copia SCP (requiere SSH) =="
echo "scp /tmp/index.html usuario@host:/tmp/  # Edita usuario y host para probar"
