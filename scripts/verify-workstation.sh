#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"

required=(git aws sam az azd terraform packer ansible vagrant kubectl helm kind k9s kubectx docker)
failed=0

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

exit "${failed}"
