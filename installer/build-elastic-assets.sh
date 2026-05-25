#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=installer/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

TARGET_DIR="${1:-/usr/share/psa-roundcube}"
PLUGINS_DIR="$TARGET_DIR/plugins"

copy_fallback() {
  local source_file="$1"
  local target_file="$2"

  if [ -f "$target_file" ]; then
    log "Asset já existe: $target_file"
    return
  fi

  if [ ! -f "$source_file" ]; then
    warn "Fallback ausente: $source_file"
    return
  fi

  mkdir -p "$(dirname "$target_file")"
  cp "$source_file" "$target_file"
  log "Fallback copiado: $target_file"
}

compile_libkolab() {
  local less_file="$PLUGINS_DIR/libkolab/skins/elastic/libkolab.less"
  local css_file="$PLUGINS_DIR/libkolab/skins/elastic/libkolab.css"

  if [ ! -f "$less_file" ]; then
    warn "Arquivo LESS ausente: $less_file"
    return
  fi

  if have_cmd lessc; then
    if lessc --relative-urls -x "$less_file" >"$css_file"; then
      log "libkolab.css recompilado com lessc"
      return
    fi

    warn "Falha ao compilar libkolab.less; usando fallback"
  else
    warn "lessc não encontrado; usando fallback CSS"
  fi

  copy_fallback \
    "$PLUGINS_DIR/libkolab/skins/larry/libkolab.css" \
    "$css_file"
}

main() {
  [ -d "$PLUGINS_DIR" ] || die "Diretório de plugins não encontrado: $PLUGINS_DIR"

  compile_libkolab
  copy_fallback "$PLUGINS_DIR/libcalendaring/skins/larry/libcal.css" "$PLUGINS_DIR/libcalendaring/skins/elastic/libcal.css"
  copy_fallback "$PLUGINS_DIR/calendar/skins/larry/fullcalendar.css" "$PLUGINS_DIR/calendar/skins/elastic/fullcalendar.css"
  copy_fallback "$PLUGINS_DIR/calendar/skins/larry/calendar.css" "$PLUGINS_DIR/calendar/skins/elastic/calendar.css"
  copy_fallback "$PLUGINS_DIR/calendar/skins/larry/print.css" "$PLUGINS_DIR/calendar/skins/elastic/print.css"
}

main "$@"
