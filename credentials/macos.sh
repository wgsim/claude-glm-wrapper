#!/usr/bin/env bash
#
# macOS credential storage using Keychain
#

set -euo pipefail

# Logging
log_error() {
    echo "[macos:credentials] ERROR: $*" >&2
}

log_info() {
    echo "[macos:credentials] INFO: $*" >&2
}

# Initialize platform
credential_init_platform() {
    if ! command -v security &>/dev/null; then
        log_error "security command not found"
        return 1
    fi
}

# Check dependencies
credential_check_deps_platform() {
    local deps=("security")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log_error "Required dependency not found: $dep"
            return 1
        fi
    done
    return 0
}

# Store credential in keychain
credential_store_platform() {
    local service="$1"
    local account="$2"
    local password="$3"

    # Delete existing entry first (ignore errors)
    security delete-generic-password \
        -s "$service" \
        -a "$account" \
        &>/dev/null || true

    # Find actual binary paths for restrictive ACLs
    local node_path npx_path wrapper_path
    node_path="$(command -v node 2>/dev/null || echo "")"
    npx_path="$(command -v npx 2>/dev/null || echo "")"
    # Use configurable install directory with fallback
    wrapper_path="${GLM_INSTALL_DIR:-$HOME/.glm-mcp}/bin/glm-mcp-wrapper"

    # Build ACL flags with actual paths (only allow specific binaries)
    local acl_flags=()
    [[ -n "$node_path" ]] && acl_flags+=(-T "$node_path")
    [[ -n "$npx_path" ]] && acl_flags+=(-T "$npx_path")
    [[ -f "$wrapper_path" ]] && acl_flags+=(-T "$wrapper_path")

    # Add new entry with restrictive ACLs
    security add-generic-password \
        -a "$account" \
        -s "$service" \
        -w "$password" \
        "${acl_flags[@]}" \
        -j "Stored by claude-glm-wrapper"

    log_info "Credential stored for service: $service"
}

# Fetch credential from keychain
credential_fetch_platform() {
    local service="$1"
    local account="$2"

    local password
    password="$(security find-generic-password \
        -s "$service" \
        -a "$account" \
        -w 2>/dev/null)" || return 1

    if [[ -z "$password" ]]; then
        log_error "Retrieved password is empty"
        return 1
    fi

    echo "$password"
}

# Delete credential from keychain
credential_delete_platform() {
    local service="$1"
    local account="$2"

    if security delete-generic-password \
        -s "$service" \
        -a "$account" \
        &>/dev/null; then
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
