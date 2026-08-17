#!/usr/bin/env bash
set -euo pipefail

log_info "Configuring HashiCorp tooling"

install_hashicorp_repository_debian() {
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings

    local tmp_dir key_file
    tmp_dir="$(with_temp_dir)"
    key_file="${tmp_dir}/hashicorp.asc"
    download_file "https://apt.releases.hashicorp.com/gpg" "${key_file}"
    gpg --dearmor < "${key_file}" > "${tmp_dir}/hashicorp.gpg"
    sudo install -m 0644 "${tmp_dir}/hashicorp.gpg" /etc/apt/keyrings/hashicorp-archive-keyring.gpg

    local codename
    codename="$(lsb_release -cs)"
    echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${codename} main" \
        | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    sudo apt-get update
    rm -rf "${tmp_dir}"
}

if [[ "${OS}" == "linux" ]]; then
    if ! command -v terraform >/dev/null 2>&1 || ! command -v packer >/dev/null 2>&1 || ! command -v vagrant >/dev/null 2>&1; then
        install_hashicorp_repository_debian
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y terraform packer vagrant
    fi
    command -v ansible >/dev/null 2>&1 || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ansible
fi

for cmd in terraform packer ansible vagrant; do
    command -v "${cmd}" >/dev/null 2>&1 || { log_error "${cmd} not found"; exit 1; }
done

terraform version
packer version
ansible --version | head -n 1
vagrant --version
log_success "HashiCorp tooling validated"
