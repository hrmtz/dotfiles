#!/bin/bash

# install-modern-tools-macos.sh
# macOS 専用 モダン CLI ツール インストールスクリプト

set -e

echo "======================================"
echo "Modern CLI Tools Installer (macOS)"
echo "======================================"

# Homebrew チェック
if ! command -v brew >/dev/null 2>&1; then
  echo "[✗] Homebrew not found. Install from https://brew.sh"
  exit 1
fi

echo "[*] Using Homebrew"
echo ""

# インストール関数
install_tool() {
  local cmd=$1
  local pkg=$2
  local desc=$3

  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[✓] $cmd already installed ($desc)"
    return 0
  fi

  echo "[*] Installing $cmd via brew ($desc)..."
  brew install "$pkg" >/dev/null 2>&1 && echo "[✓] $cmd installed" || echo "[✗] Failed to install $cmd"
}

# インストール実行
echo "[*] Installing modern CLI tools..."
echo ""

install_tool "lsd" "lsd" "modern ls"
install_tool "bat" "bat" "enhanced cat"
install_tool "rg" "ripgrep" "fast grep"
install_tool "fd" "fd" "modern find"
install_tool "jq" "jq" "JSON processor"
install_tool "delta" "delta" "git diff enhancement"

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Available aliases:"
echo "  ls        → lsd"
echo "  cat       → bat"
echo "  grep      → rg"
echo ""
echo "Available commands (use directly):"
echo "  fd        → modern find (syntax: fd 'pattern')"
echo "  jq        → JSON processor"
echo "  delta     → git diff (GIT_PAGER set)"
echo ""
echo "Reload zsh to apply aliases:"
echo "  exec zsh"
echo ""
