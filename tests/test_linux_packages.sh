#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/platform.sh"
source "${ROOT_DIR}/scripts/lib/log.sh"
# Record complete argument boundaries without invoking a real package manager.
sudo() { printf '<%s>' "$@"; }
for family in debian ubuntu fedora opensuse; do
    detect_linux_family() { echo "${family}"; }
    case "${family}" in
        debian|ubuntu)
            refresh='<apt-get><update>'
            install='<DEBIAN_FRONTEND=noninteractive><apt-get><install><-y><git></tmp/a package.rpm>'
            ;;
        fedora)
            refresh='<dnf><-y><makecache>'
            install='<dnf><install><-y><git></tmp/a package.rpm>'
            ;;
        opensuse)
            refresh='<zypper><--non-interactive><refresh>'
            install='<zypper><--non-interactive><install><--no-recommends><git></tmp/a package.rpm>'
            ;;
    esac
    [[ "$(linux_refresh_packages)" == "${refresh}" ]]
    [[ "$(linux_install_packages git '/tmp/a package.rpm')" == "${install}" ]]
done
# A failed package operation must propagate to the module/strict-mode caller.
sudo() { return 42; }
if linux_install_packages git; then exit 1; else [[ "$?" == 42 ]]; fi
