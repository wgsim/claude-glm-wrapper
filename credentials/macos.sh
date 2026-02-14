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

    # Validate password is not empty
    if [[ -z "$password" ]]; then
        log_error "Cannot store empty password"
        return 1
    fi

    # Unlock keychain for SSH/non-interactive sessions
    # May fail if keychain password differs from login password
    # Use absolute path to prevent PATH poisoning
    /usr/bin/security unlock-keychain &>/dev/null || true

    # Delete existing entry first (try service+account, fallback to service-only)
    # Use absolute path to prevent PATH poisoning
    /usr/bin/security delete-generic-password \
        -s "$service" \
        -a "$account" \
        &>/dev/null || \
    /usr/bin/security delete-generic-password \
        -s "$service" \
        &>/dev/null || true

    # Add new entry (no -t option, use defaults)
    # Note: -a "$account" may be modified by macOS on org-managed devices
    # We use service-only lookup for retrieval to handle this
    # Security: Pass password via stdin to avoid process list exposure
    # Use absolute path to prevent PATH poisoning
    local output
    output=$(printf "%s" "$password" | /usr/bin/security add-generic-password \
        -a "$account" \
        -s "$service" \
        -w \
        -D "GLM API Key" \
        -j "Stored by claude-glm-wrapper" 2>&1)

    # Check for errors
    if [[ "$output" == *"Usage:"* ]] || [[ "$output" == *"error:"* ]] || [[ "$output" == *"User interaction"* ]]; then
        log_error "Failed to store credential"
        log_error "If in SSH session, run: security unlock-keychain"
        return 1
    fi

    log_info "Credential stored for service: $service"
}

# Fetch credential from keychain
credential_fetch_platform() {
    local service="$1"
    local account="$2"

    local password

    # Try service+account match first (most specific)
    # Use absolute path to prevent PATH poisoning during credential fetch
    password="$(/usr/bin/security find-generic-password \
        -s "$service" \
        -a "$account" \
        -w 2>/dev/null)" && {
        if [[ -n "$password" ]]; then
            printf '%s' "$password"
            return 0
        fi
    }

    # Fallback: service-only lookup for org-managed devices (opt-in)
    # macOS Keychain may modify account names (e.g., "Domain\user")
    # WARNING: This can return credentials for wrong account if multiple entries exist
    # Only enable for known managed-device scenarios via GLM_ALLOW_SERVICE_ONLY_KEYCHAIN=1
    if [[ "${GLM_ALLOW_SERVICE_ONLY_KEYCHAIN:-0}" == "1" ]]; then
        # Use absolute path to prevent PATH poisoning during credential fetch
        password="$(/usr/bin/security find-generic-password \
            -s "$service" \
            -w 2>/dev/null)" || return 1

        if [[ -z "$password" ]]; then
            log_error "Retrieved password is empty"
            return 1
        fi

        printf '%s' "$password"
        return 0
    else
        # Service+account match required - no fallback allowed
        return 1
    fi
}

# Delete credential from keychain
credential_delete_platform() {
    local service="$1"
    local account="$2"

    # Try service+account match first (most specific)
    # Use absolute path to prevent PATH poisoning
    if /usr/bin/security delete-generic-password \
        -s "$service" \
        -a "$account" \
        &>/dev/null; then
        log_info "Credential deleted for service: $service, account: $account"
        return 0
    fi

    # Fallback: service-only delete for org-managed devices (opt-in)
    # Only enable if GLM_ALLOW_SERVICE_ONLY_KEYCHAIN=1 to prevent deleting wrong credentials
    if [[ "${GLM_ALLOW_SERVICE_ONLY_KEYCHAIN:-0}" == "1" ]]; then
        # Use absolute path to prevent PATH poisoning
        if /usr/bin/security delete-generic-password \
            -s "$service" \
            &>/dev/null; then
            log_info "Credential deleted for service: $service (service-only match)"
            return 0
        fi
    fi

    log_info "Credential not found (may not exist): $service"
}

export -f credential_init_platform
export -f credential_check_deps_platform
export -f credential_store_platform
export -f credential_fetch_platform
export -f credential_delete_platform
