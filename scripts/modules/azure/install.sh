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
    # Microsoft currently publishes signed .deb releases through the official
    # azd installer workflow. Download first, then execute locally (no curl|bash).
    local tmp_dir installer
    tmp_dir="$(with_temp_dir)"
    installer="${tmp_dir}/install-azd.sh"
    download_file "https://aka.ms/install-azd.sh" "${installer}"
    bash "${installer}"
    rm -rf "${tmp_dir}"
}

if [[ "${OS}" == "linux" ]]; then
    command -v az >/dev/null 2>&1 || install_azure_cli_debian
    command -v azd >/dev/null 2>&1 || install_azd_debian
fi

command -v az >/dev/null 2>&1 || { log_error "Azure CLI not found"; exit 1; }
command -v azd >/dev/null 2>&1 || { log_error "Azure Developer CLI not found"; exit 1; }

az version | head -n 8
azd version
log_success "Azure tooling validated"
