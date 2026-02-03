#!/usr/bin/env bash
#
# install-key.sh - Register Z.ai API key in platform credential storage
#
# This script securely stores the Z.ai API key:
# - macOS: Keychain (security command)
# - Linux: libsecret (secret-tool)
# - Windows: Environment variable (ZAI_API_KEY)
#
# The API key is never written to any file.
#
# Usage:
#   ~/.claude-glm-mcp/bin/install-key.sh
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source credential abstraction (loads security.conf)
source "$PROJECT_DIR/credentials/common.sh"

# Initialize credential backend
if ! credential_init; then
    print_error "Failed to initialize credential backend for platform: $CREDENTIAL_PLATFORM"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored message
print_error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

print_success() {
    echo -e "${GREEN}SUCCESS:${NC} $*"
}

print_info() {
    echo -e "${YELLOW}INFO:${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $*"
}

# Validate API key format
validate_api_key() {
    local key="$1"

    # Basic validation: not empty, reasonable length, allowed characters
    if [[ -z "$key" ]]; then
        print_error "API key cannot be empty"
        return 1
    fi

    if [[ ${#key} -lt 20 ]]; then
        print_error "API key seems too short (minimum 20 characters)"
        return 1
    fi

    if [[ ${#key} -gt 200 ]]; then
        print_error "API key seems too long (maximum 200 characters)"
        return 1
    fi

    # Check for allowed characters (alphanumeric, underscore, hyphen, dot)
    if [[ ! "$key" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        print_error "API key contains invalid characters"
        print_info "Allowed: alphanumeric, underscore, hyphen, dot"
        return 1
    fi

    return 0
}

# Main execution
main() {
    # Initialize credential backend
    credential_init

    echo "=== Z.ai API Key Registration ==="
    echo
    echo "This will store your Z.ai API key in $(get_credential_storage_name)."
    echo "Platform: $CREDENTIAL_PLATFORM"
    echo

    # Windows special handling
    if [[ "$CREDENTIAL_PLATFORM" == "windows" ]]; then
        print_info "On Windows, please set the ZAI_API_KEY environment variable:"
        echo "  set ZAI_API_KEY=your_api_key"
        echo "  Or add to System Environment Variables"
        echo
        print_info "After setting, verify with:"
        echo "  echo %ZAI_API_KEY%"
        return 0
    fi

    # Prompt for account name (with default, validate not empty)
    local account=""
    while [[ -z "$account" ]]; do
        echo "Account name for credential storage:"
        echo "  Service: $KEYCHAIN_SERVICE"
        read -rp "  Account [$KEYCHAIN_ACCOUNT]: " input_account
        echo
        # Use input if provided, otherwise use default
        account="${input_account:-$KEYCHAIN_ACCOUNT}"
        if [[ -z "$account" ]]; then
            print_warning "Account name cannot be empty. Please try again."
            echo
        fi
    done

    # Prompt for API key with retry loop
    local max_attempts=3
    local attempt=1
    local api_key=""

    while [[ $attempt -le $max_attempts ]]; do
        read -rp "Enter your Z.ai API key: " -s api_key
        echo
        echo

        # Validate API key (includes sanitization)
        if validate_api_key "$api_key"; then
            break
        fi

        attempt=$((attempt + 1))
        if [[ $attempt -le $max_attempts ]]; then
            print_warning "Invalid API key format. Please try again. ($attempt/$max_attempts)"
            echo
        else
            print_error "Too many failed attempts. Please try again later."
            exit 1
        fi
    done

    # Check if key already exists and prompt for overwrite
    if credential_fetch "$KEYCHAIN_SERVICE" "$account" &>/dev/null; then
        print_info "API key already exists for account: $account"
        read -rp "Overwrite? (y/N): " -n 1 response
        echo
        if [[ ! $response =~ ^[Yy]$ ]]; then
            print_info "Keeping existing API key"
            return 0
        fi
        # Delete existing key first
        credential_delete "$KEYCHAIN_SERVICE" "$account"
    fi

    # Store in credential storage
    if ! credential_store "$KEYCHAIN_SERVICE" "$account" "$api_key"; then
        print_error "Failed to store API key"
        exit 1
    fi

    echo
    print_success "API key saved to credential storage"
    print_success "  Service: $KEYCHAIN_SERVICE"
    print_success "  Account: $account"
    echo
    print_success "Setup complete! You can now use claude-by-glm."
    echo
    print_info "To verify, run:"
    if [[ "$CREDENTIAL_PLATFORM" == "macos" ]]; then
        echo "  security find-generic-password -s $KEYCHAIN_SERVICE -w"
    elif [[ "$CREDENTIAL_PLATFORM" == "linux" ]]; then
        echo "  secret-tool lookup glm-wrapper-service $KEYCHAIN_SERVICE glm-wrapper-account $account"
    fi
}

main "$@"
