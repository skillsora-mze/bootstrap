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
    codename="$(linux_repository_codename)"
    echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${codename} main" \
        | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    sudo apt-get update
    rm -rf "${tmp_dir}"
}

install_hashicorp_binary_linux() {
    local product="$1" version_name version checksum_name checksum tmp_dir asset
    version_name="$(printf '%s' "${product}" | tr '[:lower:]' '[:upper:]')_VERSION"
    checksum_name="$(printf '%s' "${product}" | tr '[:lower:]' '[:upper:]')_SHA256_$(printf '%s' "${ARCH}" | tr '[:lower:]' '[:upper:]')"
    version="${!version_name}"
    checksum="${!checksum_name}"
    tmp_dir="$(with_temp_dir)"
    asset="${product}_${version}_linux_${ARCH}.zip"
    download_file "https://releases.hashicorp.com/${product}/${version}/${asset}" "${tmp_dir}/${asset}"
    sha256_verify "${tmp_dir}/${asset}" "${checksum}"
    unzip -q "${tmp_dir}/${asset}" -d "${tmp_dir}"
    sudo install -m 0755 "${tmp_dir}/${product}" "/usr/local/bin/${product}"
    rm -rf "${tmp_dir}"
}

install_vagrant_opensuse() {
    local tmp_dir asset
    tmp_dir="$(with_temp_dir)"
    asset="vagrant-${VAGRANT_VERSION}-1.x86_64.rpm"
    download_file "https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/${asset}" "${tmp_dir}/${asset}"
    sha256_verify "${tmp_dir}/${asset}" "${VAGRANT_RPM_SHA256_AMD64}"
    # Import HashiCorp's signing key before asking zypper to verify the RPM.
    download_file "https://www.hashicorp.com/.well-known/pgp-key.txt" "${tmp_dir}/hashicorp.asc"
    sudo rpm --import "${tmp_dir}/hashicorp.asc"
    linux_install_packages "${tmp_dir}/${asset}"
    rm -rf "${tmp_dir}"
}

case "${OS}" in
    linux)
        if [[ "$(detect_linux_family)" == opensuse && "${ARCH}" == arm64 ]] && ! command -v vagrant >/dev/null 2>&1; then
            log_error "Vagrant has no official Linux ARM64 RPM. On openSUSE ARM64, install Vagrant yourself or deselect the hashicorp module."
            exit 1
        fi
        case "$(detect_linux_family)" in
            debian|ubuntu)
                if ! command -v terraform >/dev/null 2>&1 || ! command -v packer >/dev/null 2>&1 || ! command -v vagrant >/dev/null 2>&1; then
                    install_hashicorp_repository_debian
                    linux_install_packages terraform packer vagrant
                fi
                ;;
            fedora|opensuse)
                command -v terraform >/dev/null 2>&1 || install_hashicorp_binary_linux terraform
                command -v packer >/dev/null 2>&1 || install_hashicorp_binary_linux packer
                if ! command -v vagrant >/dev/null 2>&1; then
                    linux_refresh_packages
                    if [[ "$(detect_linux_family)" == opensuse ]]; then
                        install_vagrant_opensuse
                    else
                        linux_install_packages vagrant
                    fi
                fi
                ;;
        esac
        command -v ansible >/dev/null 2>&1 || linux_install_packages ansible
        ;;
    macos)
        command -v brew >/dev/null 2>&1 || {
            log_error "Homebrew is required to install HashiCorp tooling. Enable the system_packages module first on a clean Mac."
            exit 1
        }
        brew tap hashicorp/tap

        command -v terraform >/dev/null 2>&1 || brew install hashicorp/tap/terraform
        command -v packer >/dev/null 2>&1 || brew install hashicorp/tap/packer
        command -v ansible >/dev/null 2>&1 || brew install ansible
        command -v vagrant >/dev/null 2>&1 || brew install hashicorp/tap/hashicorp-vagrant
        ;;
esac

for cmd in terraform packer ansible vagrant; do
    command -v "${cmd}" >/dev/null 2>&1 || { log_error "${cmd} not found"; exit 1; }
done

terraform version
packer version
ansible --version | head -n 1
vagrant --version
log_success "HashiCorp tooling validated"
