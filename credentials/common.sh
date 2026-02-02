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

# Configuration
KEYCHAIN_SERVICE="${KEYCHAIN_SERVICE:-z.ai-api-key}"
KEYCHAIN_ACCOUNT="${KEYCHAIN_ACCOUNT:-${USER:-${LOGNAME}}}"

# Platform detection
detect_platform() {
    case "${OSTYPE:-}" in
        darwin*)  echo "macos" ;;
        linux*)   echo "linux" ;;
        msys*|mingw*|cygwin*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# Initialize credential backend
credential_init() {
    local platform="$CREDENTIAL_PLATFORM"

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

    # Initialize platform-specific backend
    if declare -f credential_init_platform &>/dev/null; then
        credential_init_platform
    fi
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

# Export functions
export -f detect_platform
export -f credential_init
export -f credential_store
export -f credential_fetch
export -f credential_delete
export -f credential_check_deps
