#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_paths=(
  "$ROOT_DIR/upstream/automatic_addressbook/composer.json"
  "$ROOT_DIR/upstream/automatic_addressbook/automatic_addressbook.php"
  "$ROOT_DIR/upstream/kolab/calendar/composer.json"
  "$ROOT_DIR/upstream/kolab/libcalendaring/composer.json"
  "$ROOT_DIR/upstream/kolab/libkolab/composer.json"
  "$ROOT_DIR/installer/install-plesk.sh"
  "$ROOT_DIR/installer/preflight-plesk.sh"
  "$ROOT_DIR/installer/rollback.sh"
  "$ROOT_DIR/installer/build-elastic-assets.sh"
  "$ROOT_DIR/installer/templates/plugins-port.inc.php.tpl"
  "$ROOT_DIR/docs"
  "$ROOT_DIR/patches"
  "$ROOT_DIR/smoke-tests"
)

for path in "${required_paths[@]}"; do
  [ -e "$path" ] || {
    printf '[error] Ausente: %s\n' "$path" >&2
    exit 1
  }

  printf '[ok] %s\n' "$path"
done
