#!/bin/bash

# install-modern-tools.sh
# モダン CLI ツール自動インストールスクリプト
# 対応 OS: macOS (brew), WSL (apt), Kali (apt), Generic Linux (apt)

set -e

echo "======================================"
echo "Modern CLI Tools Installer"
echo "======================================"

# OS 検出
detect_os() {
  if grep -qi kali /etc/os-release 2>/dev/null; then
    echo "kali"
  elif [[ "$OSTYPE" == darwin* ]]; then
    echo "macos"
  elif grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "linux"
  fi
}

OS=$(detect_os)
echo "[*] Detected OS: $OS"

# インストール関数
install_tool() {
  local tool=$1
  local desc=$2

  if command -v "$tool" >/dev/null 2>&1; then
    echo "[✓] $tool already installed ($desc)"
    return 0
  fi

  echo "[*] Installing $tool ($desc)..."

  case "$OS" in
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "[✗] Homebrew not found, skipping $tool"
        return 1
      fi
      brew install "$tool" >/dev/null 2>&1 && echo "[✓] $tool installed" || echo "[✗] Failed to install $tool"
      ;;
    kali|wsl|linux)
      sudo apt-get update -qq >/dev/null 2>&1
      sudo apt-get install -y "$tool" >/dev/null 2>&1 && echo "[✓] $tool installed" || echo "[✗] Failed to install $tool"
      ;;
  esac
}

# インストール実行
echo ""
echo "[*] Installing modern CLI tools..."
echo ""

install_tool "lsd" "modern ls (LSDeluxe)"
install_tool "bat" "enhanced cat"
install_tool "ripgrep" "fast grep (rg)"
install_tool "fd" "modern find"
install_tool "jq" "JSON processor"
install_tool "delta" "git diff enhancement"

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Available aliases:"
echo "  ls        → lsd"
echo "  cat       → bat"
echo "  grep      → rg"
echo "  find      → fd"
echo "  jq        → (no alias, use directly)"
echo "  delta     → (GIT_PAGER set)"
echo ""
echo "Reload zsh to apply aliases:"
echo "  exec zsh"
echo ""
