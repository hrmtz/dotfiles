#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { printf "[dotfiles] %s\n" "$*"; }
warn()  { printf "[dotfiles][WARN] %s\n" "$*" >&2; }

COMMON_PACKAGES=(zsh git vim)
MACOS_PACKAGES=(hammerspoon karabiner sketchybar tmux wezterm gh)

detect_platform() {
  if [ -n "${CODESPACES:-}" ]; then echo "codespaces"
  elif [ "$(uname -s)" = "Darwin" ]; then echo "macos"
  else echo "linux"; fi
}

link() {
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

stow_packages() {
  cd "$DOTFILES_DIR"
  stow -v -t "$HOME" "$@"
}

fallback_link() {
  # Codespaces 等 stow がない環境用フォールバック
  link "$DOTFILES_DIR/zsh/.zshrc"            "$HOME/.zshrc"
  link "$DOTFILES_DIR/zsh/.zshenv"           "$HOME/.zshenv"
  link "$DOTFILES_DIR/zsh/.zprofile"         "$HOME/.zprofile"
  link "$DOTFILES_DIR/zsh/.p10k.zsh"         "$HOME/.p10k.zsh"
  link "$DOTFILES_DIR/zsh/.zsh"              "$HOME/.zsh"
  link "$DOTFILES_DIR/git/.gitconfig"        "$HOME/.gitconfig"
  link "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
  link "$DOTFILES_DIR/vim/.vimrc"            "$HOME/.vimrc"
}

ensure_zsh_for_codespaces() {
  local zsh_path=""

  if [ -x "/bin/zsh" ]; then
    zsh_path="/bin/zsh"
  elif [ -x "/usr/bin/zsh" ]; then
    zsh_path="/usr/bin/zsh"
  elif command -v zsh >/dev/null 2>&1; then
    zsh_path="$(command -v zsh)"
  else
    info "zsh not found; installing via apt-get (Codespaces)"
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -y || warn "apt-get update failed (non-fatal)"
      sudo apt-get install -y zsh || warn "apt-get install zsh failed (non-fatal)"
      if command -v zsh >/dev/null 2>&1; then
        zsh_path="$(command -v zsh)"
      fi
    else
      warn "apt-get not available; cannot auto-install zsh"
    fi
  fi

  if [ -z "$zsh_path" ]; then
    warn "zsh path could not be determined; skipping chsh"
  fi

  printf '%s\n' "$zsh_path"
}

set_login_shell_for_vscode() {
  local zsh_path="$1"
  [ -z "$zsh_path" ] && return 0

  local target_user="vscode"
  if ! getent passwd "$target_user" >/dev/null 2>&1; then
    target_user="${USER:-$target_user}"
  fi

  local passwd_entry
  passwd_entry="$(getent passwd "$target_user" || true)"
  if [ -z "$passwd_entry" ]; then
    warn "user '$target_user' not found; skipping chsh"
    return 0
  fi

  local current_shell
  current_shell="$(printf '%s\n' "$passwd_entry" | cut -d: -f7)"
  if [ "$current_shell" = "$zsh_path" ]; then
    info "login shell for $target_user is already $zsh_path; no change"
    return 0
  fi

  info "changing login shell for $target_user: $current_shell -> $zsh_path"
  sudo chsh -s "$zsh_path" "$target_user" || warn "chsh failed for $target_user (non-fatal)"
}

main() {
  info "dotfiles install start (DIR=$DOTFILES_DIR)"
  local platform
  platform="$(detect_platform)"
  info "platform: $platform"

  if command -v stow >/dev/null 2>&1; then
    stow_packages "${COMMON_PACKAGES[@]}"
    if [ "$platform" = "macos" ]; then
      stow_packages "${MACOS_PACKAGES[@]}"
      # iterm2: AppSupport is an absolute symlink, stow can't handle it
      link "$DOTFILES_DIR/iterm2/.config/iterm2/AppSupport" "$HOME/.config/iterm2/AppSupport"
    fi
  else
    warn "stow not found, using fallback symlinks"
    fallback_link
  fi

  # Set default shell to zsh when available (best-effort)
  if command -v zsh >/dev/null 2>&1; then
    if [ -z "${CODESPACES:-}" ]; then
      local zsh_path
      zsh_path="$(command -v zsh)"
      if [ "${SHELL:-}" != "$zsh_path" ]; then
        chsh -s "$zsh_path" "${USER:-$(id -un)}" 2>/dev/null || warn "failed to chsh (non-fatal)"
      fi
    fi
  fi

  # Codespaces: p10k override + bootstrap
  if [ "$platform" = "codespaces" ]; then
    [ -f "$DOTFILES_DIR/zsh/.p10k.codespaces.zsh" ] && \
      link "$DOTFILES_DIR/zsh/.p10k.codespaces.zsh" "$HOME/.p10k.zsh"
    [ -x "$DOTFILES_DIR/scripts/codespaces-bootstrap.sh" ] && \
      "$DOTFILES_DIR/scripts/codespaces-bootstrap.sh"

    # Ensure zsh is available and set as login shell for Codespaces user
    local zsh_path
    zsh_path="$(ensure_zsh_for_codespaces)"
    set_login_shell_for_vscode "$zsh_path"
  fi

  info "dotfiles install done"
}

main "$@"
