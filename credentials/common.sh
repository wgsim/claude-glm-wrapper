#!/usr/bin/env bash
#
# credential-abstraction - Platform-agnostic credential storage interface
#
# This module provides a unified interface for credential storage across platforms:
# - macOS: Keychain (security command)
# - Linux: libsecret (secret-tool)
# - Windows: Credential Manager (PowerShell)
#
# Usage:
#   source credentials/common.sh
#   credential_init
#   credential_store "service" "account" "password"
#   credential_fetch "service" "account"
#   credential_delete "service" "account"
#

set -euo pipefail

# Platform detection (MUST be defined before use below)
detect_platform() {
    local ostype="${OSTYPE:-}"
    local uname_s
    uname_s="$(uname -s 2>/dev/null || echo "")"

    # Try OSTYPE first
    case "$ostype" in
        darwin*)  echo "macos"; return ;;
        linux*)   echo "linux"; return ;;
        msys*|mingw*|cygwin*) echo "windows"; return ;;
    esac

    # Fallback to uname
    case "$uname_s" in
        Darwin)  echo "macos"; return ;;
        Linux)   echo "linux"; return ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows"; return ;;
    esac

    echo "unknown"
}

# Detect platform (now detect_platform is defined)
CREDENTIAL_PLATFORM="${CREDENTIAL_PLATFORM:-$(detect_platform)}"

# Load security configuration (safe parsing, not code execution)
# Try to load from project security.conf, with fallback defaults
load_security_config() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local config_file="$script_dir/credentials/security.conf"

    # Fallback defaults (used if config file missing or values not found)
    KEYCHAIN_SERVICE="${KEYCHAIN_SERVICE:-z.ai-api-key}"
    KEYCHAIN_ACCOUNT="${KEYCHAIN_ACCOUNT:-${USER:-${LOGNAME}}}"
    GLM_USE_MCP="${GLM_USE_MCP:-1}"
    GLM_INSTALL_DIR="${GLM_INSTALL_DIR:-${HOME}/.claude-glm-mcp}"
    ZAI_MCP_VERSION="${ZAI_MCP_VERSION:-1.0.0}"

    # Parse config file safely (no code execution)
    if [[ -f "$config_file" ]]; then
        # Extract each variable safely using grep + sed
        local service account use_mcp install_dir mcp_version

        service=$(grep -E '^KEYCHAIN_SERVICE=' "$config_file" 2>/dev/null | tail -1 | sed 's/^KEYCHAIN_SERVICE=//' | tr -d '"'"'" | xargs)
        account=$(grep -E '^KEYCHAIN_ACCOUNT=' "$config_file" 2>/dev/null | tail -1 | sed 's/^KEYCHAIN_ACCOUNT=//' | tr -d '"'"'" | xargs)
        use_mcp=$(grep -E '^GLM_USE_MCP=' "$config_file" 2>/dev/null | tail -1 | sed 's/^GLM_USE_MCP=//' | tr -d '"'"'" | xargs)
        install_dir=$(grep -E '^GLM_INSTALL_DIR=' "$config_file" 2>/dev/null | tail -1 | sed 's/^GLM_INSTALL_DIR=//' | tr -d '"'"'" | xargs)
        mcp_version=$(grep -E '^ZAI_MCP_VERSION=' "$config_file" 2>/dev/null | tail -1 | sed 's/^ZAI_MCP_VERSION=//' | tr -d '"'"'" | xargs)

        # Apply parsed values if valid
        [[ -n "$service" ]] && KEYCHAIN_SERVICE="$service"

        # Expand account if it contains shell variable syntax
        if [[ -n "$account" ]]; then
            # If account contains ${...}, expand it
            # shellcheck disable=SC2016  # Intentionally matching literal ${ and $ characters
            if [[ "$account" == *'${'* ]] || [[ "$account" == *'$'* ]]; then
                # Safe expansion: only USER and LOGNAME variables
                account="${account//\$\{USER:-\$LOGNAME\}/${USER:-$LOGNAME}}"
                account="${account//\$USER/$USER}"
                account="${account//\$LOGNAME/$LOGNAME}"
            fi
            KEYCHAIN_ACCOUNT="$account"
        fi
        [[ "$use_mcp" == "0" || "$use_mcp" == "1" ]] && GLM_USE_MCP="$use_mcp"
        [[ -n "$install_dir" ]] && GLM_INSTALL_DIR="$install_dir"
        [[ -n "$mcp_version" ]] && ZAI_MCP_VERSION="$mcp_version"
    fi
}

# Load configuration
load_security_config

# Export configuration values
export KEYCHAIN_SERVICE
export KEYCHAIN_ACCOUNT
export GLM_USE_MCP
export GLM_INSTALL_DIR
export ZAI_MCP_VERSION

# Initialize credential backend
credential_init() {
    local platform="$CREDENTIAL_PLATFORM"

    # Check if platform is supported
    if [[ "$platform" == "unknown" ]]; then
        echo "ERROR: Unable to detect platform (OSTYPE=${OSTYPE:-}, uname=$(uname -s 2>/dev/null || echo unknown))" >&2
        echo "ERROR: Please report this issue with your system information" >&2
        return 1
    fi

    case "$platform" in
        macos)
            source "$(dirname "${BASH_SOURCE[0]}")/macos.sh"
            ;;
        linux)
            source "$(dirname "${BASH_SOURCE[0]}")/linux.sh"
            ;;
        windows)
            source "$(dirname "${BASH_SOURCE[0]}")/windows.sh"
            ;;
        *)
            echo "ERROR: Unsupported platform: $platform" >&2
            return 1
            ;;
    esac

    # Initialize platform-specific backend and check return value
    if declare -f credential_init_platform &>/dev/null; then
        if ! credential_init_platform; then
            echo "ERROR: Failed to initialize $platform credential backend" >&2
            return 1
        fi
    fi

    return 0
}

# Unified interface - delegates to platform-specific implementation
credential_store() {
    local service="$1"
    local account="$2"
    local password="$3"

    if declare -f credential_store_platform &>/dev/null; then
        credential_store_platform "$service" "$account" "$password"
    else
        echo "ERROR: credential_store not implemented for $CREDENTIAL_PLATFORM" >&2
        return 1
    fi
}

credential_fetch() {
    local service="$1"
    local account="$2"

    if declare -f credential_fetch_platform &>/dev/null; then
        credential_fetch_platform "$service" "$account"
    else
        echo "ERROR: credential_fetch not implemented for $CREDENTIAL_PLATFORM" >&2
        return 1
    fi
}

credential_delete() {
    local service="$1"
    local account="$2"

    if declare -f credential_delete_platform &>/dev/null; then
        credential_delete_platform "$service" "$account"
    else
        echo "ERROR: credential_delete not implemented for $CREDENTIAL_PLATFORM" >&2
        return 1
    fi
}

credential_check_deps() {
    if declare -f credential_check_deps_platform &>/dev/null; then
        credential_check_deps_platform
    else
        return 0
    fi
}

# Get platform-specific credential storage display name
get_credential_storage_name() {
    case "$CREDENTIAL_PLATFORM" in
        macos)
            echo "macOS Keychain"
            ;;
        linux)
            echo "libsecret (secret-tool)"
            ;;
        windows)
            echo "Environment variable (ZAI_API_KEY)"
            ;;
        *)
            echo "credential storage"
            ;;
    esac
}

# Export functions
export -f detect_platform
export -f credential_init
export -f credential_store
export -f credential_fetch
export -f credential_delete
export -f credential_check_deps
export -f get_credential_storage_name
