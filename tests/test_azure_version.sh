#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/version.sh"

for version in 1.31.1 1.31.2 1.32.0 1.100.0 2.0.0 v1.31.1 1.31.1+build.7; do
    stable_version_at_least "${version}" 1.31.1
done
for version in 1.31.0 1.9.0 0.99.99 1.31.1-beta.1 1.32.0-preview 01.31.1 unknown ''; do
    if stable_version_at_least "${version}" 1.31.1; then
        echo "Invalid/old version accepted: ${version}" >&2
        exit 1
    fi
done

# Exercise the complete module with preinstalled CLIs: no installer may run.
export OS=linux ARCH=amd64 AZD_VERSION=1.31.1
# shellcheck disable=SC2329,SC2317
az() { echo '{}'; }
# shellcheck disable=SC2329,SC2317
azd() { printf '%s\n' "${test_output}"; }
# shellcheck disable=SC2329,SC2317
detect_linux_family() { echo ubuntu; }

for test_output in 'azd version 1.31.1 (commit abc)' 'azd version 1.32.0 (commit abc)' 'azd version 1.100.0 (commit abc)'; do
    ( source "${ROOT_DIR}/scripts/modules/azure/install.sh" ) >/dev/null
done
for test_output in 'azd version 1.9.0 (commit 1.31.1)' 'azd version 1.31.10-preview (commit abc)' 'unrecognized output 1.31.1'; do
    if ( source "${ROOT_DIR}/scripts/modules/azure/install.sh" ) >/dev/null 2>&1; then
        echo "Azure module accepted: ${test_output}" >&2
        exit 1
    fi
done
