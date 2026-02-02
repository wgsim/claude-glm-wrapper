#!/bin/bash
#
# uninstall.sh - Uninstall GLM MCP wrapper system
#
# This script removes the GLM MCP wrapper installation.
# Uses platform-specific trash commands when available.
#
# Usage:
#   ~/.glm-mcp/scripts/uninstall.sh
#

set -euo pipefail

# Configuration
INSTALL_DIR="$HOME/.glm-mcp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

print_success() {
    echo -e "${GREEN}SUCCESS:${NC} $*"
}

print_info() {
    echo -e "${BLUE}INFO:${NC} $*"
}

print_step() {
    echo -e "${YELLOW}==>${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $*"
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin)  echo "macos" ;;
        Linux)   echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)       echo "unknown" ;;
    esac
}

# Detect current shell
detect_shell() {
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        echo "zsh"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        echo "bash"
    elif [[ -n "${FISH_VERSION:-}" ]]; then
        echo "fish"
    else
        echo "unknown"
    fi
}

# Get shell config file
get_shell_config() {
    local shell="$1"
    case "$shell" in
        zsh)
            if [[ -n "$ZDOTDIR" ]]; then
                echo "$ZDOTDIR/.zshrc"
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

# Find trash command for current platform
find_trash_cmd() {
    local os
    os="$(detect_os)"

    case "$os" in
        macos)
            # Try homebrew trash first, then osascript fallback
            if command -v trash &>/dev/null; then
                echo "trash"
            elif command -v /opt/homebrew/bin/trash &>/dev/null; then
                echo "/opt/homebrew/bin/trash"
            else
                echo ""
            fi
            ;;
        linux)
            # Try gio trash (GNOME), then trash-cli
            if command -v gio &>/dev/null && gio help trash &>/dev/null; then
                echo "gio trash"
            elif command -v trash-cli &>/dev/null; then
                echo "trash-cli"
            elif command -v trash &>/dev/null; then
                echo "trash"
            else
                echo ""
            fi
            ;;
        windows)
            # Windows has built-in recycle bin
            echo "windows"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Move file to trash using platform-specific method
move_to_trash() {
    local target="$1"
    local trash_cmd
    trash_cmd="$(find_trash_cmd)"

    case "$trash_cmd" in
        trash|/opt/homebrew/bin/trash)
            "$trash_cmd" "$target"
            ;;
        "gio trash")
            gio trash "$target"
            ;;
        "trash-cli")
            trash-cli "$target"
            ;;
        "windows")
            # Windows: PowerShell to move to Recycle Bin
            powershell.exe -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('$target', 'OnlyErrorDialogs', 'SendToRecycleBin')" 2>/dev/null || rm -rf "$target"
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if installation exists
check_installation() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_info "GLM MCP wrapper is not installed"
        return 1
    fi
    return 0
}

# Remove PATH configuration
remove_path_config() {
    echo
    print_step "PATH Configuration"
    echo

    local shell
    local shell_config
    shell="$(detect_shell)"
    shell_config="$(get_shell_config "$shell")"

    if [[ -z "$shell_config" ]]; then
        print_info "Could not determine shell config file"
        print_info "Please manually remove PATH from your shell config:"
        echo "  Remove line containing: ~/.glm-mcp/bin"
        return 0
    fi

    if [[ ! -f "$shell_config" ]]; then
        print_info "Shell config not found: $shell_config"
        return 0
    fi

    # Check if PATH contains our bin directory
    if grep -q "$INSTALL_DIR/bin" "$shell_config" 2>/dev/null; then
        read -rp "Remove ~/.glm-mcp/bin from PATH in $shell_config? (y/N): " -n 1 -r
        echo
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Backup config file
            cp "$shell_config" "${shell_config}.backup.$(date +%Y%m%d_%H%M%S)"

            # Remove lines containing our PATH
            local temp_file
            temp_file="$(mktemp -t "glm-uninstall-XXXXXX")"
            if grep -v -F "$INSTALL_DIR/bin" "$shell_config" > "$temp_file" 2>/dev/null; then
                if [[ -s "$temp_file" ]]; then
                    mv "$temp_file" "$shell_config"
                    print_success "PATH configuration removed from: $shell_config"
                    print_info "Backup saved to: ${shell_config}.backup.$(date +%Y%m%d_%H%M%S)"
                else
                    print_warning "Resulting config would be empty, keeping original"
                    rm -f "$temp_file"
                fi
            else
                print_error "Failed to process shell config"
                rm -f "$temp_file"
            fi
        else
            print_info "PATH configuration kept in: $shell_config"
        fi
    else
        print_info "No PATH configuration found in: $shell_config"
    fi
}

# Remove from keychain (macOS only)
remove_keychain_entry() {
    case "$(detect_os)" in
        macos)
            print_step "Removing GLM model API key from keychain..."
            local keychain_service="glm-coding-plan"
            local keychain_account="${USER:-$LOGNAME}"

            if security find-generic-password \
                -s "$keychain_service" \
                -a "$keychain_account" \
                &>/dev/null; then

                security delete-generic-password \
                    -s "$keychain_service" \
                    -a "$keychain_account" \
                    &>/dev/null || true

                print_success "GLM model API key removed from keychain"
            else
                print_info "No GLM model API key found in keychain"
            fi

            # Note: Don't remove Z.ai API key (used by MCP wrapper)
            print_info "Note: Z.ai MCP wrapper API key (z.ai-api-key) is kept"
            ;;
        linux|windows|*)
            print_info "Keychain removal only applicable to macOS"
            ;;
    esac
}

# Prompt before removing from .claude.json
prompt_claude_config() {
    local claude_json="$HOME/.claude.json"

    if [[ -f "$claude_json" ]]; then
        if grep -q "glm-mcp-wrapper" "$claude_json" 2>/dev/null; then
            echo
            print_step "Claude Configuration"
            echo
            echo "Your ~/.claude.json contains glm-mcp-wrapper configuration."
            echo "You should manually remove it:"
            echo
            echo '  Remove the "glm-mcp-wrapper" section from mcpServers'
            echo
            read -rp "Open ~/.claude.json in editor? (y/N): " -n 1 -r
            echo

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Try common editors
                if command -v code &>/dev/null; then
                    code "$claude_json"
                elif command -v vim &>/dev/null; then
                    vim "$claude_json"
                elif command -v nano &>/dev/null; then
                    nano "$claude_json"
                else
                    print_info "No editor found. Please edit manually."
                fi
            fi
        fi
    fi
}

# Remove installation directory
remove_installation() {
    print_step "Removing installation directory..."

    local trash_cmd
    trash_cmd="$(find_trash_cmd)"

    if [[ -n "$trash_cmd" ]]; then
        # Use platform-specific trash command
        print_info "Using trash: $trash_cmd"
        move_to_trash "$INSTALL_DIR"
        print_success "Installation directory moved to trash"

        echo
        echo "To restore or permanently delete:"
        case "$(detect_os)" in
            macos)   echo "  open trash" ;;
            linux)   echo "  Check your file manager" ;;
            windows) echo "  Open Recycle Bin" ;;
        esac
    else
        # No trash command available
        print_warning "No trash command found on this system"
        print_warning "Will use 'rm -rf' to permanently delete directory"
        echo
        read -rp "Continue with permanent deletion? (y/N): " -n 1 -r
        echo
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
            print_success "Installation directory permanently deleted"
        else
            print_info "Deletion cancelled. Directory kept at: $INSTALL_DIR"
            print_info "To delete manually: rm -rf $INSTALL_DIR"
            return 1
        fi
    fi
}

# Print completion message
print_completion() {
    echo
    print_success "Uninstallation complete!"
    echo
    echo "Summary:"
    if [[ -n "$(find_trash_cmd)" ]]; then
        case "$(detect_os)" in
            macos)
                echo "  - Installation directory moved to trash"
                echo "  - GLM model API key removed from keychain"
                echo "  - Z.ai MCP wrapper API key kept (z.ai-api-key)"
                ;;
            linux)
                echo "  - Installation directory moved to trash"
                echo "  - Keychain removal not applicable on Linux"
                ;;
            windows)
                echo "  - Installation directory moved to Recycle Bin"
                echo "  - Keychain removal not applicable on Windows"
                ;;
        esac
    else
        echo "  - Installation directory permanently deleted"
    fi
    echo "  - Check ~/.claude.json and remove glm-mcp-wrapper if present"
    echo
}

# Main execution
main() {
    echo "=== GLM MCP Wrapper Uninstallation ==="
    echo

    # Check if installed
    if ! check_installation; then
        exit 0
    fi

    # Confirmation
    read -rp "Uninstall GLM MCP wrapper? (y/N): " -n 1 -r
    echo
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstallation cancelled"
        exit 0
    fi

    # Remove PATH configuration
    remove_path_config

    # Remove GLM model API key from keychain
    remove_keychain_entry

    # Prompt about .claude.json
    prompt_claude_config

    # Remove installation
    if ! remove_installation; then
        exit 1
    fi

    # Print completion
    print_completion
}

main "$@"
