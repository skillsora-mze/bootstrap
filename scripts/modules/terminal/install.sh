#!/usr/bin/env bash

set -euo pipefail

MODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "${MODULE_ROOT}/lib/log.sh"


log_info "Installing terminal module"


TRAINING_ALIAS_FILE="${HOME}/.training_aliases"

SOURCE_ALIAS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/files/aliases.training"


log_info "Detecting user shell"

CURRENT_SHELL="$(basename "${SHELL:-bash}")"

log_info "Detected shell: ${CURRENT_SHELL}"


if [[ ! -f "${SOURCE_ALIAS_FILE}" ]]; then

    log_error "Training aliases file not found: ${SOURCE_ALIAS_FILE}"
    exit 1

fi


log_info "Installing training aliases"

cp "${SOURCE_ALIAS_FILE}" "${TRAINING_ALIAS_FILE}"

chmod 644 "${TRAINING_ALIAS_FILE}"


log_info "Configuring shell integration"


case "${CURRENT_SHELL}" in

    zsh)
        SHELL_RC="${HOME}/.zshrc"
        ;;

    bash)
        SHELL_RC="${HOME}/.bashrc"
        ;;

    *)
        log_error "Unsupported shell: ${CURRENT_SHELL}"
        exit 1
        ;;

esac


MARKER="# Workstation Bootstrap training aliases"


if [[ -f "${SHELL_RC}" ]]; then

    if ! grep -q "${MARKER}" "${SHELL_RC}"; then

        cat >> "${SHELL_RC}" <<EOF

${MARKER}
if [ -f ~/.training_aliases ]; then
    source ~/.training_aliases
fi

EOF

        log_info "Shell configuration updated: ${SHELL_RC}"

    else

        log_info "Shell configuration already contains training aliases"

    fi

else

    log_info "Creating shell configuration: ${SHELL_RC}"

    cat > "${SHELL_RC}" <<EOF
${MARKER}
if [ -f ~/.training_aliases ]; then
    source ~/.training_aliases
fi
EOF

fi


log_success "Terminal module validated"
