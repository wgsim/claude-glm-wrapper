#!/usr/bin/env bash
#
# Windows credential storage using Windows Credential Manager
#

set -euo pipefail

# Logging
log_error() {
    echo "[windows:credentials] ERROR: $*" >&2
}

log_info() {
    echo "[windows:credentials] INFO: $*" >&2
}

# Initialize platform
credential_init_platform() {
    if ! command -v powershell.exe &>/dev/null; then
        log_error "PowerShell not found"
        return 1
    fi
}

# Check dependencies
credential_check_deps_platform() {
    if ! command -v powershell.exe &>/dev/null; then
        log_error "PowerShell not found"
        return 1
    fi
    return 0
}

# Store credential using Windows Credential Manager
credential_store_platform() {
    local service="$1"
    local account="$2"
    local password="$3"

    # Windows does not support programmatic credential retrieval
    # from Credential Manager for security reasons.
    # We explicitly inform the user and guide them to use environment variables.

    log_error "Windows does not support automated credential storage"
    echo
    echo "Please set the environment variable manually:"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PowerShell (current session):"
    echo "  \$env:ZAI_API_KEY='your_api_key_here'"
    echo
    echo "PowerShell (permanent, user-level):"
    echo "  [System.Environment]::SetEnvironmentVariable('ZAI_API_KEY', 'your_api_key_here', 'User')"
    echo
    echo "CMD (current session):"
    echo "  set ZAI_API_KEY=your_api_key_here"
    echo
    echo "CMD (permanent):"
    echo "  setx ZAI_API_KEY your_api_key_here"
    echo
    echo "PowerShell (system-wide - requires admin):"
    echo "  setx ZAI_API_KEY 'your_api_key_here' /M"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "설정 후, 새 터미널을 열어야 합니다."
    echo

    # Return failure to indicate automatic storage is not supported
    return 1
}

# Fetch credential using environment variable (Windows limitation)
credential_fetch_platform() {
    local service="$1"
    local account="$2"

    # Windows Credential Manager doesn't allow programmatic password retrieval
    # Use environment variable instead

    # Map service to env var name
    local env_var_name
    case "$service" in
        "z.ai-api-key")
            env_var_name="ZAI_API_KEY"
            ;;
        *)
            # Generic: uppercase and replace dots/hyphens with underscores
            env_var_name="$(echo "$service" | tr '[:lower:].' '[:upper:]_')"
            ;;
    esac

    local password="${!env_var_name:-}"

    if [[ -z "$password" ]]; then
        log_error "Credential not found in environment: $env_var_name"
        log_error "Set it with: set $env_var_name=your_api_key"
        return 1
    fi

    printf '%s' "$password"
}

# Delete credential using Windows Credential Manager
credential_delete_platform() {
    local service="$1"
    local account="$2"

    local target_name="claude-glm-wrapper:${service}:${account}"

    if cmdkey /delete:"$target_name" &>/dev/null; then
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
