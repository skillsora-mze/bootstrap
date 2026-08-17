#!/usr/bin/env bash

run_module() {
    local module="$1"

    if ! module_enabled "${module}"; then
        log_info "Module '${module}' disabled"
        return 0
    fi

    log_section "Module: ${module}"

    local script="${ROOT_DIR}/scripts/modules/${module}/install.sh"
    if [[ ! -x "${script}" ]]; then
        log_error "Module '${module}' not implemented: ${script}"
        return 1
    fi

    # Run in a subshell: modules inherit framework variables/functions without
    # leaking their own functions or local state back into the bootstrap engine.
    # shellcheck disable=SC1090
    ( source "${script}" )

    log_success "Module '${module}' completed"
}
