#!/usr/bin/env bash
set -euo pipefail

log_info "Configuring AWS tooling"

detect_aws_cli_arch() {
    case "${ARCH}" in
        arm64) echo "aarch64" ;;
        amd64) echo "x86_64" ;;
        *) log_error "Unsupported architecture: ${ARCH}"; exit 1 ;;
    esac
}

detect_sam_cli_arch() {
    case "${ARCH}" in
        arm64) echo "arm64" ;;
        amd64) echo "x86_64" ;;
        *) log_error "Unsupported architecture: ${ARCH}"; exit 1 ;;
    esac
}

validate_zip() {
    local file="$1"
    file "${file}" | grep -qi 'zip archive' || { log_error "Invalid ZIP archive: ${file}"; exit 1; }
}

install_aws_cli_linux() {
    local tmp_dir archive
    tmp_dir="$(with_temp_dir)"
    archive="${tmp_dir}/awscliv2.zip"
    download_file "https://awscli.amazonaws.com/awscli-exe-linux-$(detect_aws_cli_arch).zip" "${archive}"
    validate_zip "${archive}"
    unzip -q "${archive}" -d "${tmp_dir}"
    sudo "${tmp_dir}/aws/install" --update
    rm -rf "${tmp_dir}"
}

install_sam_cli_linux() {
    local tmp_dir archive sam_arch expected_sha
    tmp_dir="$(with_temp_dir)"
    archive="${tmp_dir}/aws-sam-cli.zip"
    sam_arch="$(detect_sam_cli_arch)"
    case "${ARCH}" in
        amd64) expected_sha="${SAM_CLI_SHA256_AMD64}" ;;
        arm64) expected_sha="${SAM_CLI_SHA256_ARM64}" ;;
    esac
    download_file "https://github.com/aws/aws-sam-cli/releases/download/${SAM_CLI_VERSION}/aws-sam-cli-linux-${sam_arch}.zip" "${archive}"
    sha256_verify "${archive}" "${expected_sha}"
    validate_zip "${archive}"
    mkdir -p "${tmp_dir}/sam"
    unzip -q "${archive}" -d "${tmp_dir}/sam"
    sudo "${tmp_dir}/sam/install" --update
    rm -rf "${tmp_dir}"
}

install_sam_cli_macos() {
    local tmp_dir package
    tmp_dir="$(with_temp_dir)"
    package="${tmp_dir}/aws-sam-cli-macos-arm64.pkg"
    download_file "https://github.com/aws/aws-sam-cli/releases/download/${SAM_CLI_VERSION}/aws-sam-cli-macos-arm64.pkg" "${package}"
    sha256_verify "${package}" "${SAM_CLI_SHA256_MACOS_ARM64}"
    sudo installer -pkg "${package}" -target /
    rm -rf "${tmp_dir}"
}

case "${OS}" in
    linux)
        command -v aws >/dev/null 2>&1 || install_aws_cli_linux
        command -v sam >/dev/null 2>&1 || install_sam_cli_linux
        ;;
    macos)
        if brew list --versions aws-sam-cli >/dev/null 2>&1; then
            log_warning "AWS SAM CLI is installed through Homebrew. Clean installs use the AWS first-party package installer."
        fi
        command -v sam >/dev/null 2>&1 || install_sam_cli_macos
        ;;
esac

command -v aws >/dev/null 2>&1 || { log_error "AWS CLI not found"; exit 1; }
command -v sam >/dev/null 2>&1 || { log_error "AWS SAM CLI not found"; exit 1; }

aws --version
sam_output="$(sam --version)"
printf '%s\n' "${sam_output}"
expected_sam="${SAM_CLI_VERSION#v}"
printf '%s\n' "${sam_output}" | grep -q "${expected_sam}" || { log_error "AWS SAM CLI version mismatch: expected ${expected_sam}"; exit 1; }
log_success "AWS tooling validated"
