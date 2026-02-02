#!/usr/bin/env bash
#
# install-key.sh - Register Z.ai API key in macOS keychain
#
# This script securely stores the Z.ai API key in the macOS keychain.
# The API key is never written to any file.
#
# Usage:
#   ~/.glm-mcp/bin/install-key.sh
#

set -euo pipefail

# Configuration
KEYCHAIN_SERVICE="z.ai-api-key"
KEYCHAIN_ACCOUNT="${USER:-$LOGNAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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
    if security find-generic-password \
        -s "$KEYCHAIN_SERVICE" \
        -a "$KEYCHAIN_ACCOUNT" \
        &>/dev/null; then
        return 0
    fi
    return 1
}

# Store API key in keychain
store_api_key() {
    local api_key="$1"

    # Check if key already exists
    if check_existing_key; then
        print_info "API key already exists in keychain"
        read -rp "Overwrite? (y/N): " -n 1 response
        echo
        if [[ ! $response =~ ^[Yy]$ ]]; then
            print_info "Keeping existing API key"
            return 0
        fi

        # Delete existing key first
        if security delete-generic-password \
            -s "$KEYCHAIN_SERVICE" \
            -a "$KEYCHAIN_ACCOUNT" \
            2>&1; then
            print_info "Removed existing key"
        else
            print_warning "Could not delete existing key (may not exist)"
        fi
    fi

    # Add new key to keychain (without -U flag for proper ACLs)
    security add-generic-password \
        -a "$KEYCHAIN_ACCOUNT" \
        -s "$KEYCHAIN_SERVICE" \
        -w "$api_key" \
        -T "/usr/local/bin/node" \
        -T "/opt/homebrew/bin/node" \
        -T "/usr/local/bin/npx" \
        -T "/opt/homebrew/bin/npx"

    print_success "API key saved to keychain"
}

# Main execution
main() {
    echo "=== Z.ai API Key Registration ==="
    echo
    echo "This will store your Z.ai API key in the macOS keychain."
    echo "Service: $KEYCHAIN_SERVICE"
    echo "Account: $KEYCHAIN_ACCOUNT"
    echo

    # Prompt for API key
    read -rp "Enter your Z.ai API key: " -s api_key
    echo
    echo

    # Validate API key (includes sanitization)
    if ! validate_api_key "$api_key"; then
        exit 1
    fi

    # Store in keychain
    if ! store_api_key "$api_key"; then
        print_error "Failed to store API key in keychain"
        exit 1
    fi

    echo
    print_success "Setup complete! You can now use claude-by-glm."
    echo
    echo "To verify:"
    echo "  security find-generic-password -s $KEYCHAIN_SERVICE -a $KEYCHAIN_ACCOUNT -w"
}

main "$@"
