#!/usr/bin/env bash
#
# Linux credential storage using libsecret (secret-tool)
#

set -euo pipefail

# Logging
log_error() {
    echo "[linux:credentials] ERROR: $*" >&2
}

log_info() {
    echo "[linux:credentials] INFO: $*" >&2
}

# Initialize platform
credential_init_platform() {
    if ! command -v secret-tool &>/dev/null; then
        log_error "secret-tool not found. Install libsecret-tools:"
        log_info "  Ubuntu/Debian: sudo apt-get install libsecret-tools"
        log_info "  Fedora/RHEL: sudo dnf install libsecret-tools"
        log_info "  Arch: sudo pacman -S libsecret"
        return 1
    fi
}

# Check dependencies
credential_check_deps_platform() {
    local deps=("secret-tool")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log_error "Required dependency not found: $dep"
            log_info "Install with: sudo apt-get install libsecret-tools"
            return 1
        fi
    done
    return 0
}

# Store credential using secret-tool
credential_store_platform() {
    local service="$1"
    local account="$2"
    local password="$3"

    # Delete existing entry first
    secret-tool clear "$service" "$account" &>/dev/null || true

    # Store new credential
    # secret-tool stores with label and attributes
    echo "$password" | secret-tool store \
        --label="claude-glm-wrapper: $service" \
        "$service" "$service" \
        "account" "$account"

    log_info "Credential stored for service: $service"
}

# Fetch credential using secret-tool
credential_fetch_platform() {
    local service="$1"
    local account="$2"

    local password
    password="$(secret-tool lookup "$service" "$service" "account" "$account" 2>/dev/null)" || return 1

    if [[ -z "$password" ]]; then
        log_error "Retrieved password is empty"
        return 1
    fi

    echo "$password"
}

# Delete credential using secret-tool
credential_delete_platform() {
    local service="$1"
    local account="$2"

    if secret-tool clear "$service" "$service" "account" "$account" &>/dev/null; then
        log_info "Credential deleted for service: $service"
    else
        log_info "Credential not found (may not exist): $service"
    fi
}

export -f credential_init_platform
export -f credential_check_deps_platform
export -f credential_store_platform
export -f credential_fetch_platform
export -f credential_delete_platform
