#!/usr/bin/env bash

log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_warning() {
    echo "[WARNING] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_section() {
    echo
    echo "========================================="
    echo "$*"
    echo "========================================="
}
