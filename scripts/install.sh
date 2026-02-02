#!/bin/bash
#
# install.sh - Install GLM MCP wrapper system
#
# This script installs the GLM MCP wrapper to ~/.glm-mcp/ and
# configures PATH and shell integration based on user preferences.
#
# Usage:
#   ~/.glm-mcp/scripts/install.sh
#

set -euo pipefail

# Configuration
INSTALL_DIR="$HOME/.glm-mcp"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

# Verify dependencies
verify_dependencies() {
    print_step "Verifying dependencies..."

    local os
    os="$(detect_os)"
    local deps=()
    local missing=()

    case "$os" in
        macos)
            deps=("security" "node" "npx")
            ;;
        linux)
            deps=("node" "npx")
            ;;
        windows)
            deps=("node" "npx")
            ;;
        *)
            deps=("node" "npx")
            ;;
    esac

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_info "Please install missing dependencies and try again."
        return 1
    fi

    print_success "All required dependencies found"

    # Note about trash command
    local has_trash=0
    case "$os" in
        macos)
            if command -v trash &>/dev/null || command -v /opt/homebrew/bin/trash &>/dev/null; then
                has_trash=1
            fi
            ;;
        linux)
            if command -v gio &>/dev/null && gio help trash &>/dev/null; then
                has_trash=1
            elif command -v trash-cli &>/dev/null || command -v trash &>/dev/null; then
                has_trash=1
            fi
            ;;
        windows)
            has_trash=1  # Built-in recycle bin
            ;;
    esac

    if [[ $has_trash -eq 0 ]]; then
        print_warning "No trash command found (optional for install)"
        print_info "Uninstall will use rm -rf for permanent deletion"
    fi
}

# Create directory structure
create_directories() {
    print_step "Creating directory structure..."

    mkdir -p "$INSTALL_DIR/bin"
    mkdir -p "$INSTALL_DIR/config"
    mkdir -p "$INSTALL_DIR/scripts"

    print_success "Directories created: $INSTALL_DIR"
}

# Copy files
copy_files() {
    print_step "Copying files..."

    # Make scripts executable
    chmod +x "$PROJECT_DIR/bin/glm-mcp-wrapper"
    chmod +x "$PROJECT_DIR/bin/install-key.sh"
    chmod +x "$PROJECT_DIR/bin/claude-by-glm"
    chmod +x "$PROJECT_DIR/scripts/install.sh"
    chmod +x "$PROJECT_DIR/scripts/uninstall.sh"

    # Copy to install directory
    cp "$PROJECT_DIR/bin/glm-mcp-wrapper" "$INSTALL_DIR/bin/"
    cp "$PROJECT_DIR/bin/install-key.sh" "$INSTALL_DIR/bin/"
    cp "$PROJECT_DIR/bin/claude-by-glm" "$INSTALL_DIR/bin/"
    cp "$PROJECT_DIR/scripts/install.sh" "$INSTALL_DIR/scripts/"
    cp "$PROJECT_DIR/scripts/uninstall.sh" "$INSTALL_DIR/scripts/"

    print_success "Files copied to $INSTALL_DIR"
}

# Set file permissions
set_permissions() {
    print_step "Setting file permissions..."

    # Scripts should be executable only by owner
    chmod 500 "$INSTALL_DIR/bin/glm-mcp-wrapper"
    chmod 500 "$INSTALL_DIR/bin/install-key.sh"
    chmod 500 "$INSTALL_DIR/bin/claude-by-glm"
    chmod 500 "$INSTALL_DIR/scripts/install.sh"
    chmod 500 "$INSTALL_DIR/scripts/uninstall.sh"

    print_success "Permissions set"
}

# Backup existing .claude.json if needed
backup_claude_config() {
    local claude_json="$HOME/.claude.json"
    local backup_dir="$INSTALL_DIR/backups"

    if [[ -f "$claude_json" ]]; then
        mkdir -p "$backup_dir"
        local backup_file="$backup_dir/.claude.json.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$claude_json" "$backup_file"
        print_info "Backed up .claude.json to: $backup_file"
    fi
}

# Prompt for PATH configuration
configure_path() {
    echo
    print_step "PATH Configuration"
    echo
    print_info "Would you like to add ~/.glm-mcp/bin to your PATH?"
    echo
    echo "This allows you to run claude-by-glm from anywhere:"
    echo "  claude-by-glm <arguments>"
    echo
    echo "Options:"
    echo "  1) Yes - Add to shell config (recommended)"
    echo "  2) No  - Skip (you can manually add it later)"
    echo "  3) Skip - Don't ask again for this installation"
    echo
    read -rp "Choose [1/2/3]: " -n 1 -r
    echo

    case "$REPLY" in
        1)
            # Add PATH to shell config
            local shell
            local shell_config
            shell="$(detect_shell)"
            shell_config="$(get_shell_config "$shell")"

            if [[ -z "$shell_config" ]]; then
                print_error "Could not determine shell config file"
                print_info "Please manually add to your shell config:"
                echo "  export PATH=\"\$HOME/.glm-mcp/bin:\$PATH\""
                return 0
            fi

            # Backup existing config
            if [[ -f "$shell_config" ]]; then
                cp "$shell_config" "${shell_config}.backup.$(date +%Y%m%d_%H%M%S)"
            fi

            # Check if PATH already contains our bin directory
            if grep -q -F "PATH=\"\$HOME/.glm-mcp/bin:" "$shell_config" 2>/dev/null; then
                print_info "PATH already configured in $shell_config"
            else
                echo "
# GLM MCP Wrapper - Added by ~/.glm-mcp/scripts/install.sh
export PATH=\"\$HOME/.glm-mcp/bin:\$PATH\"" >> "$shell_config"
                print_success "PATH added to: $shell_config"
                print_info "Run: source $shell_config"
            fi
            ;;
        2)
            print_info "Skipped. You can manually add later:"
            echo "  export PATH=\"\$HOME/.glm-mcp/bin:\$PATH\""
            ;;
        3)
            # Create flag to skip PATH prompts in future
            touch "$INSTALL_DIR/.no-path-prompt"
            print_info "Skipped. Future installs will skip this prompt."
            print_info "To re-enable, remove: $INSTALL_DIR/.no-path-prompt"
            ;;
    esac
}

# Prompt for API key registration
prompt_api_key() {
    echo
    print_step "API Key Registration"
    echo
    read -rp "Register Z.ai API key now? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$INSTALL_DIR/bin/install-key.sh"
    else
        print_info "You can register later using: ~/.glm-mcp/bin/install-key.sh"
    fi
}

# Print next steps
print_next_steps() {
    local os
    os="$(detect_os)"
    local claude_json="$HOME/.claude.json"

    echo
    print_success "Installation complete!"
    echo
    echo "Installed: $INSTALL_DIR"
    echo
    echo "Next steps:"
    echo "  1. Register API key (if not done):"
    echo "     ~/.glm-mcp/bin/install-key.sh"
    echo
    echo "  2. Add to ~/.claude.json:"
    echo '     "glm-mcp-wrapper": {'
    echo '       "type": "stdio",'
    echo '       "command": "'"$INSTALL_DIR/bin/glm-mcp-wrapper"'",'
    echo '       "args": []'
    echo '     }'
    echo

    # Check if glm-mcp-wrapper already exists in config
    if [[ -f "$claude_json" ]] && grep -q "glm-mcp-wrapper" "$claude_json" 2>/dev/null; then
        print_info "Note: glm-mcp-wrapper already configured in ~/.claude.json"
    else
        print_info "Note: Don't forget to add glm-mcp-wrapper to ~/.claude.json"
    fi
    echo
    echo "  3. Run claude-by-glm:"
    if [[ ":$PATH:" == *:"$INSTALL_DIR/bin":* ]]; then
        echo "     claude-by-glm <arguments>"
    else
        echo "     ~/.glm-mcp/bin/claude-by-glm <arguments>"
        echo "     (Or add ~/.glm-mcp/bin to your PATH)"
    fi
    echo

    # OS-specific notes
    case "$os" in
        macos)
            echo "  4. Reload your shell to use PATH changes:"
            echo "     source ~/.zshrc   # or ~/.bashrc"
            ;;
        linux)
            echo "  Note: On Linux, install-key.sh uses 'security' command."
            echo "        For alternatives, consider secret-tool or passkey."
            ;;
        windows)
            echo "  Note: Keychain not supported on Windows."
            echo "        Use install-key.sh with direct API key input."
            ;;
    esac
    echo
}

# Main execution
main() {
    echo "=== GLM MCP Wrapper Installation ==="
    echo

    # Verify dependencies
    if ! verify_dependencies; then
        exit 1
    fi

    # Create directories
    create_directories

    # Copy files
    copy_files

    # Set permissions
    set_permissions

    # Backup existing config
    backup_claude_config

    # Configure PATH (skip if flag file exists)
    if [[ ! -f "$INSTALL_DIR/.no-path-prompt" ]]; then
        configure_path
    else
        print_info "PATH configuration skipped (.no-path-prompt exists)"
    fi

    # Prompt for API key
    prompt_api_key

    # Print next steps
    print_next_steps
}

main "$@"
