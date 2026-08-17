#!/usr/bin/env bash

set -euo pipefail

log_info "Installing system packages"

case "${OS}" in

    linux)

        "${ROOT_DIR}/scripts/linux/install-packages.sh"
        ;;

    macos)

        "${ROOT_DIR}/scripts/macos/install-packages.sh"
        ;;

    *)

        log_error "Unsupported operating system: ${OS}"
        exit 1
        ;;

esac
