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
    local tmp_dir binary checksum_file checksum asset
    tmp_dir="$(with_temp_dir)"
    asset="kind-linux-${ARCH}"
    binary="${tmp_dir}/kind"
    checksum_file="${tmp_dir}/${asset}.sha256sum"

    download_file "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/${asset}" "${binary}"
    download_file "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/${asset}.sha256sum" "${checksum_file}"
    checksum="$(awk '{print $1}' "${checksum_file}")"
    [[ "${checksum}" =~ ^[0-9a-fA-F]{64}$ ]] || { log_error "Invalid kind checksum metadata"; exit 1; }
    sha256_verify "${binary}" "${checksum}"

    chmod 0755 "${binary}"
    sudo install -m 0755 "${binary}" /usr/local/bin/kind
    rm -rf "${tmp_dir}"
}

install_k9s_linux() {
    local tmp_dir archive platform checksum_file checksum
    tmp_dir="$(with_temp_dir)"
    case "${ARCH}" in
        amd64) platform="amd64" ;;
        arm64) platform="arm64" ;;
        *) log_error "Unsupported architecture for k9s: ${ARCH}"; exit 1 ;;
    esac
    archive="k9s_Linux_${platform}.tar.gz"
    checksum_file="${tmp_dir}/checksums.sha256"

    download_file "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/${archive}" "${tmp_dir}/${archive}"
    download_file "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/checksums.sha256" "${checksum_file}"
    checksum="$(awk -v asset="${archive}" '$2 == asset || $2 == "*" asset { print $1; exit }' "${checksum_file}")"
    [[ "${checksum}" =~ ^[0-9a-fA-F]{64}$ ]] || { log_error "Checksum for ${archive} not found in k9s release metadata"; exit 1; }
    sha256_verify "${tmp_dir}/${archive}" "${checksum}"

    tar -xzf "${tmp_dir}/${archive}" -C "${tmp_dir}" k9s
    sudo install -m 0755 "${tmp_dir}/k9s" /usr/local/bin/k9s
    rm -rf "${tmp_dir}"
}

configure_kubernetes_macos() {
    command -v brew >/dev/null 2>&1 || {
        log_error "Homebrew is required to install Kubernetes tooling. Enable the system_packages module first on a clean Mac."
        exit 1
    }

    command -v kubectl >/dev/null 2>&1 || brew install kubectl
    command -v kind >/dev/null 2>&1 || brew install kind
    command -v k9s >/dev/null 2>&1 || brew install k9s
    command -v kubectx >/dev/null 2>&1 || brew install kubectx

    if brew list --versions helm >/dev/null 2>&1; then
        log_error "Homebrew Helm 4 is installed but this project standardizes on Helm 3."
        log_error "Remove it explicitly with: brew uninstall helm ; then rerun the bootstrap."
        exit 1
    fi
    if ! command -v helm >/dev/null 2>&1; then
        brew list --versions helm@3 >/dev/null 2>&1 || brew install helm@3
        brew link --force helm@3
    fi
    helm version --short | grep -q '^v3\.' || { log_error "Helm 3 is required"; exit 1; }
}

case "${OS}" in
    macos)
        configure_kubernetes_macos
        ;;
    linux)
        command -v kubectl >/dev/null 2>&1 || install_kubectl_debian
        command -v helm >/dev/null 2>&1 || install_helm_linux
        command -v kind >/dev/null 2>&1 || install_kind_linux
        command -v k9s >/dev/null 2>&1 || install_k9s_linux
        command -v kubectx >/dev/null 2>&1 || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y kubectx
        ;;
esac

for cmd in kubectl helm kind k9s kubectx; do
    command -v "${cmd}" >/dev/null 2>&1 || { log_error "${cmd} not found"; exit 1; }
done

kubectl_output="$(kubectl version --client --output=json | tr -d '[:space:]')"
printf '%s\n' "${kubectl_output}"

helm_output="$(helm version --short)"
printf '%s\n' "${helm_output}"

kind_output="$(kind version)"
printf '%s\n' "${kind_output}"

k9s_output="$(k9s version)"
printf '%s\n' "${k9s_output}"

if [[ "${OS}" == "linux" ]]; then
    printf '%s\n' "${kubectl_output}" | grep -q "\"gitVersion\":\"${KUBERNETES_MINOR}\." || { log_error "kubectl minor-version mismatch: expected ${KUBERNETES_MINOR}.x"; exit 1; }
    printf '%s\n' "${helm_output}" | grep -q "^${HELM_VERSION}" || { log_error "Helm version mismatch: expected ${HELM_VERSION}"; exit 1; }
    printf '%s\n' "${kind_output}" | grep -q "${KIND_VERSION#v}" || { log_error "kind version mismatch: expected ${KIND_VERSION}"; exit 1; }
    printf '%s\n' "${k9s_output}" | grep -q "${K9S_VERSION#v}" || { log_error "k9s version mismatch: expected ${K9S_VERSION}"; exit 1; }
else
    printf '%s\n' "${helm_output}" | grep -q '^v3\.' || { log_error "Helm 3 is required on macOS"; exit 1; }
fi

kubectx --help >/dev/null
log_success "Kubernetes tooling validated"
