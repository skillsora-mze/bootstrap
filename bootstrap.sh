#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR

source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/platform.sh"
source "${ROOT_DIR}/scripts/lib/verify.sh"
source "${ROOT_DIR}/scripts/lib/config.sh"
source "${ROOT_DIR}/scripts/lib/download.sh"
source "${ROOT_DIR}/scripts/lib/module.sh"

log_section "Workstation Bootstrap"

OS="$(detect_os)"
ARCH="$(detect_architecture)"
export OS ARCH

validate_supported_platform "${OS}" "${ARCH}"
load_config

VERSION="$(get_bootstrap_version)"
export KUBERNETES_MINOR KUBERNETES_PATCH KIND_VERSION K9S_VERSION KUBECTX_VERSION HELM_VERSION SAM_CLI_VERSION SAM_CLI_SHA256_AMD64 SAM_CLI_SHA256_ARM64 RANCHER_DESKTOP_VERSION

log_info "Version: ${VERSION}"
log_info "Operating system: ${OS}"
log_info "Architecture: ${ARCH}"
if [[ "${OS}" == "linux" ]]; then
    DISTRO="$(detect_linux_distribution)"
    DISTRO_VERSION="$(detect_linux_version_id)"
    export DISTRO DISTRO_VERSION
    log_info "Distribution: ${DISTRO} ${DISTRO_VERSION}"
fi

while IFS= read -r module; do
    [[ -z "${module}" ]] && continue
    run_module "${module}"
done < <(get_enabled_modules)

log_success "Workstation Bootstrap ${VERSION} completed"
