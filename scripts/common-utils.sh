#!/usr/bin/env bash
#
# common-utils.sh - Shared utility functions for GLM MCP Wrapper scripts
#
# This library provides common functionality to avoid code duplication:
# - Shell detection (detect_shell, get_shell_config)
# - OS detection (detect_os)
# - Color constants for output
# - Print functions (print_error, print_success, print_info, print_warning, print_step)
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/common-utils.sh"
#

set -euo pipefail

# ============================================================================
# Color Constants
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# ============================================================================
# Print Functions
# ============================================================================

print_error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

print_success() {
    echo -e "${GREEN}SUCCESS:${NC} $*"
}

print_info() {
    echo -e "${BLUE}INFO:${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $*"
}

print_step() {
    echo -e "${YELLOW}==>${NC} $*"
}

# Handle critical errors and exit
handle_error() {
    print_error "$*"
    exit 1
}

# ============================================================================
# OS Detection
# ============================================================================

# Detect current operating system
# Returns: macos, linux, windows, or unknown
detect_os() {
    case "$(uname -s)" in
        Darwin)  echo "macos" ;;
        Linux)   echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)       echo "unknown" ;;
    esac
}

# ============================================================================
# Shell Detection
# ============================================================================

# Detect current shell
# Checks $SHELL first (most reliable), then version variables as fallback
# Returns: zsh, bash, fish, or unknown
detect_shell() {
    # Check $SHELL first (user's login shell) - most reliable
    if [[ -n "${SHELL:-}" ]]; then
        case "$SHELL" in
            */zsh)
                echo "zsh"
                return
                ;;
            */bash)
                # Still check if we're actually in bash (not just SHELL pointing to bash)
                if [[ -n "${BASH_VERSION:-}" ]]; then
                    echo "bash"
                    return
                fi
                ;;
            */fish)
                echo "fish"
                return
                ;;
        esac
    fi

    # Fallback: check current shell version variables
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        echo "zsh"
        return
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        echo "bash"
        return
    elif [[ -n "${FISH_VERSION:-}" ]]; then
        echo "fish"
        return
    fi

    echo "unknown"
}

# Get shell config file path for current shell
# Returns config file path, or empty string if unknown shell
get_shell_config() {
    local shell="$1"
    case "$shell" in
        zsh)
            if [[ -n "${ZDOTDIR:-}" ]]; then
                echo "${ZDOTDIR}/.zshrc"
            else
                echo "$HOME/.zshrc"
            fi
            ;;
        bash)
            echo "$HOME/.bashrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# Export Functions
# ============================================================================

export -f detect_os
export -f detect_shell
export -f get_shell_config
export -f print_error
export -f print_success
export -f print_info
export -f print_warning
export -f print_step
