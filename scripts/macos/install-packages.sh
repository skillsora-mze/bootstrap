#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/download.sh"

BREWFILE="${ROOT_DIR}/packages/macos/Brewfile"

log_section "Installing macOS packages"

if ! command -v brew >/dev/null 2>&1; then
    log_info "Installing Homebrew"

    log_info "Administrator privileges are required for the initial Homebrew installation"
    if ! sudo -v; then
        log_error "Unable to obtain administrator privileges"
        exit 1
    fi

    tmp_dir="$(with_temp_dir)"
    trap 'rm -rf "${tmp_dir}"' EXIT
    installer="${tmp_dir}/install-homebrew.sh"
    download_file "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" "${installer}"
    NONINTERACTIVE=1 /bin/bash "${installer}"

    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        log_error "Homebrew installation completed but brew was not found"
        exit 1
    fi
else
    log_info "Homebrew already installed"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
    touch "${HOME}/.zprofile"
    grep -Fq 'eval "$(/opt/homebrew/bin/brew shellenv)"' "${HOME}/.zprofile" || \
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
fi

[[ -f "${BREWFILE}" ]] || { log_error "Brewfile not found: ${BREWFILE}"; exit 1; }

log_info "Installing/updating packages from Brewfile"
brew bundle install --file "${BREWFILE}"

log_info "Configuring Docker CLI plugins"

python3 - <<'PYDOCKER'
import json
from pathlib import Path

p = Path.home() / ".docker" / "config.json"
p.parent.mkdir(parents=True, exist_ok=True)

if p.exists():
    try:
        data = json.loads(p.read_text())
    except json.JSONDecodeError:
        raise SystemExit(f"Invalid Docker config JSON: {p}")
else:
    data = {}

dirs = data.setdefault("cliPluginsExtraDirs", [])
plugin_dir = "/opt/homebrew/lib/docker/cli-plugins"

if plugin_dir not in dirs:
    dirs.append(plugin_dir)

p.write_text(json.dumps(data, indent=2) + "\n")
PYDOCKER

log_success "macOS packages installation completed"
