#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=installer/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

TARGET_DIR="/usr/share/psa-roundcube"
DB_NAME="roundcubemail"
DB_PASSWORD_FILE="/etc/psa/.psa.shadow"
CALENDAR_DRIVER="database"
INSTALL_SET="all"
SKIP_SQL=0
SKIP_CONFIG=0
SKIP_ASSETS=0
FORCE_CONFIG=0

usage() {
  cat <<'EOF'
Uso:
  installer/install-plesk.sh [opções]

Opções:
  --target-dir PATH         Diretório do Roundcube no Plesk
  --db-name NAME            Nome do banco do Roundcube
  --db-password-file PATH   Arquivo com a senha do usuário admin do Plesk
  --calendar-driver NAME    database, kolab ou caldav
  --install-set NAME        all, automatic ou calendar
  --skip-sql                Não importa os SQL iniciais
  --skip-config             Não instala templates de configuração
  --skip-assets             Não recompila/copia assets Elastic
  --force-config            Sobrescreve config local dos plugins com os templates do monorepo
  --help                    Exibe esta ajuda
EOF
}

json_array_from_args() {
  php -r 'array_shift($argv); echo json_encode(array_values($argv));' "$@"
}

render_template_file() {
  local template="$1"
  local destination="$2"
  shift 2

  php -r '
    $content = file_get_contents($argv[1]);
    for ($i = 3; $i < $argc; $i += 2) {
        $content = str_replace($argv[$i], $argv[$i + 1], $content);
    }
    echo $content;
  ' "$template" unused "$@" >"$destination"
}

install_rendered_template() {
  local template="$1"
  local destination="$2"
  shift 2

  if [ -f "$destination" ] && [ "$FORCE_CONFIG" -ne 1 ]; then
    warn "Config existente preservada: $destination"
    return
  fi

  backup_path "$destination" "$BACKUP_ROOT" "$MANIFEST"
  mkdir -p "$(dirname "$destination")"
  render_template_file "$template" "$destination" "$@"
}

install_static_template() {
  local template="$1"
  local destination="$2"

  if [ -f "$destination" ] && [ "$FORCE_CONFIG" -ne 1 ]; then
    warn "Config existente preservada: $destination"
    return
  fi

  install_file "$template" "$destination" "$BACKUP_ROOT" "$MANIFEST"
}

mark_sql_applied() {
  local stamp_file="$1"

  mkdir -p "$SQL_STATE_DIR"
  touch "$stamp_file"
}

sql_declared_tables() {
  local sql_file="$1"

  php -r '
    $sql = file_get_contents($argv[1]);
    preg_match_all(
      "/CREATE\\s+TABLE\\s+(?:IF\\s+NOT\\s+EXISTS\\s+)?`?([A-Za-z0-9_]+)`?/i",
      $sql,
      $matches
    );

    foreach (array_values(array_unique($matches[1])) as $table) {
        echo $table, PHP_EOL;
    }
  ' "$sql_file"
}

sql_has_destructive_ddl() {
  local sql_file="$1"

  php -r '
    $sql = file_get_contents($argv[1]);
    exit(preg_match("/\\bDROP\\s+TABLE\\s+IF\\s+EXISTS\\b/i", $sql) ? 0 : 1);
  ' "$sql_file"
}

mysql_table_exists() {
  local table_name="$1"
  local result

  result="$(
    mysql -N -s -u admin "-p$DB_PASSWORD" "$DB_NAME" \
      -e "SHOW TABLES LIKE '$table_name'"
  )"

  [ "$result" = "$table_name" ]
}

detect_sql_schema_state() {
  local sql_file="$1"
  local -a tables=()
  local existing_count=0
  local table_name

  mapfile -t tables < <(sql_declared_tables "$sql_file")

  if [ "${#tables[@]}" -eq 0 ]; then
    printf 'unknown'
    return
  fi

  for table_name in "${tables[@]}"; do
    if mysql_table_exists "$table_name"; then
      existing_count=$((existing_count + 1))
    fi
  done

  if [ "$existing_count" -eq 0 ]; then
    printf 'absent'
    return
  fi

  if [ "$existing_count" -eq "${#tables[@]}" ]; then
    printf 'present'
    return
  fi

  printf 'partial:%s/%s' "$existing_count" "${#tables[@]}"
}

apply_sql_once() {
  local stamp_name="$1"
  local sql_file="$2"
  local stamp_file="$SQL_STATE_DIR/${stamp_name}.stamp"
  local schema_state

  if [ -f "$stamp_file" ]; then
    log "SQL já aplicado anteriormente: $stamp_name"
    return
  fi

  [ -f "$sql_file" ] || die "Arquivo SQL ausente: $sql_file"

  schema_state="$(detect_sql_schema_state "$sql_file")"

  case "$schema_state" in
    present)
      mark_sql_applied "$stamp_file"
      log "Schema já presente no banco; marcando SQL como aplicado: $stamp_name"
      return
      ;;
    partial:*)
      if sql_has_destructive_ddl "$sql_file"; then
        die "Schema parcial detectado para $stamp_name ($schema_state). Abortei para evitar SQL destrutivo sobre tabelas já existentes."
      fi

      warn "Schema parcial detectado para $stamp_name ($schema_state); aplicando SQL não destrutivo para completar a instalação"
      ;;
  esac

  mysql -u admin "-p$DB_PASSWORD" "$DB_NAME" <"$sql_file"
  mark_sql_applied "$stamp_file"
  log "SQL aplicado: $sql_file"
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
      --skip-sql)
        SKIP_SQL=1
        shift
        ;;
      --skip-config)
        SKIP_CONFIG=1
        shift
        ;;
      --skip-assets)
        SKIP_ASSETS=1
        shift
        ;;
      --force-config)
        FORCE_CONFIG=1
        shift
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

select_plugins() {
  case "$INSTALL_SET" in
    automatic)
      PLUGINS_TO_INSTALL=("automatic_addressbook")
      ;;
    calendar)
      PLUGINS_TO_INSTALL=("libcalendaring" "libkolab" "calendar")
      ;;
    all)
      PLUGINS_TO_INSTALL=("automatic_addressbook" "libcalendaring" "libkolab" "calendar")
      ;;
    *)
      die "install-set inválido: $INSTALL_SET"
      ;;
  esac
}

verify_environment() {
  require_root
  require_cmd php
  [ -d "$TARGET_DIR" ] || die "Diretório alvo não encontrado: $TARGET_DIR"
  [ -f "$TARGET_DIR/config/config.inc.php" ] || die "Config principal ausente em $TARGET_DIR/config/config.inc.php"

  if [ "$SKIP_SQL" -ne 1 ]; then
    require_cmd mysql
    [ -r "$DB_PASSWORD_FILE" ] || die "Arquivo de senha do banco não legível: $DB_PASSWORD_FILE"
    DB_PASSWORD="$(tr -d '\n' <"$DB_PASSWORD_FILE")"
  else
    DB_PASSWORD=""
  fi

  case "$CALENDAR_DRIVER" in
    database|kolab|caldav)
      ;;
    *)
      die "calendar-driver inválido: $CALENDAR_DRIVER"
      ;;
  esac
}

install_plugins() {
  local plugin source_path target_path

  for plugin in "${PLUGINS_TO_INSTALL[@]}"; do
    case "$plugin" in
      automatic_addressbook)
        source_path="$REPO_ROOT/upstream/automatic_addressbook"
        ;;
      calendar|libcalendaring|libkolab)
        source_path="$REPO_ROOT/upstream/kolab/$plugin"
        ;;
      *)
        die "Plugin não mapeado: $plugin"
        ;;
    esac

    target_path="$TARGET_DIR/plugins/$plugin"
    log "Instalando plugin: $plugin"
    replace_tree "$source_path" "$target_path" "$BACKUP_ROOT" "$MANIFEST"
  done
}

install_configs() {
  local fragment_template="$SCRIPT_DIR/templates/plugins-port.inc.php.tpl"
  local fragment_target="$TARGET_DIR/config/callendar.plugins.inc.php"
  local plugin_json

  [ "$SKIP_CONFIG" -eq 1 ] && return

  plugin_json="$(json_array_from_args "${PLUGINS_TO_INSTALL[@]}")"
  install_rendered_template "$fragment_template" "$fragment_target" "__PLUGIN_JSON__" "$plugin_json"

  backup_path "$TARGET_DIR/config/config.inc.php" "$BACKUP_ROOT" "$MANIFEST"
  php "$SCRIPT_DIR/php/ensure-roundcube-include.php" "$TARGET_DIR/config/config.inc.php" "callendar.plugins.inc.php" >/dev/null

  if [[ " ${PLUGINS_TO_INSTALL[*]} " == *" automatic_addressbook "* ]]; then
    install_static_template \
      "$SCRIPT_DIR/templates/automatic_addressbook.config.inc.php" \
      "$TARGET_DIR/plugins/automatic_addressbook/config/config.inc.php"
  fi

  if [[ " ${PLUGINS_TO_INSTALL[*]} " == *" calendar "* ]]; then
    install_rendered_template \
      "$SCRIPT_DIR/templates/calendar.config.inc.php.tpl" \
      "$TARGET_DIR/plugins/calendar/config/config.inc.php" \
      "__CALENDAR_DRIVER__" "$CALENDAR_DRIVER"
    install_static_template \
      "$SCRIPT_DIR/templates/libkolab.config.inc.php" \
      "$TARGET_DIR/plugins/libkolab/config.inc.php"
  fi
}

build_assets() {
  [ "$SKIP_ASSETS" -eq 1 ] && return

  if [[ " ${PLUGINS_TO_INSTALL[*]} " == *" calendar "* ]]; then
    "$SCRIPT_DIR/build-elastic-assets.sh" "$TARGET_DIR"
  fi
}

apply_sql() {
  [ "$SKIP_SQL" -eq 1 ] && return

  if [[ " ${PLUGINS_TO_INSTALL[*]} " == *" automatic_addressbook "* ]]; then
    apply_sql_once \
      "automatic_addressbook_mysql_initial" \
      "$TARGET_DIR/plugins/automatic_addressbook/SQL/mysql.initial.sql"
  fi

  if [[ " ${PLUGINS_TO_INSTALL[*]} " == *" calendar "* ]]; then
    apply_sql_once \
      "libkolab_mysql_initial" \
      "$TARGET_DIR/plugins/libkolab/SQL/mysql.initial.sql"
    apply_sql_once \
      "calendar_${CALENDAR_DRIVER}_mysql_initial" \
      "$TARGET_DIR/plugins/calendar/drivers/${CALENDAR_DRIVER}/SQL/mysql.initial.sql"
  fi
}

main() {
  parse_args "$@"
  select_plugins
  verify_environment

  STATE_BASE="$REPO_ROOT/.installer-state/$(state_key "$TARGET_DIR")"
  BACKUP_ROOT="$STATE_BASE/backups/$(timestamp)"
  MANIFEST="$BACKUP_ROOT/manifest.tsv"
  SQL_STATE_DIR="$STATE_BASE/sql"

  mkdir -p "$BACKUP_ROOT" "$SQL_STATE_DIR"

  install_plugins
  install_configs
  build_assets
  apply_sql

  log "Instalação concluída"
  log "Manifesto de backup: $MANIFEST"
}

main "$@"
