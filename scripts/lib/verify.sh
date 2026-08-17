#!/usr/bin/env bash

command_exists() {

    command -v "$1" >/dev/null 2>&1

}


verify_command() {

    local command_name="$1"

    if command_exists "${command_name}"; then
        echo "✓ ${command_name} disponible"
        return 0
    else
        echo "✗ ${command_name} absent"
        return 1
    fi

}


verify_version() {

    local command_name="$1"

    if command_exists "${command_name}"; then
        "${command_name}" --version 2>/dev/null | head -n 1
    else
        echo "${command_name} non installé"
        return 1
    fi

}
