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

    # Delete existing entry first (service-only lookup to handle account prefixes)
    security delete-generic-password \
        -s "$service" \
        &>/dev/null || true

    # Find actual binary paths for ACLs (less restrictive)
    local wrapper_path
    wrapper_path="${GLM_INSTALL_DIR:-$HOME/.claude-glm-mcp}/bin/glm-mcp-wrapper"

    # Build ACL flags (only wrapper script, not node/npx)
    # Using -U for user-only access (more compatible)
    local acl_flags=()
    [[ -f "$wrapper_path" ]] && acl_flags+=(-U "$wrapper_path")

    # Add new entry with explicit type and minimal ACLs
    # Note: -a "$account" may be modified by macOS on org-managed devices
    # We use service-only lookup for retrieval to handle this
    security add-generic-password \
        -a "$account" \
        -s "$service" \
        -w "$password" \
        -t "genp" \
        -D "GLM API Key" \
        "${acl_flags[@]:-}" \
        -j "Stored by claude-glm-wrapper"

    log_info "Credential stored for service: $service"
}

# Fetch credential from keychain
credential_fetch_platform() {
    local service="$1"
    local account="$2"  # Unused in lookup, but kept for interface consistency

    local password

    # Use service-only lookup to handle account name prefixes
    # macOS Keychain may modify account names on org-managed devices (e.g., "Domain\user")
    password="$(security find-generic-password \
        -s "$service" \
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
    local account="$2"  # Unused in lookup, but kept for interface consistency

    # Use service-only lookup to handle account name prefixes
    if security delete-generic-password \
        -s "$service" \
        &>/dev/null; then
        log_info "Credential deleted for service: $service"
        return 0
    fi

    log_info "Credential not found (may not exist): $service"
}

export -f credential_init_platform
export -f credential_check_deps_platform
export -f credential_store_platform
export -f credential_fetch_platform
export -f credential_delete_platform
