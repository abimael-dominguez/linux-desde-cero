#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
cd "$repo_dir"

errors=0

ok() { printf 'OK    %s\n' "$*"; }
fail() { printf 'ERROR %s\n' "$*" >&2; errors=$((errors + 1)); }

chapters=(
  01-introduccion-entorno-linux.md
  02-instalacion-configuracion-inicial.md
  03-comandos-gestion-archivos.md
  04-permisos-usuarios-grupos.md
  05-procesos-gestion-sistema.md
  06-redes-conectividad.md
  07-shell-automatizacion-basica.md
  08-bash-cron.md
  09-almacenamiento-respaldos.md
  10-servidores-servicios.md
  11-virtualizacion-contenedores.md
  12-seguridad-linux.md
  13-proyecto-final.md
)

actual_chapter_count=$(find . -maxdepth 1 -type f \
  -regextype posix-extended -regex './[0-9]{2}-.*\.md' | wc -l)
if [[ $actual_chapter_count -eq 13 ]]; then
  ok 'Existen exactamente 13 capítulos.'
else
  fail "Se encontraron $actual_chapter_count capítulos numerados; se esperaban 13."
fi

for index in "${!chapters[@]}"; do
  number=$((index + 1))
  chapter=${chapters[$index]}
  [[ -f $chapter ]] || { fail "Falta $chapter."; continue; }

  challenge_count=$(grep -Ec '^## .*Reto' "$chapter" || true)
  answer_link_count=$(grep -Fc \
    "[Ver respuesta](instructor/soluciones.md#respuesta-reto-$number)" \
    "$chapter" || true)
  [[ $challenge_count -eq 1 ]] \
    || fail "$chapter tiene $challenge_count encabezados de reto."
  [[ $answer_link_count -eq 1 ]] \
    || fail "$chapter no tiene exactamente un enlace al reto $number."

  anchor_count=$(grep -Fc "<a id=\"respuesta-reto-$number\"></a>" \
    instructor/soluciones.md || true)
  [[ $anchor_count -eq 1 ]] \
    || fail "La solución del reto $number tiene $anchor_count anclas."
done
(( errors > 0 )) || ok 'Los 13 retos enlazan una solución única.'

mapfile -t mapped_pdf_sections < <(
  awk -F'|' '/^\| [0-9]+\.[0-9]+ / {
    gsub(/[[:space:]]/, "", $2)
    print $2
  }' instructor/plan-curso-consultor-linux-2026.md
)

expected_pdf_sections=()
for module in 1 2 4 5 6 9 10 11 12 13; do
  for section in 1 2 3 4; do
    expected_pdf_sections+=("$module.$section")
  done
done
for section in 1 2 3 4 5; do
  expected_pdf_sections+=("3.$section" "7.$section")
done
for section in 1 2 3; do
  expected_pdf_sections+=("8.$section")
done

if diff --brief \
  <(printf '%s\n' "${expected_pdf_sections[@]}" | sort --version-sort) \
  <(printf '%s\n' "${mapped_pdf_sections[@]}" | sort --version-sort) \
  >/dev/null; then
  ok 'Los 53 apartados del PDF están mapeados una vez.'
else
  fail 'La matriz del plan no coincide con los 53 apartados del PDF.'
fi

mapfile -t markdown_files < <(
  find . -path ./.git -prune -o -type f -name '*.md' -print | sort
)

for markdown_file in "${markdown_files[@]}"; do
  fence_count=$(grep -c '^```' "$markdown_file" || true)
  (( fence_count % 2 == 0 )) \
    || fail "$markdown_file tiene $fence_count fences Markdown."

  while IFS= read -r destination; do
    case $destination in
      ''|'#'*|http://*|https://*|mailto:*) continue ;;
    esac
    target=${destination%%#*}
    target=${target#<}
    target=${target%>}
    resolved=$(realpath --canonicalize-missing \
      "$(dirname -- "$markdown_file")/$target")
    [[ -e $resolved ]] || fail "$markdown_file enlaza una ruta inexistente: $destination"
  done < <(
    grep -oE '\]\([^)]+\)' "$markdown_file" 2>/dev/null \
      | sed -E 's/^\]\(//; s/\)$//' || true
  )
done
(( errors > 0 )) || ok 'Fences balanceados y rutas Markdown existentes.'

mapfile -t shell_files < <(
  find scripts proyecto-compose -type f -name '*.sh' -print | sort
)
for shell_file in "${shell_files[@]}"; do
  bash -n "$shell_file" || fail "bash -n falló para $shell_file."
done
(( errors > 0 )) || ok 'bash -n pasó en todos los scripts.'

if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck "${shell_files[@]}"; then
    ok 'ShellCheck pasó en todos los scripts.'
  else
    fail 'ShellCheck encontró problemas.'
  fi
else
  printf 'AVISO ShellCheck no está instalado; bash -n sí se ejecutó.\n'
fi

if command -v docker >/dev/null 2>&1; then
  if docker compose --project-directory proyecto-compose \
    --file proyecto-compose/compose.yaml config --quiet; then
    ok 'Docker Compose aceptó la configuración.'
  else
    fail 'Docker Compose rechazó la configuración.'
  fi
fi

for image in \
  'nginx:1.28.3-alpine' \
  'wordpress:7.0.0-php8.3-apache' \
  'mariadb:11.8.8-noble'; do
  grep -Fq "image: $image" proyecto-compose/compose.yaml \
    || fail "Falta la imagen fijada $image."
done
if grep -Eq 'image:[[:space:]]*[^#]*:latest([[:space:]]|$)' \
  proyecto-compose/compose.yaml; then
  fail 'Compose contiene una imagen latest.'
else
  ok 'Las tres imágenes están fijadas y no se usa latest.'
fi

if git ls-files --error-unmatch \
  proyecto-compose/secrets/db_password.txt >/dev/null 2>&1; then
  fail 'Hay un secreto rastreado por Git.'
else
  ok 'Los secretos de Compose no están rastreados.'
fi

if rg -l 'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY' . \
  --glob '!.git/**' --glob '!laboratorio/**' --glob '!backups/**' \
  >/dev/null; then
  fail 'Se encontró contenido con forma de clave privada.'
else
  ok 'No se detectaron claves privadas en el material.'
fi

if (( errors != 0 )); then
  printf '\nValidación terminada con %d error(es).\n' "$errors" >&2
  exit 1
fi

printf '\nValidación estática terminada sin errores.\n'
