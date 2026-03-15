# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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
  # Detect Kali Linux first (most specific)
  if grep -qi kali /etc/os-release 2>/dev/null && [[ -f "$HOME/.zsh/zshrc.kali" ]]; then
    source "$HOME/.zsh/zshrc.kali"
  # Assume macOS when OSTYPE matches
  elif [[ "$OSTYPE" == darwin* ]] && [[ -f "$HOME/.zsh/zshrc.macos" ]]; then
    source "$HOME/.zsh/zshrc.macos"
  # Generic Linux fallback
  elif [[ -f "$HOME/.zsh/zshrc.linux" ]]; then
    source "$HOME/.zsh/zshrc.linux"
  fi
fi

# Local overrides (machine-specific secrets, not tracked by git)
if [[ -f "$HOME/.zsh/zshrc.local" ]]; then
  source "$HOME/.zsh/zshrc.local"
fi

# OpenClaw Completion (optional, skip if not installed)
if command -v openclaw >/dev/null 2>&1; then
  source <(openclaw completion --shell zsh) 2>/dev/null || true
fi

# p10k config is loaded in zshrc.common
