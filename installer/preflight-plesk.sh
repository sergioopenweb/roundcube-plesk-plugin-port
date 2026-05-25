#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=installer/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

TARGET_DIR="/usr/share/psa-roundcube"
DB_NAME="roundcubemail"
DB_PASSWORD_FILE="/etc/psa/.psa.shadow"
CALENDAR_DRIVER="database"
INSTALL_SET="all"

usage() {
  cat <<'EOF'
Uso:
  installer/preflight-plesk.sh [opções]

Opções:
  --target-dir PATH         Diretório do Roundcube no Plesk
  --db-name NAME            Nome do banco do Roundcube
  --db-password-file PATH   Arquivo com a senha admin do Plesk
  --calendar-driver NAME    database, kolab ou caldav
  --install-set NAME        all, automatic ou calendar
  --help                    Exibe esta ajuda
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --target-dir)
        TARGET_DIR="$2"
        shift 2
        ;;
      --db-name)
        DB_NAME="$2"
        shift 2
        ;;
      --db-password-file)
        DB_PASSWORD_FILE="$2"
        shift 2
        ;;
      --calendar-driver)
        CALENDAR_DRIVER="$2"
        shift 2
        ;;
      --install-set)
        INSTALL_SET="$2"
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

check_path() {
  local path="$1"
  local label="$2"

  if [ -e "$path" ]; then
    log "$label ok: $path"
  else
    die "$label ausente: $path"
  fi
}

check_optional_cmd() {
  local cmd="$1"

  if have_cmd "$cmd"; then
    log "Comando opcional disponível: $cmd"
  else
    warn "Comando opcional ausente: $cmd"
  fi
}

check_plugin_target() {
  local plugin="$1"
  local path="$TARGET_DIR/plugins/$plugin"

  if [ -e "$path" ]; then
    warn "Plugin já existe no target e será substituído com backup: $path"
  else
    log "Plugin ainda não existe no target: $path"
  fi
}

main() {
  parse_args "$@"

  log "Usuário atual: $(id -un)"
  if is_root; then
    log "Execução como root confirmada"
  else
    warn "Você não está como root; a instalação real vai falhar sem privilégio"
  fi

  require_cmd php
  require_cmd mysql
  check_optional_cmd lessc

  log "PHP CLI: $(php -r 'echo PHP_VERSION;')"
  log "MySQL CLI: $(mysql --version | sed 's/^mysql  //')"

  check_path "$TARGET_DIR" "Diretório do Roundcube"
  check_path "$TARGET_DIR/config/config.inc.php" "Config principal do Roundcube"
  check_path "$TARGET_DIR/plugins" "Diretório de plugins"
  check_path "$DB_PASSWORD_FILE" "Arquivo de senha do Plesk"

  case "$INSTALL_SET" in
    automatic)
      check_plugin_target "automatic_addressbook"
      ;;
    calendar)
      check_plugin_target "libcalendaring"
      check_plugin_target "libkolab"
      check_plugin_target "calendar"
      ;;
    all)
      check_plugin_target "automatic_addressbook"
      check_plugin_target "libcalendaring"
      check_plugin_target "libkolab"
      check_plugin_target "calendar"
      ;;
    *)
      die "install-set inválido: $INSTALL_SET"
      ;;
  esac

  case "$CALENDAR_DRIVER" in
    database|kolab|caldav)
      log "calendar-driver selecionado: $CALENDAR_DRIVER"
      ;;
    *)
      die "calendar-driver inválido: $CALENDAR_DRIVER"
      ;;
  esac

  log "Banco alvo: $DB_NAME"
  log "Preflight concluído"
  printf '\n'
  printf 'Comando sugerido para instalar:\n'
  printf '  ./installer/install-plesk.sh --target-dir %q --db-name %q --calendar-driver %q\n' \
    "$TARGET_DIR" "$DB_NAME" "$CALENDAR_DRIVER"
}

main "$@"
