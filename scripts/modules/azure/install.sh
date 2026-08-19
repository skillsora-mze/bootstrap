#!/usr/bin/env bash
set -euo pipefail

log_info "Configuring Microsoft Azure tooling"

install_azure_cli_debian() {
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings

    local tmp_dir key_file
    tmp_dir="$(with_temp_dir)"
    key_file="${tmp_dir}/microsoft.asc"
    download_file "https://packages.microsoft.com/keys/microsoft.asc" "${key_file}"
    gpg --dearmor < "${key_file}" > "${tmp_dir}/microsoft.gpg"
    sudo install -m 0644 "${tmp_dir}/microsoft.gpg" /etc/apt/keyrings/microsoft.gpg

    local codename
    codename="$(lsb_release -cs)"
    sudo tee /etc/apt/sources.list.d/azure-cli.sources >/dev/null <<EOF2
Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${codename}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg
EOF2

    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y azure-cli
    rm -rf "${tmp_dir}"
}

install_azd_debian() {
    local tmp_dir asset expected
    tmp_dir="$(with_temp_dir)"
    case "${ARCH}" in
        amd64)
            asset="azd_${AZD_VERSION}_amd64.deb"
            expected="${AZD_SHA256_AMD64}"
            download_file "https://github.com/Azure/azure-dev/releases/download/azure-dev-cli_${AZD_VERSION}/${asset}" "${tmp_dir}/${asset}"
            sha256_verify "${tmp_dir}/${asset}" "${expected}"
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${tmp_dir}/${asset}"
            ;;
        arm64)
            asset="azd-linux-arm64.tar.gz"
            expected="${AZD_SHA256_ARM64}"
            download_file "https://github.com/Azure/azure-dev/releases/download/azure-dev-cli_${AZD_VERSION}/${asset}" "${tmp_dir}/${asset}"
            sha256_verify "${tmp_dir}/${asset}" "${expected}"
            tar -xzf "${tmp_dir}/${asset}" -C "${tmp_dir}"
            [[ -f "${tmp_dir}/azd" ]] || { log_error "azd binary missing from release archive"; exit 1; }
            sudo install -m 0755 "${tmp_dir}/azd" /usr/local/bin/azd
            ;;
        *) log_error "Unsupported architecture for azd: ${ARCH}"; exit 1 ;;
    esac
    rm -rf "${tmp_dir}"
}

case "${OS}" in
    linux)
        command -v az >/dev/null 2>&1 || install_azure_cli_debian
        command -v azd >/dev/null 2>&1 || install_azd_debian
        ;;
    macos)
        command -v brew >/dev/null 2>&1 || {
            log_error "Homebrew is required to install Azure tooling. Enable the system_packages module first on a clean Mac."
            exit 1
        }
        command -v az >/dev/null 2>&1 || brew install azure-cli
        command -v azd >/dev/null 2>&1 || brew install azd
        ;;
esac

command -v az >/dev/null 2>&1 || { log_error "Azure CLI not found"; exit 1; }
command -v azd >/dev/null 2>&1 || { log_error "Azure Developer CLI not found"; exit 1; }

az version | head -n 8
azd_output="$(azd version)"
printf '%s\n' "${azd_output}"
if [[ "${OS}" == "linux" ]]; then
    printf '%s\n' "${azd_output}" | grep -Fq "${AZD_VERSION}" || { log_error "azd version mismatch: expected ${AZD_VERSION}; automatic downgrade is not performed"; exit 1; }
fi
log_success "Azure tooling validated"
