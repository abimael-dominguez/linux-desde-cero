#!/bin/bash

function sum_array () {
    local sum=0
    for number in "$@"
    do
        sum=$(echo "$sum + $number" | bc)
    done
    echo "$sum"
}

test_array=(1 2 3 4 5 1)
total=$(sum_array "${test_array[@]}")
echo "Suma total: $total"