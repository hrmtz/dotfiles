#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { printf "[dotfiles] %s\n" "$*"; }
warn()  { printf "[dotfiles][WARN] %s\n" "$*" >&2; }
error() { printf "[dotfiles][ERROR] %s\n" "$*" >&2; exit 1; }

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

detect_platform() {
  if [ -n "${CODESPACES:-}" ]; then
    echo "codespaces"
  elif [ "${OSTYPE:-}" = darwin* ] || [ "$(uname -s 2>/dev/null || echo unknown)" = "Darwin" ]; then
    echo "macos"
  else
    echo "linux"
  fi
}

main() {
  info "dotfiles install start (DIR=$DOTFILES_DIR)"

  # Ensure we are used as ~/.dotfiles when possible
  if [ "${HOME:-}" != "$DOTFILES_DIR" ]; then
    if [ ! -e "$HOME/.dotfiles" ]; then
      ln -s "$DOTFILES_DIR" "$HOME/.dotfiles"
      info "linked: $HOME/.dotfiles -> $DOTFILES_DIR"
    fi
  fi

  # zsh / p10k entrypoints
  link "$DOTFILES_DIR/zsh/zshrc"      "$HOME/.zshrc"
  link "$DOTFILES_DIR/zsh/zprofile"   "$HOME/.zprofile"
  # Default p10k (overridden per-platform below if needed)
  link "$DOTFILES_DIR/.p10k.zsh"      "$HOME/.p10k.zsh"
  link "$DOTFILES_DIR/zsh"            "$HOME/.zsh"

  # git
  [ -f "$DOTFILES_DIR/git/gitconfig" ]  && link "$DOTFILES_DIR/git/gitconfig"  "$HOME/.gitconfig"
  [ -f "$DOTFILES_DIR/git/gitignore" ]  && link "$DOTFILES_DIR/git/gitignore"  "$HOME/.gitignore"

  # vim (optional)
  if [ -d "$DOTFILES_DIR/vim" ]; then
    link "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"
    link "$DOTFILES_DIR/vim"        "$HOME/.vim"
  fi

  # Set default shell to zsh when available (best-effort)
  if command -v zsh >/dev/null 2>&1; then
    local zsh_path
    zsh_path="$(command -v zsh)"
    if [ "${SHELL:-}" != "$zsh_path" ]; then
      chsh -s "$zsh_path" "${USER:-$(id -un)}" 2>/dev/null || warn "failed to chsh (non-fatal)"
    fi
  fi

  # Platform-specific bootstrap (optional hooks)
  local platform
  platform="$(detect_platform)"
  info "platform detected: $platform"

  case "$platform" in
    macos)
      [ -x "$DOTFILES_DIR/scripts/macos-bootstrap.sh" ] && "$DOTFILES_DIR/scripts/macos-bootstrap.sh"
      ;;
    codespaces)
      # Override p10k config for Codespaces if a dedicated config exists.
      if [ -f "$DOTFILES_DIR/.p10k.codespaces.zsh" ]; then
	link "$DOTFILES_DIR/.p10k.codespaces.zsh" "$HOME/.p10k.zsh"
      fi
      [ -x "$DOTFILES_DIR/scripts/codespaces-bootstrap.sh" ] && "$DOTFILES_DIR/scripts/codespaces-bootstrap.sh"
      ;;
    *)
      ;;
  esac

  info "dotfiles install done"
}

main "$@"
