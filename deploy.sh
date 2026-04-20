#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[INFO] $*"; }
err(){ echo "[ERROR] $*" >&2; }

require_file() { [[ -f "$1" ]] || { err "Falta $1"; exit 1; }; }

usage() {
  cat <<'EOF'
Uso:
  ./deploy.sh deploy [--with-sync] [--sync-mode interactive|non-interactive] [-- args...]
  ./deploy.sh sync [interactive|non-interactive] [args...]
EOF
}

require_prereqs() {
  require_file ".env"
  require_file "docker-compose.yaml"
  docker compose version >/dev/null 2>&1 || { err "docker compose v2 no disponible"; exit 1; }
}

run_sync() {
  local mode="${1:-non-interactive}"; shift || true
  log "Levantando dependencias mínimas (redis)..."
  docker compose up -d redis

  if [[ "$mode" == "interactive" ]]; then
    log "Sync interactivo..."
    docker compose --profile manual run --rm sync --interactive "$@"
  elif [[ "$mode" == "non-interactive" ]]; then
    log "Sync no interactivo..."
    docker compose --profile manual run --rm sync --no-interactive "$@"
  else
    err "Modo de sync inválido: $mode"
    exit 1
  fi
}

cmd="${1:-}"; shift || true
require_prereqs

case "$cmd" in
  deploy)
    with_sync=false
    sync_mode="non-interactive"
    sync_args=()

    while (($#)); do
      case "$1" in
        --with-sync) with_sync=true; shift ;;
        --sync-mode) sync_mode="${2:-}"; shift 2 ;;
        --) shift; sync_args=("$@"); break ;;
        *) err "Opción inválida: $1"; usage; exit 1 ;;
      esac
    done

    log "Levantando dependencias (redis/frontend)..."
    docker compose up -d redis frontend

    log "Ejecutando migraciones..."
    if ! docker compose run --rm migrate; then
      err "Falló migrate. Backend NO se arranca."
      exit 1
    fi

    log "Arrancando backend..."
    docker compose up -d backend

    if [[ "$with_sync" == "true" ]]; then
      run_sync "$sync_mode" "${sync_args[@]}"
    fi

    log "Deploy completado."
    docker compose ps
    ;;
  sync)
    run_sync "${1:-non-interactive}" "${@:2}"
    ;;
  *)
    usage
    exit 1
    ;;
esac