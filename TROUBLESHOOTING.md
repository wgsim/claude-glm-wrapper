# Troubleshooting Guide

Common issues and solutions for GLM MCP Wrapper System.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [API Key Issues](#api-key-issues)
3. [MCP Wrapper Issues](#mcp-wrapper-issues)
4. [Claude-by-glm Issues](#claude-by-glm-issues)
5. [Configuration Issues](#configuration-issues)
6. [Platform-Specific Issues](#platform-specific-issues)

## Installation Issues

### "command not found: npx"

**Cause**: Node.js not installed or not in PATH.

**Solution**:
```bash
# Install Node.js via Homebrew (macOS)
brew install node

# Verify installation
node --version
npx --version
```

### "security: command not found"

**Cause**: Only on macOS. Linux/Windows don't have this command.

**Solution**:
- **macOS**: Should be available by default. Try `xcode-select --install`
- **Linux**: Use `secret-tool` (libsecret) or alternative credential storage
- **Windows**: Not supported, use direct API key input

### Permission Denied on Scripts

**Cause**: Scripts not executable.

**Solution**:
```bash
chmod +x ~/.glm-mcp/bin/*
chmod +x ~/.glm-mcp/scripts/*
```

### Install Script Fails at Dependency Check

**Cause**: Missing required dependencies.

**Solution**:
```bash
# Check each dependency
command -v node
command -v npx
command -v security  # macOS only

# Install missing dependencies
brew install node  # macOS
```

## API Key Issues

### "Failed to retrieve Z.ai API key from keychain"

**Cause**: API key not stored in keychain or wrong service/account.

**Solution**:
```bash
# Check if key exists
security find-generic-password -s "z.ai-api-key" -a "$USER" -w

# If not found, register it
~/.glm-mcp/bin/install-key.sh
```

### "security: SecKeychainItemCopyGenericPassword: The specified item could not be found in the keychain"

**Cause**: Keychain entry doesn't exist.

**Solution**:
```bash
# Register your Z.ai API key
~/.glm-mcp/bin/install-key.sh
```

**Note**: This system uses a single `z.ai-api-key` entry for both model API and MCP server.

### Wrong API Key Stored

**Cause**: Old or incorrect API key in keychain.

**Solution**:
```bash
# Delete and re-register
security delete-generic-password -s "z.ai-api-key" -a "$USER"
~/.glm-mcp/bin/install-key.sh
```

## MCP Wrapper Issues

### Wrapper Not Connecting

**Cause**: `GLM_MODE` not set or wrong keychain service.

**Solution**:
```bash
# Check if GLM_MODE is set
echo $GLM_MODE

# Test wrapper directly
GLM_MODE=1 ~/.glm-mcp/bin/glm-mcp-wrapper

# Should show MCP server output, not "sleep infinity"
```

### Claude Code Shows "No MCP Tools Available"

**Cause**: MCP server not configured in `~/.claude.json` or GLM_MODE not set.

**Solution**:
```bash
# Check .claude.json configuration
cat ~/.claude.json | grep -A 5 glm-mcp-wrapper

# Should show:
# "glm-mcp-wrapper": {
#   "type": "stdio",
#   "command": "/Users/YOUR_USERNAME/.glm-mcp/bin/glm-mcp-wrapper",
#   "args": []
# }

# Verify GLM_MODE is set by claude-by-glm
grep GLM_MODE ~/.glm-mcp/bin/claude-by-glm
```

### Wrapper Path Incorrect in .claude.json

**Cause**: Hardcoded path from different machine or user.

**Solution**:
```bash
# Get your username
echo $USER

# Update ~/.claude.json with correct path
# Replace YOUR_USERNAME with your actual username
```

## Claude-by-glm Issues

### "claude: command not found"

**Cause**: Claude Code not installed or not in PATH.

**Solution**:
```bash
# Check if Claude Code is installed
which claude

# Install Claude Code if needed
# Visit: https://claude.ai/download
```

### claude-by-glm: command not found

**Cause**: PATH not configured.

**Solution**:
```bash
# Use full path
~/.glm-mcp/bin/claude-by-glm

# Or add to PATH (see INSTALL.md)
export PATH="$HOME/.glm-mcp/bin:$PATH"
```

### Wrong Models Being Used

**Cause**: Environment variables not set correctly.

**Solution**:
```bash
# Check environment variables in claude-by-glm
grep ANTHROPIC ~/.glm-mcp/bin/claude-by-glm

# Should show:
# ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
# ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
# ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.6"
# ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.7"
```

### API Key Not Found

**Cause**: Z.ai API key (`z.ai-api-key`) not stored in keychain.

**Solution**:
```bash
# Check if key exists
security find-generic-password -s "z.ai-api-key" -a "$USER" -w

# If not found, register it
~/.glm-mcp/bin/install-key.sh
```

## Configuration Issues

### .claude.json Not Found

**Cause**: Claude Code not configured yet.

**Solution**:
```bash
# Create config directory
mkdir -p ~/.claude

# Create basic config
cat > ~/.claude.json << 'EOF'
{
  "mcpServers": {}
}
EOF
```

### Multiple Claude Configurations Conflict

**Cause**: Both `~/.claude.json` and project-specific `.claude/` exist.

**Solution**:
```bash
# Check for multiple configs
find ~ -name ".claude.json" -o -name "claude.json" 2>/dev/null
find ~ -type d -name ".claude" 2>/dev/null

# Claude Code merges configs, but MCP servers from ~/.claude.json take precedence
```

### PATH Not Updated After Installation

**Cause**: Shell config not reloaded or wrong shell detected.

**Solution**:
```bash
# Detect current shell
echo $SHELL

# Reload appropriate config
source ~/.zshrc    # zsh
source ~/.bashrc   # bash
source ~/.config/fish/config.fish  # fish

# Verify PATH
echo $PATH | grep glm-mcp
```

## Platform-Specific Issues

### macOS: Keychain Permission Prompt

**Issue**: System prompts for keychain access when running scripts.

**Solution**:
1. Click "Always Allow" when prompted
2. Or manually allow in Keychain Access:
   - Open Keychain Access app
   - Find "z.ai-api-key"
   - Get Info → Access Control → Add `node`, `npx`, `/bin/bash`

### Linux: No `security` Command

**Cause**: `security` is macOS-only.

**Workaround**:
```bash
# Install secret-tool (libsecret)
sudo apt-get install libsecret-tools  # Ubuntu/Debian
sudo dnf install libsecret-tools      # Fedora

# Alternative: Use environment variable (less secure)
export ZAI_API_KEY="your_key_here"
```

### Windows: Keychain Not Supported

**Cause**: Windows doesn't have macOS-style keychain.

**Workaround**:
```bash
# Use Windows Credential Manager
# Or set environment variable (less secure)
setx ZAI_API_KEY "your_key_here"
```

## Debug Commands

### Full Installation Check

```bash
# Check all files exist
ls -la ~/.glm-mcp/bin/
ls -la ~/.glm-mcp/scripts/

# Check permissions
stat -f "%Lp %N" ~/.glm-mcp/bin/*  # macOS
stat -c "%a %n" ~/.glm-mcp/bin/*   # Linux

# Check keychain entry (single key for both purposes)
security find-generic-password -s "z.ai-api-key" -a "$USER" -w

# Check .claude.json
cat ~/.claude.json | python3 -m json.tool

# Check PATH
echo $PATH | tr ':' '\n' | grep glm
```

### Test Wrapper Directly

```bash
# Test with GLM_MODE enabled
GLM_MODE=1 ~/.glm-mcp/bin/glm-mcp-wrapper

# Test with GLM_MODE disabled (should sleep)
~/.glm-mcp/bin/glm-mcp-wrapper

# Check for syntax errors
bash -n ~/.glm-mcp/bin/glm-mcp-wrapper
bash -n ~/.glm-mcp/bin/claude-by-glm
```

### Enable Debug Output

Add to scripts for troubleshooting:

```bash
# Add to top of script
set -x  # Enable debug output

# Or add specific debug prints
echo "DEBUG: GLM_MODE=$GLM_MODE" >&2
echo "DEBUG: API_KEY_LENGTH=${#API_KEY}" >&2
```

## Getting Help

If issues persist:

1. Check error messages carefully
2. Run debug commands above
3. Verify all prerequisites are installed
4. Try reinstalling: `~/.glm-mcp/scripts/uninstall.sh` then `./scripts/install.sh`
5. Check GitHub Issues for similar problems
6. Create new issue with:
   - macOS/Linux version
   - Node.js version
   - Full error message
   - Output of debug commands
