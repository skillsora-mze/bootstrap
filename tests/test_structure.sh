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

if grep -q 'brew "aws-sam-cli"' "${ROOT_DIR}/packages/macos/Brewfile"; then
    echo "Unsupported Homebrew AWS SAM CLI formula still present" >&2
    exit 1
fi

[[ -f "${ROOT_DIR}/bootstrap.ps1" ]]
[[ -f "${ROOT_DIR}/packages/windows/packages.psd1" ]]

if grep -R -q 'ibmmo/workstation-bootstrap' "${ROOT_DIR}/README.md" "${ROOT_DIR}/USERGUIDE.md" "${ROOT_DIR}/docs"; then
    echo "Legacy repository URL still present" >&2
    exit 1
fi

if grep -q 'minimum_build: 26100' "${ROOT_DIR}/config/bootstrap.yaml"; then
    echo "Obsolete Windows minimum build still present" >&2
    exit 1
fi

if grep -R -q 'sam\.exe' "${ROOT_DIR}/scripts"; then
    echo "Unsupported sam.exe reference still present" >&2
    exit 1
fi

if grep -R -q 'install-azd\.sh' "${ROOT_DIR}/scripts"; then
    echo "Mutable azd installer script reference still present" >&2
    exit 1
fi

if grep -q 'module_enabled' "${ROOT_DIR}/scripts/lib/module.sh"; then
    echo "Dispatcher still re-checks persistent module configuration" >&2
    exit 1
fi

[[ -f "${ROOT_DIR}/tests/windows/test-native-command.ps1" ]]
