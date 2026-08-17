#!/usr/bin/env bash

download_file() {
    local url="$1"
    local destination="$2"

    curl --fail --silent --show-error --location \
        --retry 3 --retry-delay 2 --retry-connrefused \
        "${url}" -o "${destination}"
}

sha256_verify() {
    local file="$1"
    local expected="$2"
    local actual

    if command -v sha256sum >/dev/null 2>&1; then
        actual="$(sha256sum "${file}" | awk '{print $1}')"
    else
        actual="$(shasum -a 256 "${file}" | awk '{print $1}')"
    fi

    [[ "${actual}" == "${expected}" ]] || {
        log_error "SHA-256 mismatch for ${file}"
        return 1
    }
}

with_temp_dir() {
    mktemp -d 2>/dev/null || mktemp -d -t workstation-bootstrap
}
