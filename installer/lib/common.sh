#!/usr/bin/env bash

log() {
  printf '[info] %s\n' "$*"
}

warn() {
  printf '[warn] %s\n' "$*" >&2
}

die() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  have_cmd "$1" || die "Comando obrigatório ausente: $1"
}

timestamp() {
  date +"%Y%m%d-%H%M%S"
}

state_key() {
  printf '%s' "$1" | sha1sum | awk '{print $1}'
}

record_manifest() {
  local manifest="$1"
  local target="$2"
  local backup="$3"

  mkdir -p "$(dirname "$manifest")"
  printf '%s\t%s\n' "$target" "$backup" >>"$manifest"
}

backup_path() {
  local target="$1"
  local backup_root="$2"
  local manifest="$3"
  local backup_path

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup_path="$backup_root/${target#/}"
    mkdir -p "$(dirname "$backup_path")"
    cp -a "$target" "$backup_path"
  else
    backup_path="__MISSING__"
  fi

  record_manifest "$manifest" "$target" "$backup_path"
}

replace_tree() {
  local src="$1"
  local dest="$2"
  local backup_root="$3"
  local manifest="$4"

  [ -d "$src" ] || die "Diretório de origem ausente: $src"
  backup_path "$dest" "$backup_root" "$manifest"
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
}

install_file() {
  local src="$1"
  local dest="$2"
  local backup_root="$3"
  local manifest="$4"
  local mode="${5:-}"

  [ -f "$src" ] || die "Arquivo de origem ausente: $src"
  backup_path "$dest" "$backup_root" "$manifest"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"

  if [ -n "$mode" ]; then
    chmod "$mode" "$dest"
  fi
}

write_file() {
  local dest="$1"
  local backup_root="$2"
  local manifest="$3"
  local mode="${4:-}"

  backup_path "$dest" "$backup_root" "$manifest"
  mkdir -p "$(dirname "$dest")"
  cat >"$dest"

  if [ -n "$mode" ]; then
    chmod "$mode" "$dest"
  fi
}
