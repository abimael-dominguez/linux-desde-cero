# #!/bin/bash

# for file in ./data/inherited_folder/*.R
# do
#     echo "$file"
# done

#!/bin/bash

# for file in ./data/robs_files/*.py
# do
#     if grep -q 'RandomForestClassifier' "$file"; then
#         mv "$file" ./data/to_keep/
#     fi
# done


#!/bin/bash

case $1 in
    Monday|Tuesday|Wednesday|Thursday|Friday)
        echo "Es un día de semana!";;
    Saturday|Sunday)
        echo "Es fin de semana!";;
    HOLA)
        echo "Saludos!";;
    ADIOS)
        echo "Hasta luego!";;
    *)
        echo "No es un día!";;
esac