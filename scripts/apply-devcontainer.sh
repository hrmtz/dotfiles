#!/usr/bin/env bash
set -euo pipefail

# Apply devcontainer template from ~/.dotfiles to the current project.

DOTFILES_DEVCONTAINER_DIR="${HOME}/.dotfiles/.devcontainer"
PROJECT_DEVCONTAINER_DIR=".devcontainer"

if [ ! -d "${DOTFILES_DEVCONTAINER_DIR}" ]; then
  echo "ERROR: ${DOTFILES_DEVCONTAINER_DIR} not found. Ensure dotfiles devcontainer template exists." >&2
  exit 1
fi

mkdir -p "${PROJECT_DEVCONTAINER_DIR}"

cp "${DOTFILES_DEVCONTAINER_DIR}/devcontainer.json" "${PROJECT_DEVCONTAINER_DIR}/devcontainer.json"
cp "${DOTFILES_DEVCONTAINER_DIR}/postCreate.zsh-setup.sh" "${PROJECT_DEVCONTAINER_DIR}/postCreate.zsh-setup.sh"
chmod +x "${PROJECT_DEVCONTAINER_DIR}/postCreate.zsh-setup.sh"

echo "Applied devcontainer template to $(pwd)/${PROJECT_DEVCONTAINER_DIR}" 
 echo "- Reopen / Rebuild this project in container to take effect."