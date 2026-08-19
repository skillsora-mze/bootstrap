#!/usr/bin/env bash

CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${CONFIG_ROOT}/config/bootstrap.yaml"
VERSIONS_FILE="${CONFIG_ROOT}/config/versions.env"

load_config() {
    [[ -f "${CONFIG_FILE}" ]] || { log_error "Configuration file not found: ${CONFIG_FILE}"; return 1; }
    [[ -f "${VERSIONS_FILE}" ]] || { log_error "Versions file not found: ${VERSIONS_FILE}"; return 1; }

    # shellcheck disable=SC1090
    source "${VERSIONS_FILE}"

    local required=(KUBERNETES_MINOR KUBERNETES_PATCH KIND_VERSION K9S_VERSION KUBECTX_VERSION HELM_VERSION SAM_CLI_VERSION SAM_CLI_SHA256_AMD64 SAM_CLI_SHA256_ARM64 SAM_CLI_SHA256_MACOS_ARM64 RANCHER_DESKTOP_VERSION AZD_VERSION AZD_SHA256_AMD64 AZD_SHA256_ARM64)
    local var
    for var in "${required[@]}"; do
        [[ -n "${!var:-}" ]] || { log_error "Missing required version: ${var}"; return 1; }
    done
}

module_enabled() {
    local module="$1"
    grep -Eq "^[[:space:]]{2}${module}:[[:space:]]*true[[:space:]]*$" "${CONFIG_FILE}"
}

get_enabled_modules() {
    awk '
        /^modules:[[:space:]]*$/ { in_modules=1; next }
        in_modules && /^[^[:space:]]/ { exit }
        in_modules && /^[[:space:]]{2}[A-Za-z0-9_-]+:[[:space:]]*true[[:space:]]*$/ {
            key=$1; sub(":", "", key); print key
        }
    ' "${CONFIG_FILE}"
}

get_bootstrap_version() {
    awk -F': *' '
        /^bootstrap:[[:space:]]*$/ { in_bootstrap=1; next }
        in_bootstrap && /^[^[:space:]]/ { exit }
        in_bootstrap && /^[[:space:]]{2}version:/ {
            gsub(/^[[:space:]"]+|[[:space:]"]+$/, "", $2); print $2; exit
        }
    ' "${CONFIG_FILE}"
}
