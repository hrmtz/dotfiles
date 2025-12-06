#!/usr/bin/env bash
set -euo pipefail

info()  { printf "[dotfiles][macos] %s\n" "$*"; }
warn()  { printf "[dotfiles][macos][WARN] %s\n" "$*" >&2; }

dotfiles_link() {
  local src="$1" dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ] || [ -f "$dst" ] || [ -d "$dst" ]; then
    if [ "${DOTFILES_FORCE:-0}" != "1" ]; then
      warn "skip existing: $dst (set DOTFILES_FORCE=1 to overwrite)"
      return
    fi
    rm -rf "$dst"
  fi

  ln -s "$src" "$dst"
  info "linked: $dst -> $src"
}

main() {
  local home_dir
  home_dir="${HOME:-$PWD}"
  local dotfiles_dir
  dotfiles_dir="$home_dir/.dotfiles"

  info "macOS bootstrap start (HOME=$home_dir DOTFILES=$dotfiles_dir)"

  # .config symlinks (Karabiner, skhd, yabai, wezterm)
  mkdir -p "$home_dir/.config" \
           "$home_dir/.config/skhd" \
           "$home_dir/.config/yabai" \
           "$home_dir/.config/wezterm" \
           "$dotfiles_dir/.config" \
           "$dotfiles_dir/.config/skhd" \
           "$dotfiles_dir/.config/yabai" \
           "$dotfiles_dir/.config/wezterm"

  # If a regular file exists in ~/.config and not yet in ~/.dotfiles/.config, copy it once
  for rel in "karabiner.edn" "skhd/skhdrc" "yabai/yabairc" "wezterm/wezterm.lua"; do
    local src_config dst_repo
    src_config="$home_dir/.config/$rel"
    dst_repo="$dotfiles_dir/.config/$rel"

    if [ -f "$src_config" ] && [ ! -e "$dst_repo" ]; then
      mkdir -p "$(dirname "$dst_repo")"
      cp -a "$src_config" "$dst_repo"
      info "copied: $src_config -> $dst_repo"
    fi
  done

  dotfiles_link "$dotfiles_dir/.config/karabiner.edn" "$home_dir/.config/karabiner.edn"
  dotfiles_link "$dotfiles_dir/.config/skhd/skhdrc"   "$home_dir/.config/skhd/skhdrc"
  dotfiles_link "$dotfiles_dir/.config/yabai/yabairc" "$home_dir/.config/yabai/yabairc"
  dotfiles_link "$dotfiles_dir/.config/wezterm/wezterm.lua" "$home_dir/.config/wezterm/wezterm.lua"

  info "macOS bootstrap done"
}

main "$@"
