#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   ./run-sync.sh interactive
#   ./run-sync.sh non-interactive [args...]
#
# Ejemplos:
#   ./run-sync.sh interactive
#   ./run-sync.sh non-interactive --cleanup
#   ./run-sync.sh non-interactive /data/assets

MODE="${1:-interactive}"
shift || true

if [[ ! -f ".env" || ! -f "docker-compose.yaml" ]]; then
  echo "No se ejecuta nada: faltan .env y/o docker-compose.yaml en la carpeta actual."
  exit 0
fi

echo "Levantando todos los servicios ..."
docker compose up -d

if [[ "$MODE" == "interactive" ]]; then
  echo "Ejecutando sync:prod en modo interactivo..."
  docker compose exec backend npm run sync:prod -- --interactive
elif [[ "$MODE" == "non-interactive" ]]; then
  echo "Ejecutando sync:prod en modo no interactivo..."
  docker compose exec -T backend npm run sync:prod -- --no-interactive "$@"
else
  echo "Modo no valido: $MODE"
  echo "Usa: interactive | non-interactive"
  exit 1
fi
