#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/platform.sh"

DISTRO="$(detect_linux_distribution)"
[[ "${DISTRO}" == "debian" ]] || { log_error "Unsupported Linux distribution: ${DISTRO}"; exit 1; }

PACKAGE_FILE="${ROOT_DIR}/packages/debian/packages.txt"
[[ -f "${PACKAGE_FILE}" ]] || { log_error "Package file not found: ${PACKAGE_FILE}"; exit 1; }

log_section "Installing Debian system packages"
sudo apt-get update

packages=()
while IFS= read -r package; do
    [[ -z "${package}" || "${package}" =~ ^[[:space:]]*# ]] && continue
    packages+=("${package}")
done < "${PACKAGE_FILE}"

if ((${#packages[@]})); then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
fi

log_success "Debian system packages installation completed"
