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

# Detect platform
CREDENTIAL_PLATFORM="${CREDENTIAL_PLATFORM:-$(detect_platform)}"

# Load security configuration
# Try to load from project security.conf, with fallback defaults
load_security_config() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local config_file="$script_dir/credentials/security.conf"

    # Try to source config file (may not exist in all contexts)
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi

    # Fallback defaults (if config file missing or incomplete)
    KEYCHAIN_SERVICE="${KEYCHAIN_SERVICE:-z.ai-api-key}"
    KEYCHAIN_ACCOUNT="${KEYCHAIN_ACCOUNT:-${USER:-${LOGNAME}}}"
    GLM_USE_MCP="${GLM_USE_MCP:-1}"
    GLM_INSTALL_DIR="${GLM_INSTALL_DIR:-${HOME}/.claude-glm-mcp}"
}

# Load configuration
load_security_config

# Export configuration values
export KEYCHAIN_SERVICE
export KEYCHAIN_ACCOUNT
export GLM_USE_MCP
export GLM_INSTALL_DIR

# Platform detection
detect_platform() {
    local ostype="${OSTYPE:-}"
    local uname_s="$(uname -s 2>/dev/null || echo "")"

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

# Initialize credential backend
credential_init() {
    local platform="$CREDENTIAL_PLATFORM"

    # Check if platform is supported
    if [[ "$platform" == "unknown" ]]; then
        echo "ERROR: Unable to detect platform (OSTYPE=$ostype, uname=$uname_s)" >&2
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
