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
  local pkg_name=$3  # Optional: package name (different from command name)

  if command -v "$tool" >/dev/null 2>&1; then
    echo "[✓] $tool already installed ($desc)"
    return 0
  fi

  echo "[*] Installing $tool ($desc)..."

  # Package name default to tool name if not specified
  pkg_name=${pkg_name:-$tool}

  case "$OS" in
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "[✗] Homebrew not found, skipping $tool"
        return 1
      fi
      brew install "$pkg_name" >/dev/null 2>&1 && echo "[✓] $tool installed" || echo "[✗] Failed to install $tool"
      ;;
    kali|wsl|linux)
      sudo apt-get update -qq >/dev/null 2>&1
      sudo apt-get install -y "$pkg_name" >/dev/null 2>&1 && echo "[✓] $tool installed" || echo "[✗] Failed to install $tool"
      ;;
  esac
}

# インストール実行
echo ""
echo "[*] Installing modern CLI tools..."
echo ""

install_tool "lsd" "modern ls (LSDeluxe)"
install_tool "bat" "enhanced cat"
install_tool "rg" "fast grep (ripgrep)" "ripgrep"
install_tool "fd" "modern find" "fd-find"
install_tool "jq" "JSON processor"
install_tool "delta" "git diff enhancement"

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""

# Symlink fixes for Kali/Debian (fdfind → fd, ripgrep → rg)
if [[ "$OS" == "kali" || "$OS" == "wsl" || "$OS" == "linux" ]]; then
  echo "[*] Setting up symlinks..."

  # fdfind → fd (Kali provides fd-find package with fdfind binary)
  if ! command -v fd >/dev/null 2>&1; then
    if command -v fdfind >/dev/null 2>&1; then
      echo "[*] Creating symlink: fd → fdfind"
      sudo ln -sf /usr/bin/fdfind /usr/bin/fd 2>/dev/null && echo "[✓] fd symlink created" || echo "[!] fd symlink failed (may need: sudo ln -sf /usr/bin/fdfind /usr/bin/fd)"
    fi
  fi

  # ripgrep → rg (usually already works, but check)
  if ! command -v rg >/dev/null 2>&1 && command -v ripgrep >/dev/null 2>&1; then
    echo "[*] Creating symlink: rg → ripgrep"
    sudo ln -sf /usr/bin/ripgrep /usr/bin/rg 2>/dev/null && echo "[✓] rg symlink created" || echo "[!] rg symlink failed"
  fi
fi

echo ""
echo "Available aliases:"
echo "  ls        → lsd"
echo "  cat       → bat"
echo "  grep      → rg"
echo ""
echo "Available commands (use directly, no alias due to syntax differences):"
echo "  fd        → modern find (syntax: fd 'pattern')"
echo "  jq        → JSON processor"
echo "  delta     → git diff (GIT_PAGER set)"
echo ""
echo "Reload zsh to apply aliases:"
echo "  exec zsh"
echo ""
