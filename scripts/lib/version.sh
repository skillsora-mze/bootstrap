#!/usr/bin/env bash

# Stable major.minor.patch versions only; optional v prefix and build metadata.
# Prereleases must not accidentally satisfy a stable minimum.
stable_version_core() {
    local value="${1#v}"
    if [[ "${value}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\+[0-9A-Za-z.-]+)?$ ]]; then
        printf '%s.%s.%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    else
        return 1
    fi
}

stable_version_at_least() {
    local actual minimum i
    local actual_parts minimum_parts
    actual="$(stable_version_core "$1")" || return 1
    minimum="$(stable_version_core "$2")" || return 1
    IFS=. read -r -a actual_parts <<< "${actual}"
    IFS=. read -r -a minimum_parts <<< "${minimum}"
    for i in 0 1 2; do
        (( actual_parts[i] > minimum_parts[i] )) && return 0
        (( actual_parts[i] < minimum_parts[i] )) && return 1
    done
    return 0
}
