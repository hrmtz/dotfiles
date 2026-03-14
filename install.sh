#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { printf "[dotfiles] %s\n" "$*"; }
warn()  { printf "[dotfiles][WARN] %s\n" "$*" >&2; }

COMMON_PACKAGES=(zsh git vim tmux)
MACOS_PACKAGES=(hammerspoon karabiner sketchybar wezterm gh)

detect_platform() {
  if [ -n "${CODESPACES:-}" ]; then echo "codespaces"
  elif [ "$(uname -s)" = "Darwin" ]; then echo "macos"
  else echo "linux"; fi
}

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  # Check if destination exists and handle DOTFILES_FORCE
  if [ -L "$dst" ] || [ -f "$dst" ] || [ -d "$dst" ]; then
    if [ "${DOTFILES_FORCE:-0}" != "1" ]; then
      warn "skip existing: $dst (set DOTFILES_FORCE=1 to overwrite)"
      return
    fi
    rm -rf "$dst"
  fi
  # Use ln -sf for idempotent symlink creation (atomic overwrite)
  ln -sf "$src" "$dst"
  info "linked: $dst -> $src"
}

stow_packages() {
  cd "$DOTFILES_DIR"
  stow -v -t "$HOME" "$@"
}

fallback_link() {
  # Codespaces 等 stow がない環境用フォールバック
  # Data-driven approach using associative array
  declare -A fallback_links=(
    [zsh/.zshrc]=".zshrc"
    [zsh/.zshenv]=".zshenv"
    [zsh/.zprofile]=".zprofile"
    [zsh/.p10k.zsh]=".p10k.zsh"
    [zsh/.zsh]=".zsh"
    [git/.gitconfig]=".gitconfig"
    [git/.gitignore_global]=".gitignore_global"
    [vim/.vimrc]=".vimrc"
    [tmux/.config/tmux/tmux.conf]=".config/tmux/tmux.conf"
  )

  for src_rel in "${!fallback_links[@]}"; do
    link "$DOTFILES_DIR/$src_rel" "$HOME/${fallback_links[$src_rel]}"
  done
}

ensure_zsh_for_codespaces() {
  local zsh_path=""

  # Try standard install paths first (no subshell needed)
  if [ -x "/bin/zsh" ]; then
    zsh_path="/bin/zsh"
  elif [ -x "/usr/bin/zsh" ]; then
    zsh_path="/usr/bin/zsh"
  else
    # Only call command -v once if zsh not in standard paths
    zsh_path="$(command -v zsh 2>/dev/null || true)"
  fi

  # If zsh not found, try to install it
  if [ -z "$zsh_path" ]; then
    info "zsh not found; installing via apt-get (Codespaces)"
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -y || warn "apt-get update failed (non-fatal)"
      sudo apt-get install -y zsh || warn "apt-get install zsh failed (non-fatal)"
      # Check again after install attempt
      zsh_path="$(command -v zsh 2>/dev/null || true)"
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

  # Install modern CLI tools first (includes stow)
  info "installing modern CLI tools..."
  if [ -x "$DOTFILES_DIR/install-modern-tools.sh" ]; then
    bash "$DOTFILES_DIR/install-modern-tools.sh"
  else
    warn "install-modern-tools.sh not found"
  fi

  # Configure git for delta (one-time setup, not on every shell startup)
  if command -v delta >/dev/null 2>&1; then
    info "configuring git for delta"
    git config --global core.pager delta 2>/dev/null || true
    git config --global delta.navigate true 2>/dev/null || true
  fi

  # Initialize zinit for shell plugins (one-time setup, not on every startup)
  if [ ! -d "$HOME/.zinit/bin" ]; then
    info "initializing zinit"
    mkdir -p "$HOME/.zinit"
    git clone https://github.com/zdharma-continuum/zinit.git "$HOME/.zinit/bin" 2>/dev/null || warn "zinit clone failed (non-fatal)"
  fi

  # Clean up existing dotfiles symlinks before stow (to avoid conflicts)
  # Remove symlinks that would be managed by stow
  info "cleaning up existing dotfiles symlinks"
  [ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
  [ -L "$HOME/.zshenv" ] && rm "$HOME/.zshenv"
  [ -L "$HOME/.zprofile" ] && rm "$HOME/.zprofile"
  [ -L "$HOME/.p10k.zsh" ] && rm "$HOME/.p10k.zsh"
  [ -L "$HOME/.p10k.kali.zsh" ] && rm "$HOME/.p10k.kali.zsh"
  [ -L "$HOME/.p10k.codespaces.zsh" ] && rm "$HOME/.p10k.codespaces.zsh"
  [ -L "$HOME/.zsh" ] && rm "$HOME/.zsh"
  [ -L "$HOME/.gitconfig" ] && rm "$HOME/.gitconfig"
  [ -L "$HOME/.gitignore_global" ] && rm "$HOME/.gitignore_global"
  [ -L "$HOME/.vimrc" ] && rm "$HOME/.vimrc"
  [ -L "$HOME/.config/git" ] && rm "$HOME/.config/git"

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
      # Only call chsh if current shell is different
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
