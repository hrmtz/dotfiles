#!/usr/bin/env bash
set -euo pipefail

# Minimal bootstrap for Codespaces; extend as needed

if command -v apt >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y fzf fd-find ripgrep lsd
fi
