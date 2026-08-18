#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for module in system_packages containers aws azure hashicorp kubernetes terminal; do
    [[ -x "${ROOT_DIR}/scripts/modules/${module}/install.sh" ]] || { echo "Missing executable Bash module: ${module}" >&2; exit 1; }
    [[ -f "${ROOT_DIR}/scripts/modules/${module}/install.ps1" ]] || { echo "Missing PowerShell module: ${module}" >&2; exit 1; }
done
[[ ! -e "${ROOT_DIR}/scripts/modules/docker" ]] || { echo "Legacy docker module still present" >&2; exit 1; }
[[ -f "${ROOT_DIR}/scripts/lib/selection.sh" ]]
[[ -f "${ROOT_DIR}/packages/macos/Brewfile" ]]
grep -q 'cask "orbstack"' "${ROOT_DIR}/packages/macos/Brewfile"
grep -q 'brew "helm@3"' "${ROOT_DIR}/packages/macos/Brewfile"
! grep -q 'brew "aws-sam-cli"' "${ROOT_DIR}/packages/macos/Brewfile"
[[ -f "${ROOT_DIR}/bootstrap.ps1" ]]
[[ -f "${ROOT_DIR}/packages/windows/packages.psd1" ]]
! grep -R -q 'ibmmo/workstation-bootstrap' "${ROOT_DIR}/README.md" "${ROOT_DIR}/USERGUIDE.md" "${ROOT_DIR}/docs"
! grep -q 'minimum_build: 26100' "${ROOT_DIR}/config/bootstrap.yaml"
! grep -R -q 'sam\.exe' "${ROOT_DIR}/scripts"
! grep -R -q 'install-azd\.sh' "${ROOT_DIR}/scripts"
! grep -q 'module_enabled' "${ROOT_DIR}/scripts/lib/module.sh"
[[ -f "${ROOT_DIR}/tests/windows/test-native-command.ps1" ]]
