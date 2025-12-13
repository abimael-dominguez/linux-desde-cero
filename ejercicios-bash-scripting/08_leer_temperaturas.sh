#!/bin/bash

# Lee temperaturas de archivos
temp_a=$(cat ./data/temps/region_A)
temp_b=$(cat ./data/temps/region_B)
temp_c=$(cat ./data/temps/region_C)

echo "Las temperaturas son $temp_a, $temp_b, y $temp_c"