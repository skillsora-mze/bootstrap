#!/usr/bin/env bash

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux) echo "linux" ;;
        *) echo "unsupported" ;;
    esac
}

detect_architecture() {
    case "$(uname -m)" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "unknown" ;;
    esac
}

detect_linux_distribution() {
    [[ -f /etc/os-release ]] || { echo "unknown"; return; }
    # shellcheck disable=SC1091
    source /etc/os-release
    case "${ID:-}" in
        debian) echo "debian" ;;
        *) echo "unknown" ;;
    esac
}

detect_linux_version_id() {
    [[ -f /etc/os-release ]] || { echo "unknown"; return; }
    # shellcheck disable=SC1091
    source /etc/os-release
    echo "${VERSION_ID:-unknown}"
}

detect_macos_major() {
    sw_vers -productVersion 2>/dev/null | awk -F. '{print $1}'
}

validate_supported_platform() {
    local os="$1"
    local arch="$2"

    case "${arch}" in
        amd64|arm64) ;;
        *) log_error "Unsupported architecture: ${arch}"; return 1 ;;
    esac

    case "${os}" in
        macos)
            [[ "${arch}" == "arm64" ]] || { log_error "Supported macOS architecture: Apple Silicon (arm64) only"; return 1; }
            local major
            major="$(detect_macos_major)"
            [[ "${major}" =~ ^[0-9]+$ ]] || { log_error "Unable to determine macOS version"; return 1; }
            (( major >= 14 )) || { log_error "macOS 14 or newer is required for OrbStack"; return 1; }
            ;;
        linux)
            local distro version
            distro="$(detect_linux_distribution)"
            version="$(detect_linux_version_id)"
            [[ "${distro}" == "debian" ]] || { log_error "Supported Linux distribution: Debian only"; return 1; }
            [[ "${version}" == "12" ]] || { log_error "Supported Debian version: 12 (detected: ${version})"; return 1; }
            ;;
        *) log_error "Unsupported operating system: ${os}"; return 1 ;;
    esac
}
