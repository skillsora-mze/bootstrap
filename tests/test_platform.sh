#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/platform.sh"

detect_linux_distribution() { echo debian; }
detect_linux_version_id() { echo 12; }
validate_supported_platform linux amd64
validate_supported_platform linux arm64

if validate_supported_platform linux unknown >/dev/null 2>&1; then
    echo "Unknown architecture should fail" >&2
    exit 1
fi

detect_macos_major() { echo 14; }
validate_supported_platform macos arm64
if validate_supported_platform macos amd64 >/dev/null 2>&1; then
    echo "Intel macOS should fail" >&2
    exit 1
fi
