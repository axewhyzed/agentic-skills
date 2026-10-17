#!/usr/bin/env bash
# install.sh - Cross-Platform Skill Installer for Linux / macOS
set -euo pipefail

TARGET="${1:-global}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/../skills"

if [ ! -d "${SOURCE_DIR}" ]; then
    SOURCE_DIR="${SCRIPT_DIR}/../.agents/skills"
fi

if [ "${TARGET}" = "global" ]; then
    DEST_DIR="${HOME}/.gemini/config/skills"
    echo -e "\033[36mInstalling Agentic Skills globally into ${DEST_DIR}...\033[0m"
else
    DEST_DIR="$(pwd)/.agents/skills"
    echo -e "\033[36mInstalling Agentic Skills into workspace: ${DEST_DIR}...\033[0m"
fi

mkdir -p "${DEST_DIR}"
cp -R "${SOURCE_DIR}/"* "${DEST_DIR}/"

echo -e "\033[32mSuccessfully installed skills:\033[0m"
for dir in "${DEST_DIR}"/*; do
    if [ -d "$dir" ]; then
        echo -e "  \033[33m- $(basename "$dir")\033[0m"
    fi
done
