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
source "${ROOT_DIR}/scripts/lib/selection.sh"

INTERACTIVE_MODE="auto"
for arg in "$@"; do
    case "${arg}" in
        --interactive) INTERACTIVE_MODE="yes" ;;
        --non-interactive) INTERACTIVE_MODE="no" ;;
        -h|--help)
            cat <<'USAGE'
Usage: ./bootstrap.sh [--interactive|--non-interactive]

By default, module selection is interactive when attached to a terminal.
--interactive      Force interactive module selection.
--non-interactive  Use config/bootstrap.yaml without prompting (CI/automation).
USAGE
            exit 0
            ;;
        *) log_error "Unknown option: ${arg}"; exit 2 ;;
    esac
done

log_section "Workstation Bootstrap"

OS="$(detect_os)"
ARCH="$(detect_architecture)"
export OS ARCH

validate_supported_platform "${OS}" "${ARCH}"
load_config

VERSION="$(get_bootstrap_version)"
export KUBERNETES_MINOR KUBERNETES_PATCH KIND_VERSION K9S_VERSION KUBECTX_VERSION HELM_VERSION SAM_CLI_VERSION SAM_CLI_SHA256_AMD64 SAM_CLI_SHA256_ARM64 RANCHER_DESKTOP_VERSION AZD_VERSION AZD_SHA256_AMD64

log_info "Version: ${VERSION}"
log_info "Operating system: ${OS}"
log_info "Architecture: ${ARCH}"
if [[ "${OS}" == "linux" ]]; then
    DISTRO="$(detect_linux_distribution)"
    DISTRO_VERSION="$(detect_linux_version_id)"
    export DISTRO DISTRO_VERSION
    log_info "Distribution: ${DISTRO} ${DISTRO_VERSION}"
fi

selected_file="$(mktemp)"
trap 'rm -f "${selected_file}"' EXIT
if [[ "${INTERACTIVE_MODE}" == "yes" ]] || { [[ "${INTERACTIVE_MODE}" == "auto" ]] && [[ -t 0 ]] && [[ -t 1 ]] && [[ -z "${CI:-}" ]]; }; then
    select_modules_interactive > "${selected_file}"
else
    get_enabled_modules > "${selected_file}"
fi

selected_modules="$(paste -sd ',' "${selected_file}")"
log_info "Selected modules: ${selected_modules:-none}"

while IFS= read -r module; do
    [[ -z "${module}" ]] && continue
    run_module "${module}"
done < "${selected_file}"

log_success "Workstation Bootstrap ${VERSION} completed"
