#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_home="$(mktemp -d)"
trap 'rm -rf "${tmp_home}"' EXIT

for _ in 1 2; do
    HOME="${tmp_home}" SHELL=/bin/bash bash "${ROOT_DIR}/scripts/modules/terminal/install.sh" >/dev/null
done

[[ -f "${tmp_home}/.training_aliases" ]]
[[ -f "${tmp_home}/.bashrc" ]]
count="$(grep -c '^# Workstation Bootstrap training aliases$' "${tmp_home}/.bashrc")"
[[ "${count}" == "1" ]] || { echo "Terminal integration is not idempotent" >&2; exit 1; }
