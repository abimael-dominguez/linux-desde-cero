# Artefactos del proyecto

Este directorio contiene el stack del proyecto final. No ejecutes `docker compose up` directamente la primera vez: desde la raíz del curso utiliza:

```bash
bash scripts/preparar-proyecto.sh
```

El script crea secretos locales, descarga imágenes versionadas y levanta primero la base de datos, después WordPress y finalmente Nginx. Sólo se publica `127.0.0.1:8080`; MariaDB no expone ningún puerto del host.

No antepongas `sudo` al script: él solicita `sudo` únicamente para comunicarse
con Docker cuando hace falta. Así, los secretos quedan propiedad del alumno y
pueden auditarse y limpiarse sin convertir todo el proyecto en archivos de
`root`.

Los archivos bajo `secrets/`, los respaldos y los volúmenes de Docker son artefactos locales y no se versionan.
