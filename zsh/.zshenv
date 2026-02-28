# .zshenv — loaded for ALL zsh sessions (interactive, non-interactive, SSH)
# Keep minimal: only PATH and essential env vars

# Homebrew (macOS)
if [[ "$OSTYPE" == darwin* ]] && [[ -d /opt/homebrew ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi
