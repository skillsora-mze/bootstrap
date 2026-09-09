#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/platform.sh"
source "${ROOT_DIR}/scripts/lib/download.sh"

ARCH="${ARCH:-$(detect_architecture)}"

install_uv_linux() {
    local tmp_dir archive platform expected

    tmp_dir="$(with_temp_dir)"

    case "${ARCH}" in
        amd64)
            platform="x86_64-unknown-linux-gnu"
            expected="${UV_SHA256_AMD64}"
            ;;
        arm64)
            platform="aarch64-unknown-linux-gnu"
            expected="${UV_SHA256_ARM64}"
            ;;
        *)
            log_error "Unsupported architecture for uv: ${ARCH}"
            exit 1
            ;;
    esac

    archive="uv-${platform}.tar.gz"

    download_file         "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${archive}"         "${tmp_dir}/${archive}"

    sha256_verify "${tmp_dir}/${archive}" "${expected}"

    tar -xzf "${tmp_dir}/${archive}" -C "${tmp_dir}"

    sudo install -m 0755 "${tmp_dir}/uv-${platform}/uv" /usr/local/bin/uv
    sudo install -m 0755 "${tmp_dir}/uv-${platform}/uvx" /usr/local/bin/uvx

    rm -rf "${tmp_dir}"
}

install_yq_linux() {
    local tmp_dir asset expected

    tmp_dir="$(with_temp_dir)"

    case "${ARCH}" in
        amd64)
            asset="yq_linux_amd64"
            expected="${YQ_SHA256_AMD64}"
            ;;
        arm64)
            asset="yq_linux_arm64"
            expected="${YQ_SHA256_ARM64}"
            ;;
        *)
            log_error "Unsupported architecture for yq: ${ARCH}"
            exit 1
            ;;
    esac

    download_file         "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${asset}"         "${tmp_dir}/${asset}"

    sha256_verify "${tmp_dir}/${asset}" "${expected}"

    sudo install -m 0755 "${tmp_dir}/${asset}" /usr/local/bin/yq

    rm -rf "${tmp_dir}"
}

install_starship_linux() {
    local tmp_dir archive platform expected

    tmp_dir="$(with_temp_dir)"

    case "${ARCH}" in
        amd64)
            platform="x86_64-unknown-linux-gnu"
            expected="${STARSHIP_SHA256_AMD64}"
            ;;
        arm64)
            platform="aarch64-unknown-linux-musl"
            expected="${STARSHIP_SHA256_ARM64}"
            ;;
        *)
            log_error "Unsupported architecture for starship: ${ARCH}"
            exit 1
            ;;
    esac

    archive="starship-${platform}.tar.gz"

    download_file         "https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/${archive}"         "${tmp_dir}/${archive}"

    sha256_verify "${tmp_dir}/${archive}" "${expected}"

    tar -xzf "${tmp_dir}/${archive}" -C "${tmp_dir}" starship
    sudo install -m 0755 "${tmp_dir}/starship" /usr/local/bin/starship

    rm -rf "${tmp_dir}"
}

DISTRO="$(detect_linux_distribution)"
validate_supported_platform linux "${ARCH}"

FAMILY="$(detect_linux_family)"
[[ "${FAMILY}" != ubuntu ]] || FAMILY=debian
PACKAGE_FILE="${ROOT_DIR}/packages/${FAMILY}/packages.txt"
[[ -f "${PACKAGE_FILE}" ]] || { log_error "Package file not found: ${PACKAGE_FILE}"; exit 1; }

log_section "Installing ${DISTRO} system packages"
linux_refresh_packages

# Debian 11 does not ship gh in its default repositories.
if [[ "${FAMILY}" == debian ]] && ! apt-cache policy gh | awk '/Candidate:/ { if ($2 != "(none)") found=1 } END { exit !found }'; then
    sudo apt-get install -y ca-certificates curl
    key_dir="$(with_temp_dir)"
    download_file "https://cli.github.com/packages/githubcli-archive-keyring.gpg" "${key_dir}/githubcli.gpg"
    sudo install -d -m 0755 /etc/apt/keyrings
    sudo install -m 0644 "${key_dir}/githubcli.gpg" /etc/apt/keyrings/githubcli.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    rm -rf "${key_dir}"
    sudo apt-get update
fi

packages=()
while IFS= read -r package; do
    [[ -z "${package}" || "${package}" =~ ^[[:space:]]*# ]] && continue
    packages+=("${package}")
done < "${PACKAGE_FILE}"

if ((${#packages[@]})); then
    linux_install_packages "${packages[@]}"
fi

if ! command -v uv >/dev/null 2>&1 || [[ "$(uv --version | awk '{print $2}')" != "${UV_VERSION#v}" ]]; then
    install_uv_linux
fi

if ! command -v yq >/dev/null 2>&1 || [[ "$(yq --version | awk '{print $NF}')" != "${YQ_VERSION}" ]]; then
    install_yq_linux
fi

if ! command -v starship >/dev/null 2>&1 || [[ "$(starship --version | awk 'NR == 1 {print $2}')" != "${STARSHIP_VERSION#v}" ]]; then
    install_starship_linux
fi

command -v uv >/dev/null 2>&1 || { log_error "uv not found"; exit 1; }
command -v yq >/dev/null 2>&1 || { log_error "yq not found"; exit 1; }
command -v starship >/dev/null 2>&1 || { log_error "starship not found"; exit 1; }

[[ "$(uv --version | awk '{print $2}')" == "${UV_VERSION#v}" ]] || {
    log_error "uv version mismatch: expected ${UV_VERSION}"
    exit 1
}

[[ "$(yq --version | awk '{print $NF}')" == "${YQ_VERSION}" ]] || {
    log_error "yq version mismatch: expected ${YQ_VERSION}"
    exit 1
}

[[ "$(starship --version | awk 'NR == 1 {print $2}')" == "${STARSHIP_VERSION#v}" ]] || {
    log_error "starship version mismatch: expected ${STARSHIP_VERSION}"
    exit 1
}

log_success "${DISTRO} system packages installation completed"
