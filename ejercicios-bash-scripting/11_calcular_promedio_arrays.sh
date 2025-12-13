#!/bin/bash

temp_b="$(cat ./data/temps/region_B)"
temp_c="$(cat ./data/temps/region_C)"
region_temps=($temp_b $temp_c)
average_temp=$(echo "scale=2; (${region_temps[0]} + ${region_temps[1]}) / 2" | bc)
region_temps+=($average_temp)
echo "Temperaturas y promedio: ${region_temps[@]}"