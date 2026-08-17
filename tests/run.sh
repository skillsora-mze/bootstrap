#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for test in "${ROOT_DIR}"/tests/test_*.sh; do
    echo "==> $(basename "${test}")"
    bash "${test}"
done
echo "All tests passed"
