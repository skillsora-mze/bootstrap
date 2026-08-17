#!/usr/bin/env bash
set -euo pipefail

log_info "Configuring Kubernetes tooling"

install_kubectl_debian() {
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings

    local tmp_dir key_file
    tmp_dir="$(with_temp_dir)"
    key_file="${tmp_dir}/kubernetes-release.key"
    download_file "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/Release.key" "${key_file}"
    gpg --dearmor < "${key_file}" > "${tmp_dir}/kubernetes.gpg"
    sudo install -m 0644 "${tmp_dir}/kubernetes.gpg" /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/ /" \
        | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y kubectl
    rm -rf "${tmp_dir}"
}

install_helm_linux() {
    local tmp_dir archive checksum_file platform checksum
    tmp_dir="$(with_temp_dir)"
    platform="linux-${ARCH}"
    archive="helm-${HELM_VERSION}-${platform}.tar.gz"

    download_file "https://get.helm.sh/${archive}" "${tmp_dir}/${archive}"
    checksum_file="${tmp_dir}/${archive}.sha256sum"
    download_file "https://get.helm.sh/${archive}.sha256sum" "${checksum_file}"
    checksum="$(awk '{print $1}' "${checksum_file}")"
    [[ "${checksum}" =~ ^[0-9a-fA-F]{64}$ ]] || { log_error "Invalid Helm checksum metadata"; exit 1; }
    sha256_verify "${tmp_dir}/${archive}" "${checksum}"

    tar -xzf "${tmp_dir}/${archive}" -C "${tmp_dir}"
    sudo install -m 0755 "${tmp_dir}/${platform}/helm" /usr/local/bin/helm
    rm -rf "${tmp_dir}"
}

install_kind_linux() {
    local tmp_dir binary
    tmp_dir="$(with_temp_dir)"
    binary="${tmp_dir}/kind"
    download_file "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}" "${binary}"
    chmod 0755 "${binary}"
    sudo install -m 0755 "${binary}" /usr/local/bin/kind
    rm -rf "${tmp_dir}"
}

install_k9s_linux() {
    local tmp_dir archive platform
    tmp_dir="$(with_temp_dir)"
    case "${ARCH}" in
        amd64) platform="amd64" ;;
        arm64) platform="arm64" ;;
        *) log_error "Unsupported architecture for k9s: ${ARCH}"; exit 1 ;;
    esac
    archive="k9s_Linux_${platform}.tar.gz"
    download_file "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/${archive}" "${tmp_dir}/${archive}"
    tar -xzf "${tmp_dir}/${archive}" -C "${tmp_dir}" k9s
    sudo install -m 0755 "${tmp_dir}/k9s" /usr/local/bin/k9s
    rm -rf "${tmp_dir}"
}


configure_helm_macos() {
    if brew list --versions helm >/dev/null 2>&1; then
        log_error "Homebrew Helm 4 is installed but this project standardizes on Helm 3 (${HELM_VERSION})."
        log_error "Remove it explicitly with: brew uninstall helm ; then rerun the bootstrap."
        exit 1
    fi
    if ! command -v helm >/dev/null 2>&1; then
        brew list --versions helm@3 >/dev/null 2>&1 || brew install helm@3
        brew link --force helm@3
    fi
    helm version --short | grep -q '^v3\.' || { log_error "Helm 3 is required"; exit 1; }
}

if [[ "${OS}" == "macos" ]]; then
    configure_helm_macos
fi

if [[ "${OS}" == "linux" ]]; then
    command -v kubectl >/dev/null 2>&1 || install_kubectl_debian
    command -v helm >/dev/null 2>&1 || install_helm_linux
    command -v kind >/dev/null 2>&1 || install_kind_linux
    command -v k9s >/dev/null 2>&1 || install_k9s_linux
    command -v kubectx >/dev/null 2>&1 || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y kubectx
fi

for cmd in kubectl helm kind k9s kubectx; do
    command -v "${cmd}" >/dev/null 2>&1 || { log_error "${cmd} not found"; exit 1; }
done

kubectl version --client
helm version --short
kind version
k9s version
kubectx --help >/dev/null
log_success "Kubernetes tooling validated"
