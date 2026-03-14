#!/bin/bash

# install-modern-tools.sh
# Dispatcher script - runs OS-specific installer

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$OS" in
  macos)
    echo "Detected: macOS"
    bash "$SCRIPT_DIR/install-modern-tools-macos.sh"
    ;;
  kali)
    echo "Detected: Kali Linux"
    bash "$SCRIPT_DIR/install-modern-tools-kali.sh"
    ;;
  wsl|linux)
    echo "Detected: WSL/Linux (using Kali script)"
    bash "$SCRIPT_DIR/install-modern-tools-kali.sh"
    ;;
  *)
    echo "Unknown OS"
    exit 1
    ;;
esac

