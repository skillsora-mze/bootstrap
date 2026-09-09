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

# Read release metadata in a subshell so distro variables never leak to callers.
linux_release_value() (
    local field="$1"
    unset ID ID_LIKE VERSION_ID VERSION_CODENAME UBUNTU_CODENAME VARIANT_ID
    [[ -f "${OS_RELEASE_FILE:-/etc/os-release}" ]] || return 0
    # shellcheck disable=SC1090
    source "${OS_RELEASE_FILE:-/etc/os-release}"
    printf '%s\n' "${!field:-}"
)

detect_linux_distribution() {
    local id
    id="$(linux_release_value ID)"
    echo "${id:-unknown}"
}

detect_linux_version_id() {
    local version
    version="$(linux_release_value VERSION_ID)"
    echo "${version:-unknown}"
}

detect_linux_family() {
    local id like
    id="$(detect_linux_distribution)"
    like=" $(linux_release_value ID_LIKE) "
    case "${id}" in
        debian|ubuntu|fedora) echo "${id}" ;;
        opensuse|opensuse-leap|opensuse-tumbleweed) echo opensuse ;;
        *)
            if [[ "${like}" == *" ubuntu "* ]]; then echo ubuntu
            elif [[ "${like}" == *" debian "* ]]; then echo debian
            else echo unknown
            fi
            ;;
    esac
}

linux_repository_codename() {
    local codename
    if [[ "$(detect_linux_family)" == ubuntu ]]; then
        codename="$(linux_release_value UBUNTU_CODENAME)"
    fi
    codename="${LINUX_BASE_CODENAME:-${codename:-$(linux_release_value VERSION_CODENAME)}}"
    [[ "${codename}" =~ ^[a-z][a-z0-9]*$ ]] || {
        log_error "Cannot determine base repository codename; set LINUX_BASE_CODENAME explicitly"
        return 1
    }
    echo "${codename}"
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
            (( major >= 14 )) || { log_error "macOS 14 or newer is required"; return 1; }
            ;;
        linux)
            local distro version family
            distro="$(detect_linux_distribution)"
            version="$(detect_linux_version_id)"
            family="$(detect_linux_family)"
            [[ "${family}" != unknown ]] || {
                log_error "Unsupported Linux distribution: ${distro}. Supported families: Debian (11+), Ubuntu, Fedora and openSUSE Leap/Tumbleweed."
                return 1
            }
            if [[ "${distro}" == debian ]]; then
                if [[ ! "${version}" =~ ^[0-9]+([.][0-9]+)*$ ]] || (( 10#${version%%.*} < 11 )); then
                    log_error "Debian 11 or newer is required (detected: ${version})"
                    return 1
                fi
            fi
            local manager
            manager="$(linux_package_manager)" || return 1
            command -v "${manager}" >/dev/null 2>&1 || { log_error "${manager} is required for ${distro}"; return 1; }
            if [[ "${manager}" == apt-get ]]; then
                linux_repository_codename >/dev/null || return 1
            fi
            if [[ -e /run/ostree-booted ]] || [[ "$(linux_release_value VARIANT_ID)" =~ ^(silverblue|kinoite|sericea|onyx|coreos)$ ]]; then
                log_error "Immutable Linux editions require a separate installer"
                return 1
            fi
            ;;
        *) log_error "Unsupported operating system: ${os}"; return 1 ;;
    esac
}

linux_package_manager() {
    case "$(detect_linux_family)" in
        debian|ubuntu) echo apt-get ;;
        fedora) echo dnf ;;
        opensuse) echo zypper ;;
        *) log_error "No supported Linux package manager"; return 1 ;;
    esac
}

linux_refresh_packages() {
    case "$(linux_package_manager)" in
        apt-get) sudo apt-get update ;;
        dnf) sudo dnf -y makecache ;;
        zypper) sudo zypper --non-interactive refresh ;;
        *) return 1 ;;
    esac
}

linux_install_packages() {
    case "$(linux_package_manager)" in
        apt-get) sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
        dnf) sudo dnf install -y "$@" ;;
        zypper) sudo zypper --non-interactive install --no-recommends "$@" ;;
        *) return 1 ;;
    esac
}
