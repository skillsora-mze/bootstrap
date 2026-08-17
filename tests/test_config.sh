#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/config.sh"
load_config
expected=(system_packages containers aws azure hashicorp kubernetes terminal)
actual=()
while IFS= read -r module; do
    actual+=("$module")
done < <(get_enabled_modules)
[[ "${actual[*]}" == "${expected[*]}" ]] || { echo "Unexpected module order: ${actual[*]}" >&2; exit 1; }
[[ "$(get_bootstrap_version)" == "1.4.1" ]]
