#!/usr/bin/env bash

select_modules_interactive() {
    local known_modules=(system_packages containers aws azure hashicorp kubernetes terminal)
    local default_modules=() selected=() tokens=() input token number i module found

    while IFS= read -r module; do
        [[ -n "${module}" ]] && default_modules+=("${module}")
    done < <(get_enabled_modules)

    for module in "${known_modules[@]}"; do
        found=0
        for token in "${default_modules[@]}"; do
            if [[ "${token}" == "${module}" ]]; then
                found=1
                break
            fi
        done
        selected+=("${found}")
    done

    while true; do
        printf "\n=== Module selection ===\n" >&2
        for ((i=0; i<${#known_modules[@]}; i++)); do
            if [[ "${selected[$i]}" == "1" ]]; then
                printf '%d. [x] %s\n' "$((i+1))" "${known_modules[$i]}" >&2
            else
                printf '%d. [ ] %s\n' "$((i+1))" "${known_modules[$i]}" >&2
            fi
        done
        printf '\nToggle module number(s), comma-separated; Enter to continue: ' >&2
        IFS= read -r input
        [[ -z "${input}" ]] && break
        input="${input//,/ }"
        tokens=()
        IFS=' ' read -r -a tokens <<< "${input}"
        for token in "${tokens[@]}"; do
            case "${token}" in
                ''|*[!0-9]*) printf '[WARNING] Ignoring invalid module selection: %s\n' "${token}" >&2; continue ;;
            esac
            number=$((token))
            if (( number < 1 || number > ${#known_modules[@]} )); then
                printf '[WARNING] Ignoring invalid module selection: %s\n' "${token}" >&2
                continue
            fi
            i=$((number-1))
            if [[ "${selected[$i]}" == "1" ]]; then selected[$i]=0; else selected[$i]=1; fi
        done
    done

    for ((i=0; i<${#known_modules[@]}; i++)); do
        [[ "${selected[$i]}" == "1" ]] && printf '%s\n' "${known_modules[$i]}"
    done
}
