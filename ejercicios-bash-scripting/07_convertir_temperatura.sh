#!/bin/bash

temp_f=$1
temp_f2=$(echo "scale=2; $temp_f - 32" | bc)
temp_c=$(echo "scale=2; $temp_f2 * 5 / 9" | bc)
echo "$temp_f F es $temp_c C"