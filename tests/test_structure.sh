#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for module in system_packages containers aws azure hashicorp kubernetes terminal; do
    [[ -x "${ROOT_DIR}/scripts/modules/${module}/install.sh" ]] || { echo "Missing executable module: ${module}" >&2; exit 1; }
done
[[ ! -e "${ROOT_DIR}/scripts/modules/docker" ]] || { echo "Legacy docker module still present" >&2; exit 1; }
[[ -f "${ROOT_DIR}/packages/macos/Brewfile" ]]
grep -q 'cask "orbstack"' "${ROOT_DIR}/packages/macos/Brewfile"
grep -q 'brew "helm@3"' "${ROOT_DIR}/packages/macos/Brewfile"
[[ -f "${ROOT_DIR}/bootstrap.ps1" ]]
[[ -f "${ROOT_DIR}/packages/windows/packages.psd1" ]]
