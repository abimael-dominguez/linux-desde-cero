# #!/bin/bash

# declare -a capital_cities
# capital_cities+=("Sydney")
# capital_cities+=("Albany")
# capital_cities+=("Paris")
# capital_cities+=("Abimael")

# echo "Ciudades: ${capital_cities[@]}"

# echo "Número de ciudades: ${#capital_cities[@]}"

#!/bin/bash

declare -A model_metrics
model_metrics[model_accuracy]=98
model_metrics[model_name]="knn"
model_metrics[model_f1]=0.82

echo "Claves: ${!model_metrics[@]}"

echo "Valores: ${model_metrics[@]}"