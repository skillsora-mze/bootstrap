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

# Module-specific macOS packages must not leak into system_packages/Brewfile.
for token in orbstack awscli azure-cli azd terraform packer ansible vagrant kubectl helm@3 k9s kind kubectx; do
    if grep -Fq "${token}" "${ROOT_DIR}/packages/macos/Brewfile"; then
        echo "Module-specific macOS package leaked into base Brewfile: ${token}" >&2
        exit 1
    fi
done

# Each macOS-capable module owns installation of its own package-manager tools.
grep -q 'brew install --cask orbstack' "${ROOT_DIR}/scripts/modules/containers/install.sh"
grep -q 'brew install awscli' "${ROOT_DIR}/scripts/modules/aws/install.sh"
grep -q 'brew install azure-cli' "${ROOT_DIR}/scripts/modules/azure/install.sh"
grep -q 'brew install azd' "${ROOT_DIR}/scripts/modules/azure/install.sh"
grep -q 'brew install terraform' "${ROOT_DIR}/scripts/modules/hashicorp/install.sh"
grep -q 'brew install --cask vagrant' "${ROOT_DIR}/scripts/modules/hashicorp/install.sh"
grep -q 'brew install kubectl' "${ROOT_DIR}/scripts/modules/kubernetes/install.sh"
grep -q 'brew install helm@3' "${ROOT_DIR}/scripts/modules/kubernetes/install.sh"

if grep -q 'brew "aws-sam-cli"' "${ROOT_DIR}/packages/macos/Brewfile"; then
    echo "Unsupported Homebrew AWS SAM CLI formula still present" >&2
    exit 1
fi

[[ -f "${ROOT_DIR}/bootstrap.ps1" ]]
[[ -f "${ROOT_DIR}/bootstrap.cmd" ]]
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

legacy_runtime_pattern="$(printf '%s%s' 'ranch' 'er')|$(printf '%s%s' 'rd' 'ctl')"
if grep -R -E -i -q "${legacy_runtime_pattern}" "${ROOT_DIR}" --exclude-dir=.git; then
    echo 'Legacy Windows container runtime reference present' >&2
    exit 1
fi

grep -Fxq 'gh' "${ROOT_DIR}/packages/debian/packages.txt" || {
    echo "GitHub CLI missing from Debian system packages" >&2
    exit 1
}

grep -Fq 'UV_VERSION=' "${ROOT_DIR}/config/versions.env" || {
    echo "uv version baseline missing" >&2
    exit 1
}

grep -Fq 'YQ_VERSION=' "${ROOT_DIR}/config/versions.env" || {
    echo "yq version baseline missing" >&2
    exit 1
}

grep -Fq 'STARSHIP_VERSION=' "${ROOT_DIR}/config/versions.env" || {
    echo "starship version baseline missing" >&2
    exit 1
}

grep -Fq 'github.com/astral-sh/uv/releases/download/' "${ROOT_DIR}/scripts/linux/install-packages.sh" || {
    echo "Verified uv Linux release installation missing" >&2
    exit 1
}

grep -Fq 'github.com/mikefarah/yq/releases/download/' "${ROOT_DIR}/scripts/linux/install-packages.sh" || {
    echo "MikeFarah yq Linux release installation missing" >&2
    exit 1
}

grep -Fq 'github.com/starship/starship/releases/download/' "${ROOT_DIR}/scripts/linux/install-packages.sh" || {
    echo "Starship Linux release installation missing" >&2
    exit 1
}

grep -Fq 'system_packages) required+=(git gh python3 uv go jq yq rg starship)' \
    "${ROOT_DIR}/scripts/verify-workstation.sh" || {
    echo "Linux verification baseline is inconsistent" >&2
    exit 1
}
