#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_assets=(
  "$ROOT_DIR/upstream/kolab/libkolab/skins/elastic/libkolab.css"
  "$ROOT_DIR/upstream/kolab/libcalendaring/skins/elastic/libcal.css"
  "$ROOT_DIR/upstream/kolab/calendar/skins/elastic/fullcalendar.css"
  "$ROOT_DIR/upstream/kolab/calendar/skins/elastic/calendar.css"
  "$ROOT_DIR/upstream/kolab/calendar/skins/elastic/print.css"
)

for asset in "${required_assets[@]}"; do
  [ -f "$asset" ] || {
    printf '[error] Asset ausente: %s\n' "$asset" >&2
    exit 1
  }

  printf '[ok] %s\n' "$asset"
done
