#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/platform.sh"
fixture="$(mktemp)"
trap 'rm -f "${fixture}"' EXIT
export OS_RELEASE_FILE="${fixture}"
# These stubs test command detection only; no sudo invocation uses them.
# shellcheck disable=SC2032
apt-get() { :; }
# shellcheck disable=SC2032
dnf() { :; }
# shellcheck disable=SC2032
zypper() { :; }

for version in 11 12 13 14; do
    printf 'ID=debian\nVERSION_ID=%s\nVERSION_CODENAME=trixie\n' "${version}" > "${fixture}"
    validate_supported_platform linux amd64
    validate_supported_platform linux arm64
done
for id in ubuntu linuxmint pop; do
    printf 'ID=%s\nID_LIKE="ubuntu debian"\nVERSION_ID=24.04\nVERSION_CODENAME=wilma\nUBUNTU_CODENAME=noble\n' "${id}" > "${fixture}"
    validate_supported_platform linux amd64
    [[ "$(detect_linux_distribution)" == "${id}" ]]
    [[ "$(detect_linux_family)" == ubuntu ]]
    [[ "$(linux_repository_codename)" == noble ]]
done
for id in fedora opensuse opensuse-leap opensuse-tumbleweed; do
    printf 'ID=%s\n' "${id}" > "${fixture}"
    validate_supported_platform linux amd64
    validate_supported_platform linux arm64
    case "${id}" in
        fedora) [[ "$(linux_package_manager)" == dnf ]] ;;
        *) [[ "$(linux_package_manager)" == zypper ]] ;;
    esac
done
printf 'ID=fedora\nVARIANT_ID=silverblue\n' > "${fixture}"
if validate_supported_platform linux amd64; then exit 1; fi
printf 'ID=debian\nVERSION_ID=10\nVERSION_CODENAME=buster\n' > "${fixture}"
if validate_supported_platform linux amd64; then exit 1; fi
for id in arch alpine opensuse-microos rhel unknown; do
    printf 'ID=%s\n' "${id}" > "${fixture}"
    if validate_supported_platform linux amd64; then exit 1; fi
done
# Reject a recognized distro if its native package manager is missing.
for id in fedora opensuse-tumbleweed; do
    printf 'ID=%s\n' "${id}" > "${fixture}"
    (
        # Invoked indirectly by validate_supported_platform.
        # shellcheck disable=SC2329
        command() {
            if [[ "$1" == -v && ( "$2" == dnf || "$2" == zypper ) ]]; then return 1; fi
            builtin command "$@"
        }
        if validate_supported_platform linux amd64 >/dev/null 2>&1; then exit 1; fi
    )
done
printf 'ID=kali\nID_LIKE=debian\n' > "${fixture}"
if validate_supported_platform linux amd64; then exit 1; fi
LINUX_BASE_CODENAME=trixie validate_supported_platform linux amd64
[[ "$(linux_release_value UBUNTU_CODENAME)" == "" ]]
if validate_supported_platform linux unknown >/dev/null 2>&1; then exit 1; fi
detect_macos_major() { echo 14; }
validate_supported_platform macos arm64
if validate_supported_platform macos amd64 >/dev/null 2>&1; then exit 1; fi
