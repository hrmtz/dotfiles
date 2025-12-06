#!/usr/bin/env bash
set -euo pipefail

# Detect zsh path (prefer /bin/zsh, fallback to command -v)
zsh_path="/bin/zsh"
if ! [ -x "$zsh_path" ]; then
  if command -v zsh >/dev/null 2>&1; then
    zsh_path="$(command -v zsh)"
  else
    # Install zsh if not present
    sudo apt-get update
    sudo apt-get install -y zsh
    zsh_path="$(command -v zsh || true)"
  fi
fi

if [ -z "$zsh_path" ]; then
  echo "WARN: zsh not found and could not be installed; skipping chsh"
  exit 0
fi

# Target user (Codespaces なら $USER でほぼよい)
target_user="${USER:-codespace}"

passwd_entry="$(getent passwd "$target_user" || true)"
if [ -z "$passwd_entry" ]; then
  echo "WARN: user '$target_user' not found in passwd; skipping chsh"
  exit 0
fi

current_shell="$(printf '%s\n' "$passwd_entry" | cut -d: -f7)"
if [ -n "$current_shell" ] && [ "$current_shell" != "$zsh_path" ]; then
  echo "Changing login shell for $target_user: $current_shell -> $zsh_path"
  if sudo chsh -s "$zsh_path" "$target_user"; then
    echo "Login shell updated for $target_user"
  else
    echo "WARN: chsh failed for $target_user (non-fatal)"
  fi
else
  echo "Login shell for $target_user is already $zsh_path; nothing to do"
fi
