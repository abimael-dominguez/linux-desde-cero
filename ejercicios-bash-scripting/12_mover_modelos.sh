#!/bin/bash

# Extrae precisión y mueve a carpetas
accuracy=$(grep "Accuracy" "$1" | sed 's/.* //')
if [ $accuracy -ge 90 ]; then
    mv "$1" ./data/good_models/
elif [ $accuracy -lt 90 ]; then
    mv "$1" ./data/bad_models/
fi