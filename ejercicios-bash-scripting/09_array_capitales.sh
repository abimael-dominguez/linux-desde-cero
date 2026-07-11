#!/usr/bin/env bash
set -o nounset

capitales=(Sydney Albany Paris)
printf 'Ciudades (%d):' "${#capitales[@]}"
printf ' %s' "${capitales[@]}"
printf '\n'

declare -A metricas=(
  [model_name]=knn
  [model_accuracy]=98
  [model_f1]=0.82
)
printf 'Modelo: %s\n' "${metricas[model_name]}"
printf 'Accuracy: %s\n' "${metricas[model_accuracy]}"
printf 'F1: %s\n' "${metricas[model_f1]}"
