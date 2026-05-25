#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=installer/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

TARGET_DIR="/usr/share/psa-roundcube"
MANIFEST=""

usage() {
  cat <<'EOF'
Uso:
  installer/rollback.sh [--target-dir PATH] [--manifest PATH]

Se --manifest não for informado, o script restaura o último manifesto
registrado para o target informado.
EOF
}

find_latest_manifest() {
  local state_base="$REPO_ROOT/.installer-state/$(state_key "$TARGET_DIR")/backups"

  [ -d "$state_base" ] || die "Nenhum backup encontrado para $TARGET_DIR"

  find "$state_base" -name manifest.tsv | sort | tail -n 1
}

restore_target() {
  local target="$1"
  local backup="$2"

  rm -rf "$target"

  if [ "$backup" = "__MISSING__" ]; then
    log "Removido arquivo criado pelo instalador: $target"
    return
  fi

  mkdir -p "$(dirname "$target")"
  cp -a "$backup" "$target"
  log "Restaurado: $target"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --target-dir)
        TARGET_DIR="$2"
        shift 2
        ;;
      --manifest)
        MANIFEST="$2"
        shift 2
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        die "Opção desconhecida: $1"
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  require_root

  if [ -z "$MANIFEST" ]; then
    MANIFEST="$(find_latest_manifest)"
  fi

  [ -f "$MANIFEST" ] || die "Manifesto não encontrado: $MANIFEST"

  tac "$MANIFEST" | while IFS=$'\t' read -r target backup; do
    restore_target "$target" "$backup"
  done

  log "Rollback concluído"
}

main "$@"
