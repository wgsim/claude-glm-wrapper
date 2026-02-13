#!/bin/bash
#
# install.sh - Install GLM MCP wrapper system
#
# This script installs the GLM MCP wrapper to ~/.claude-glm-mcp/ and
# configures PATH and shell integration based on user preferences.
#
# Usage:
#   ~/.claude-glm-mcp/scripts/install.sh
#

set -euo pipefail

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source shared utilities
source "$PROJECT_DIR/scripts/common-utils.sh"

# Source security configuration for install directory
source "$PROJECT_DIR/credentials/common.sh"
INSTALL_DIR="${GLM_INSTALL_DIR:-$HOME/.claude-glm-mcp}"

# Validate installation directory for safety
validate_install_dir() {
    local raw="$1"

    # Must not be empty
    if [[ -z "$raw" ]]; then
        print_error "INSTALL_DIR is empty"
        return 1
    fi

    # Must be absolute path
    if [[ "$raw" != /* ]]; then
        print_error "INSTALL_DIR must be absolute path: $raw"
        return 1
    fi

    # Canonicalize if realpath available
    local canonical_dir
    if command -v realpath &>/dev/null; then
        canonical_dir="$(realpath "$raw")" || {
            print_error "Cannot resolve INSTALL_DIR: $raw"
            return 1
        }
    else
        canonical_dir="$raw"
    fi

    # Reject unsafe directories
    local canonical_home
    canonical_home="$(cd "$HOME" && pwd)"

    case "$canonical_dir" in
        ""|"/"|"/bin"|"/usr"|"/usr/bin"|"/usr/local"|"/etc"|"/var"|"$canonical_home")
            print_error "Refusing unsafe INSTALL_DIR: $canonical_dir"
            print_error "Cannot install to system directories or HOME root"
            return 1
            ;;
    esac

    # Update INSTALL_DIR with canonical path
    INSTALL_DIR="$canonical_dir"
    return 0
}

validate_install_dir "$INSTALL_DIR" || exit 1

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
    mkdir -p "$INSTALL_DIR/credentials"
    mkdir -p "$INSTALL_DIR/scripts"
    mkdir -p "$INSTALL_DIR/completion"

    print_success "Directories created: $INSTALL_DIR"
}

# Copy files
copy_files() {
    print_step "Copying files..."

    # Make scripts executable
    chmod +x "$PROJECT_DIR/bin/glm-mcp-wrapper"
    chmod +x "$PROJECT_DIR/bin/install-key.sh"
    chmod +x "$PROJECT_DIR/bin/claude-by-glm"
    chmod +x "$PROJECT_DIR/bin/glm-cleanup-sessions"
    chmod +x "$PROJECT_DIR/bin/glm-update"
    chmod +x "$PROJECT_DIR/scripts/install.sh"
    chmod +x "$PROJECT_DIR/scripts/uninstall.sh"

    # Copy to install directory
    cp -f "$PROJECT_DIR/bin/glm-mcp-wrapper" "$INSTALL_DIR/bin/"
    cp -f "$PROJECT_DIR/bin/install-key.sh" "$INSTALL_DIR/bin/"
    cp -f "$PROJECT_DIR/bin/claude-by-glm" "$INSTALL_DIR/bin/"
    cp -f "$PROJECT_DIR/bin/glm-cleanup-sessions" "$INSTALL_DIR/bin/"
    cp -f "$PROJECT_DIR/bin/glm-update" "$INSTALL_DIR/bin/"
    cp -f "$PROJECT_DIR/credentials/common.sh" "$INSTALL_DIR/credentials/"
    cp -f "$PROJECT_DIR/credentials/macos.sh" "$INSTALL_DIR/credentials/"
    cp -f "$PROJECT_DIR/credentials/linux.sh" "$INSTALL_DIR/credentials/"
    cp -f "$PROJECT_DIR/credentials/windows.sh" "$INSTALL_DIR/credentials/"
    cp -f "$PROJECT_DIR/credentials/security.conf" "$INSTALL_DIR/credentials/"
    cp -f "$PROJECT_DIR/scripts/install.sh" "$INSTALL_DIR/scripts/"
    cp -f "$PROJECT_DIR/scripts/uninstall.sh" "$INSTALL_DIR/scripts/"
    cp -f "$PROJECT_DIR/scripts/common-utils.sh" "$INSTALL_DIR/scripts/"
    # Copy completion scripts
    cp -f "$PROJECT_DIR/completion/glm-completion.bash" "$INSTALL_DIR/completion/" 2>/dev/null || true
    cp -f "$PROJECT_DIR/completion/glm-completion.zsh" "$INSTALL_DIR/completion/" 2>/dev/null || true
    cp -f "$PROJECT_DIR/completion/glm-completion.fish" "$INSTALL_DIR/completion/" 2>/dev/null || true

    print_success "Files copied to $INSTALL_DIR"
}

# Set file permissions
set_permissions() {
    print_step "Setting file permissions..."

    # Scripts should be executable only by owner
    chmod 500 "$INSTALL_DIR/bin/glm-mcp-wrapper"
    chmod 500 "$INSTALL_DIR/bin/install-key.sh"
    chmod 500 "$INSTALL_DIR/bin/claude-by-glm"
    chmod 500 "$INSTALL_DIR/bin/glm-cleanup-sessions"
    chmod 500 "$INSTALL_DIR/bin/glm-update"
    chmod 600 "$INSTALL_DIR/credentials/common.sh"
    chmod 600 "$INSTALL_DIR/credentials/macos.sh"
    chmod 600 "$INSTALL_DIR/credentials/linux.sh"
    chmod 600 "$INSTALL_DIR/credentials/windows.sh"
    chmod 600 "$INSTALL_DIR/credentials/security.conf"
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
        local timestamp
        timestamp="$(date +%Y%m%d_%H%M%S)"
        local backup_file="$backup_dir/.claude.json.backup.$timestamp"
        cp "$claude_json" "$backup_file"
        print_info "Backed up .claude.json to: $backup_file"
    fi
}

# Configure shell completion
configure_completion() {
    echo
    print_step "Shell Completion Configuration"
    echo
    print_info "Would you like to enable shell completion for GLM commands?"
    echo
    echo "This provides Tab completion for:"
    echo "  - glm-cleanup-sessions (options, session IDs)"
    echo "  - glm-update (options, directories)"
    echo
    echo "Options:"
    echo "  1) Yes - Add to shell config (recommended)"
    echo "  2) No  - Skip (you can manually add it later)"
    echo
    read -rp "Choose [1/2]: " -n 1 -r
    echo

    # Detect shell once for both options (fixes scope issue)
    local shell
    local shell_config
    local completion_file

    shell="$(detect_shell)"
    shell_config="$(get_shell_config "$shell")"

    case "$REPLY" in
        1)
            if [[ -z "$shell_config" ]]; then
                print_error "Could not determine shell config file"
                print_info "Please manually add completion to your shell config"
                return 0
            fi

            case "$shell" in
                bash)
                    completion_file="source \"$INSTALL_DIR/completion/glm-completion.bash\""
                    ;;
                zsh)
                    completion_file="source \"$INSTALL_DIR/completion/glm-completion.zsh\""
                    ;;
                fish)
                    # Fish uses a different mechanism
                    local fish_completion_dir="$HOME/.config/fish/completions"
                    mkdir -p "$fish_completion_dir" 2>/dev/null || true
                    cp -f "$INSTALL_DIR/completion/glm-completion.fish" "$fish_completion_dir/glm-cleanup-sessions.fish" 2>/dev/null || true
                    cp -f "$INSTALL_DIR/completion/glm-completion.fish" "$fish_completion_dir/glm-update.fish" 2>/dev/null || true
                    print_success "Fish completion installed to: $fish_completion_dir"
                    print_info "Restart fish or run: source $fish_completion_dir/glm-cleanup-sessions.fish"
                    return 0
                    ;;
                *)
                    print_warning "Unsupported shell for completion: $shell"
                    return 0
                    ;;
            esac

            # Backup existing config
            if [[ -f "$shell_config" ]]; then
                cp "$shell_config" "${shell_config}.backup.$(date +%Y%m%d_%H%M%S)"
            fi

            # Check if completion already exists
            if grep -q -F "glm-completion" "$shell_config" 2>/dev/null; then
                print_info "Completion already configured in $shell_config"
            else
                echo "
# GLM MCP Wrapper Completion - Added by ~/.claude-glm-mcp/scripts/install.sh
$completion_file" >> "$shell_config"
                print_success "Completion added to: $shell_config"
                print_info "Run: source $shell_config"
            fi
            ;;
        2)
            print_info "Skipped. You can manually add later:"
            case "$shell" in
                bash)
                    echo "  source \"$INSTALL_DIR/completion/glm-completion.bash\""
                    ;;
                zsh)
                    echo "  source \"$INSTALL_DIR/completion/glm-completion.zsh\""
                    ;;
                fish)
                    echo "  cp $INSTALL_DIR/completion/glm-completion.fish ~/.config/fish/completions/"
                    ;;
            esac
            ;;
    esac
}

# Prompt for PATH configuration
configure_path() {
    echo
    print_step "PATH Configuration"
    echo
    print_info "Would you like to add ~/.claude-glm-mcp/bin to your PATH?"
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
                echo "  export PATH=\"\$HOME/.claude-glm-mcp/bin:\$PATH\""
                return 0
            fi

            # Backup existing config
            if [[ -f "$shell_config" ]]; then
                cp "$shell_config" "${shell_config}.backup.$(date +%Y%m%d_%H%M%S)"
            fi

            # Check if PATH already contains our bin directory in CURRENT shell config
            if grep -q -F "PATH=\"\$HOME/.claude-glm-mcp/bin:" "$shell_config" 2>/dev/null; then
                print_info "PATH already configured in $shell_config"
            else
                # Also check if PATH exists in other common shell configs and inform user
                local found_in_other=""
                if [[ -f "$HOME/.bashrc" ]] && grep -q -F "\.claude-glm-mcp/bin" "$HOME/.bashrc" 2>/dev/null; then
                    found_in_other="\$HOME/.bashrc"
                elif [[ -f "$HOME/.zshrc" ]] && grep -q -F "\.claude-glm-mcp/bin" "$HOME/.zshrc" 2>/dev/null; then
                    found_in_other="\$HOME/.zshrc"
                fi

                if [[ -n "$found_in_other" && "$found_in_other" != "$shell_config" ]]; then
                    print_info "Note: PATH also exists in $found_in_other (different shell)"
                fi

                echo "
# GLM MCP Wrapper - Added by ~/.claude-glm-mcp/scripts/install.sh
export PATH=\"\$HOME/.claude-glm-mcp/bin:\$PATH\"" >> "$shell_config"
                print_success "PATH added to: $shell_config"
                print_info "Run: source $shell_config"
            fi
            ;;
        2)
            print_info "Skipped. You can manually add later:"
            echo "  export PATH=\"\$HOME/.claude-glm-mcp/bin:\$PATH\""
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
        print_info "You can register later using: ~/.claude-glm-mcp/bin/install-key.sh"
    fi
}

# Prompt for MCP server configuration
prompt_mcp_config() {
    echo
    print_step "MCP Server Configuration"
    echo
    echo "Enable MCP server?"
    echo " - Yes: Use Z.ai MCP tools (environment variable exposure risk)"
    echo " - No:  More secure, but no MCP tools"
    echo
    read -rp "Enable MCP server? [Y/n]: " -n 1 -r
    echo

    # Create config directory
    mkdir -p "$INSTALL_DIR/config" 2>/dev/null || true

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        # MCP enabled (default)
        echo "GLM_USE_MCP=1" > "$INSTALL_DIR/config/mcp.conf"
        print_success "MCP server enabled"
    else
        # MCP disabled
        echo "GLM_USE_MCP=0" > "$INSTALL_DIR/config/mcp.conf"
        print_info "MCP server disabled (more secure, no environment variable exposure)"
    fi
    echo
}

# Setup isolated CLAUDE_CONFIG_DIR for GLM sessions
# Creates ~/.claude-glm with symlinks to shared resources and copied settings
setup_claude_config_dir() {
    print_step "Setting up GLM config directory (~/.claude-glm)..."

    local glm_config="$HOME/.claude-glm"
    local claude_config="$HOME/.claude"

    if ! mkdir -p "$glm_config" 2>/dev/null; then
        print_error "Failed to create GLM config directory: $glm_config"
        print_info "Check filesystem permissions and available disk space"
        return 1
    fi

    if ! mkdir -p "$glm_config/glm-sessions" 2>/dev/null; then
        print_error "Failed to create sessions directory"
        return 1
    fi

    # Symlink shared resources (only if source exists)
    local symlink_targets=("plugins" "commands" "projects" "todos" "statsig" "CLAUDE.md")
    for target in "${symlink_targets[@]}"; do
        local src="$claude_config/$target"
        local dst="$glm_config/$target"
        if [[ -e "$src" ]] && [[ ! -e "$dst" ]]; then
            if ! ln -s "$src" "$dst" 2>/dev/null; then
                print_warning "Failed to symlink $target (non-critical, continuing)"
            else
                print_info "Symlinked: $target"
            fi
        elif [[ -L "$dst" ]]; then
            # Already a symlink, verify it points correctly
            local current_target
            current_target="$(readlink "$dst" 2>/dev/null || true)"
            if [[ "$current_target" != "$src" ]]; then
                # Use ln -sf to atomically replace symlink (no rm needed)
                ln -sf "$src" "$dst"
                print_info "Re-linked: $target"
            fi
        fi
    done

    # Copy settings files (GLM-specific, not symlinked)
    # Use settings.glm.json as source if available, otherwise copy from ~/.claude/
    local settings_src="$claude_config/settings.glm.json"
    if [[ ! -f "$settings_src" ]]; then
        settings_src="$claude_config/settings.json"
    fi
    if [[ -f "$settings_src" ]] && [[ ! -f "$glm_config/settings.json" ]]; then
        if ! cp "$settings_src" "$glm_config/settings.json" 2>/dev/null; then
            print_error "Failed to copy settings.json for GLM"
            print_info "Source: $settings_src"
            print_info "Check filesystem permissions and available disk space"
            return 1
        fi
        print_info "Copied settings.json for GLM"
    fi

    if [[ -f "$claude_config/settings.local.json" ]] && [[ ! -f "$glm_config/settings.local.json" ]]; then
        if ! cp "$claude_config/settings.local.json" "$glm_config/settings.local.json" 2>/dev/null; then
            print_error "Failed to copy settings.local.json for GLM"
            print_info "Check filesystem permissions and available disk space"
            return 1
        fi
        print_info "Copied settings.local.json for GLM"
    fi

    print_success "GLM config directory ready: $glm_config"
}

# Create GLM settings file
create_glm_settings() {
    print_step "Creating GLM settings file..."

    local glm_settings="$HOME/.claude/settings.glm.json"

    # Skip if already exists (preserve user modifications)
    if [[ -f "$glm_settings" ]]; then
        print_info "Settings file already exists: $glm_settings"
        print_info "Preserving existing configuration"
        return 0
    fi

    # Check if claude-dashboard is available
    local dashboard_line=""
    if [[ -f "$HOME/.claude/plugins/cache/claude-dashboard/claude-dashboard" ]]; then
        local dashboard_path
        dashboard_path=$(find "$HOME/.claude/plugins/cache/claude-dashboard/claude-dashboard" -name "index.js" -path "*/dist/*" 2>/dev/null | head -1)
        if [[ -n "$dashboard_path" ]]; then
            dashboard_line="  \"statusLine\": {
    \"type\": \"command\",
    \"command\": \"node $dashboard_path\"
  },"
        fi
    fi

    # Create settings.glm.json WITHOUT enabledPlugins
    # This allows Claude to auto-detect plugins from installed_plugins.json
    # Also set the default GLM model to prevent interference from other sessions
    # Use "opus" alias which maps to glm-4.7 via ANTHROPIC_DEFAULT_OPUS_MODEL env var
    cat > "$glm_settings" << EOF
{
  "model": "opus",$dashboard_line
}
EOF

    print_success "Created: $glm_settings"
    print_info "Plugins will be auto-detected from installed_plugins.json"
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
    echo "     ~/.claude-glm-mcp/bin/install-key.sh"
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
        echo "     ~/.claude-glm-mcp/bin/claude-by-glm <arguments>"
        echo "     (Or add ~/.claude-glm-mcp/bin to your PATH)"
    fi
    echo

    # OS-specific notes
    case "$os" in
        macos)
            echo "  4. Reload your shell to use changes:"
            echo "     source ~/.zshrc   # or ~/.bashrc"
            ;;
        linux)
            echo "  4. Reload your shell to use changes:"
            echo "     source ~/.bashrc  # or ~/.zshrc"
            echo
            echo "  Note: On Linux, install-key.sh requires 'secret-tool' (libsecret)."
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

    # Check for existing installation
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Existing installation found at: $INSTALL_DIR"
        echo
        echo "Options:"
        echo "  1) Uninstall first, then reinstall (recommended)"
        echo "  2) Overwrite existing files"
        echo "  3) Cancel"
        echo
        read -rp "Choose [1/2/3]: " -n 1 -r
        echo
        echo

        case "$REPLY" in
            1)
                print_step "Uninstalling existing installation..."
                # Directly remove the installation directory
                if command -v /opt/homebrew/opt/trash/bin/trash &>/dev/null; then
                    /opt/homebrew/opt/trash/bin/trash "$INSTALL_DIR"
                    print_success "Moved to trash: $INSTALL_DIR"
                elif command -v trash &>/dev/null; then
                    trash "$INSTALL_DIR"
                    print_success "Moved to trash: $INSTALL_DIR"
                else
                    rm -rf "$INSTALL_DIR"
                    print_success "Removed: $INSTALL_DIR"
                fi
                # Wait a moment for filesystem sync
                sleep 1
                ;;
            2)
                print_info "Will overwrite existing installation"
                # Remove restrictive files that might cause issues
                rm -f "$INSTALL_DIR/bin/"* 2>/dev/null || true
                rm -f "$INSTALL_DIR/credentials/"* 2>/dev/null || true
                rm -f "$INSTALL_DIR/scripts/"* 2>/dev/null || true
                ;;
            3)
                print_info "Installation cancelled"
                exit 0
                ;;
            *)
                print_info "Installation cancelled"
                exit 0
                ;;
        esac
    fi

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

    # Configure shell completion
    configure_completion

    # Prompt for API key
    prompt_api_key

    # Prompt for MCP configuration
    prompt_mcp_config

    # Setup isolated config directory for GLM
    setup_claude_config_dir

    # Create GLM settings file
    create_glm_settings

    # Print next steps
    print_next_steps
}

main "$@"
