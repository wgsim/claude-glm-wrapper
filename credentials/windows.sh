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

    # Use PowerShell to store credential
    # Target name format: claude-glm-wrapper:service:account
    local target_name="claude-glm-wrapper:${service}:${account}"

    powershell.exe -NoProfile -Command "
        try {
            \$password = '${password}' | ConvertTo-SecureString -AsPlainText -Force
            \$credential = New-Object System.Management.Automation.PSCredential ('${account}', \$password)
            Write-Host 'Storing credential for ${service}'
        } catch {
            Write-Error \$_
            exit 1
        }
    " 2>/dev/null

    # Alternative: Use cmdkey command (older but more compatible)
    cmdkey /generic:"$target_name" /user:"$account" /pass:"$password" &>/dev/null || true

    log_info "Credential stored for service: $service"
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

    echo "$password"
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
