#!/bin/bash
palabras_a_buscar=$1
nombre_archivo=$2

if egrep -q "$palabras_a_buscar" "$nombre_archivo"; then
    mkdir -p ./data/moved_logs
    mv "$nombre_archivo" ./data/moved_logs/
fi