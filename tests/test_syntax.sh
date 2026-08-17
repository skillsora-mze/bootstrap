#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
while IFS= read -r -d '' file; do
    bash -n "${file}"
done < <(find "${ROOT_DIR}" -type f -name '*.sh' -print0)
