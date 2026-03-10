# Main zshrc entrypoint (managed in ~/.dotfiles)

# Load common settings
if [[ -f "$HOME/.zsh/zshrc.common" ]]; then
  source "$HOME/.zsh/zshrc.common"
fi

# Environment-specific overrides
if [[ -n "${CODESPACES:-}" ]]; then
  if [[ -f "$HOME/.zsh/zshrc.codespaces" ]]; then
    source "$HOME/.zsh/zshrc.codespaces"
  fi
else
  # Assume macOS when OSTYPE matches, otherwise treat as generic linux
  if [[ "$OSTYPE" == darwin* ]] && [[ -f "$HOME/.zsh/zshrc.macos" ]]; then
    source "$HOME/.zsh/zshrc.macos"
  elif [[ -f "$HOME/.zsh/zshrc.linux" ]]; then
    source "$HOME/.zsh/zshrc.linux"
  fi
fi

# Local overrides (machine-specific secrets, not tracked by git)
if [[ -f "$HOME/.zsh/zshrc.local" ]]; then
  source "$HOME/.zsh/zshrc.local"
fi

# OpenClaw Completion
source <(openclaw completion --shell zsh)
