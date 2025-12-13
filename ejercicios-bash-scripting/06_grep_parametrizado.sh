#!/bin/bash

# Busca el primer argumento en todos los archivos CSV de hire_data
# grep "$1": busca el patrón en la entrada
# > "$1".csv: guarda en archivo nombrado con el argumento

cat ./data/hire_data/*.csv | grep "$1" > "./data/$1.csv"