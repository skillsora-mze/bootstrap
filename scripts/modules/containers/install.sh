#!/usr/bin/env bash
set -euo pipefail

log_info "Configuring container runtime"

install_docker_engine_debian() {
    log_info "Configuring Docker Engine official APT repository"

    local conflict
    for conflict in docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc; do
        if dpkg -s "${conflict}" >/dev/null 2>&1; then
            log_error "Conflicting package detected: ${conflict}"
            log_error "Remove conflicting container packages explicitly before running the bootstrap."
            exit 1
        fi
    done

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings

    local tmp_dir key_file
    tmp_dir="$(with_temp_dir)"
    key_file="${tmp_dir}/docker.asc"
    download_file "https://download.docker.com/linux/debian/gpg" "${key_file}"
    sudo install -m 0644 "${key_file}" /etc/apt/keyrings/docker.asc

    local codename
    # shellcheck disable=SC1091
    codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
    sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF2
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${codename}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF2

    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    rm -rf "${tmp_dir}"
}

configure_linux_user() {
    getent group docker >/dev/null 2>&1 || return 0
    if ! id -nG "${USER}" | tr ' ' '\n' | grep -qx docker; then
        log_info "Adding ${USER} to docker group (effective after a new login session)"
        sudo usermod -aG docker "${USER}"
    fi
}

ensure_colima_macos() {
    command -v brew >/dev/null 2>&1 || {
        log_error "Homebrew is required. Enable the system_packages module first on a clean Mac."
        exit 1
    }

    command -v colima >/dev/null 2>&1 || {
        log_error "Colima is not installed. Enable the system_packages module."
        exit 1
    }

    command -v docker >/dev/null 2>&1 || {
        log_error "Docker CLI is not installed. Enable the system_packages module."
        exit 1
    }

    if ! colima status >/dev/null 2>&1; then
        log_info "Starting Colima"
        colima start
    else
        log_info "Colima already running"
    fi

    local elapsed=0
    local timeout=120

    until docker info >/dev/null 2>&1; do
        if (( elapsed >= timeout )); then
            log_error "Colima Docker engine did not become ready"
            colima status || true
            exit 1
        fi

        sleep 3
        elapsed=$((elapsed + 3))
    done
}


case "${OS}" in
    macos)
        ensure_colima_macos
        ;;
    linux)
        if dpkg -s docker-ce >/dev/null 2>&1; then
            log_info "Docker Engine CE already installed"
            sudo systemctl enable --now docker
        else
            install_docker_engine_debian
        fi
        configure_linux_user
        if ! docker info >/dev/null 2>&1 && ! sudo docker info >/dev/null 2>&1; then
            log_error "Docker Engine is not reachable"
            exit 1
        fi
        ;;
    *)
        log_error "Unsupported operating system: ${OS}"
        exit 1
        ;;
esac

docker --version
docker compose version
log_success "Container runtime validated"
