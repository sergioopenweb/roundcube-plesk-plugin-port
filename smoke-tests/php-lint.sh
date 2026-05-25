#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

php_files=(
  "$ROOT_DIR/upstream/automatic_addressbook/automatic_addressbook.php"
  "$ROOT_DIR/upstream/automatic_addressbook/automatic_addressbook_backend.php"
  "$ROOT_DIR/upstream/kolab/libkolab/libkolab.php"
  "$ROOT_DIR/upstream/kolab/libcalendaring/libcalendaring.php"
  "$ROOT_DIR/upstream/kolab/calendar/lib/calendar_ui.php"
  "$ROOT_DIR/installer/php/ensure-roundcube-include.php"
)

for file in "${php_files[@]}"; do
  php -l "$file" >/dev/null
  printf '[ok] %s\n' "$file"
done
