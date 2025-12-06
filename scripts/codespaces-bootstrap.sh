#!/usr/bin/env bash
set -euo pipefail

# Minimal bootstrap for Codespaces; extend as needed

if command -v apt >/dev/null 2>&1; then
  echo "[codespaces-bootstrap] apt-based environment detected; installing CLI tools (best-effort)..."
  sudo apt-get update -y || echo "[codespaces-bootstrap][WARN] apt-get update failed (continuing)"
  sudo apt-get install -y fzf fd-find ripgrep lsd || echo "[codespaces-bootstrap][WARN] apt-get install failed (continuing)"
fi

# Ensure VS Code settings for integrated terminal (zsh on Linux)
SETTINGS_DIR="/workspaces/dotfiles/.vscode"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"
TEMPLATE_FILE="${SETTINGS_DIR}/settings.codespaces.json"

mkdir -p "${SETTINGS_DIR}"

# If jq is available, merge existing settings.json and template; otherwise, fallback to overwrite.
if [ -f "${TEMPLATE_FILE}" ]; then
  if command -v jq >/dev/null 2>&1 && [ -f "${SETTINGS_FILE}" ]; then
    # Merge: existing SETTINGS_FILE + TEMPLATE_FILE (template wins on conflicts)
    TMP_FILE="${SETTINGS_FILE}.tmp"
    jq -s '.[0] * .[1]' "${SETTINGS_FILE}" "${TEMPLATE_FILE}" > "${TMP_FILE}"
    mv "${TMP_FILE}" "${SETTINGS_FILE}"
  else
    # No jq or no existing settings.json: just copy template
    cp "${TEMPLATE_FILE}" "${SETTINGS_FILE}"
  fi
fi

