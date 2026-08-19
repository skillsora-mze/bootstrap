#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/config.sh"
source "${ROOT_DIR}/scripts/lib/selection.sh"

# Disable AWS (3) and Azure (4), then accept selection.
actual="$(printf '3,4\n\n' | select_modules_interactive 2>/dev/null | paste -sd ',' -)"
expected='system_packages,containers,hashicorp,kubernetes,terminal'
[[ "${actual}" == "${expected}" ]] || { echo "Unexpected interactive selection: ${actual}" >&2; exit 1; }
