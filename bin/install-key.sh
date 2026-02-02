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

    # Sanitize input: remove newlines and control characters
    key=$(echo "$key" | tr -d '\n\r' | tr -cd '[:print:]')

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

# Check if key already exists
check_existing_key() {
    if credential_fetch "$KEYCHAIN_SERVICE" "$KEYCHAIN_ACCOUNT" &>/dev/null; then
        return 0
    fi
    return 1
}

# Store API key
store_api_key() {
    local api_key="$1"

    # Check if key already exists
    if check_existing_key; then
        print_info "API key already exists in credential storage"
        read -rp "Overwrite? (y/N): " -n 1 response
        echo
        if [[ ! $response =~ ^[Yy]$ ]]; then
            print_info "Keeping existing API key"
            return 0
        fi

        # Delete existing key first
        credential_delete "$KEYCHAIN_SERVICE" "$KEYCHAIN_ACCOUNT"
    fi

    # Store new key
    credential_store "$KEYCHAIN_SERVICE" "$KEYCHAIN_ACCOUNT" "$api_key"

    print_success "API key saved to credential storage"
}

# Main execution
main() {
    # Initialize credential backend
    credential_init

    echo "=== Z.ai API Key Registration ==="
    echo
    echo "This will store your Z.ai API key in $(get_credential_storage_name)."
    echo "Service: $KEYCHAIN_SERVICE"
    echo "Account: $KEYCHAIN_ACCOUNT"
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

    # Prompt for API key
    read -rp "Enter your Z.ai API key: " -s api_key
    echo
    echo

    # Validate API key (includes sanitization)
    if ! validate_api_key "$api_key"; then
        exit 1
    fi

    # Store in credential storage
    if ! store_api_key "$api_key"; then
        print_error "Failed to store API key"
        exit 1
    fi

    echo
    print_success "Setup complete! You can now use claude-by-glm."
    echo
    print_info "To verify, run:"
    if [[ "$CREDENTIAL_PLATFORM" == "macos" ]]; then
        echo "  security find-generic-password -s $KEYCHAIN_SERVICE -a $KEYCHAIN_ACCOUNT -w"
    elif [[ "$CREDENTIAL_PLATFORM" == "linux" ]]; then
        echo "  secret-tool lookup glm-wrapper-service $KEYCHAIN_SERVICE glm-wrapper-account $KEYCHAIN_ACCOUNT"
    fi
}

main "$@"
