#!/usr/bin/env bash
set -euo pipefail

# Dotfiles repo root (this script is assumed to live here)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prefer zsh if available
if command -v zsh >/dev/null 2>&1; then
  ZSH_PATH="$(command -v zsh)"
  # Set login shell for current user when possible (may fail in Codespaces, so ignore errors)
  chsh -s "$ZSH_PATH" "${USER:-vscode}" 2>/dev/null || true
fi

# Symlink zsh config
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
  ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
fi

if [ -f "$DOTFILES_DIR/.p10k.zsh" ]; then
  ln -sf "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
fi

# Ensure bash also hands off to zsh when interactive
BASHRC_PATH="$HOME/.bashrc"

if ! grep -q "exec \"\$SHELL\" -l" "$BASHRC_PATH" 2>/dev/null; then
  cat >> "$BASHRC_PATH" <<'EOF'
# --- auto-switch to zsh when available (installed via dotfiles) ---
if [ -t 1 ] && command -v zsh >/dev/null 2>&1; then
  export SHELL="$(command -v zsh)"
  exec "$SHELL" -l
fi
EOF
fi

# --- oh-my-zsh / powerlevel10k / zsh-completions setup ---

# oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  export CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
fi

# zsh-completions plugin
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ]; then
  git clone https://github.com/zsh-users/zsh-completions \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"
fi

if command -v apt >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y fzf fd-find ripgrep
  command -v lsd >/dev/null 2>&1 || sudo apt-get install -y lsd
  command -v bat >/dev/null 2>&1 || sudo apt-get install -y bat
fi
