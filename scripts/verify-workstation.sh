#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/config.sh"

failed=0
required=()

while IFS= read -r module; do
    case "${module}" in
        system_packages) required+=(git gh python uv go jq yq rg starship) ;;
        containers) required+=(docker) ;;
        aws) required+=(aws sam) ;;
        azure) required+=(az azd) ;;
        hashicorp) required+=(terraform packer ansible vagrant) ;;
        kubernetes) required+=(kubectl helm kind k9s kubectx) ;;
        terminal) ;;
    esac
done < <(get_enabled_modules)

log_section "Workstation verification"
for cmd in "${required[@]}"; do
    if command -v "${cmd}" >/dev/null 2>&1; then
        log_success "${cmd}"
    else
        log_error "${cmd} missing"
        failed=1
    fi
done

if command -v docker >/dev/null 2>&1; then
    docker info >/dev/null 2>&1 || { log_error "Container engine unavailable"; failed=1; }
fi

[[ "${failed}" -eq 0 ]] && log_success "Workstation verification completed"
exit "${failed}"
