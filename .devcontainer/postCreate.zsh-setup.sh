#!/usr/bin/env bash
set -euo pipefail

# Install zsh if not present
if ! command -v zsh >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y zsh
fi

# Ensure vscode user's default shell is /bin/zsh
current_shell="$(getent passwd vscode | cut -d: -f7 || true)"
if [ "$current_shell" != "/bin/zsh" ]; then
  sudo chsh -s /bin/zsh vscode
fi
