# Installation Guide

GLM MCP Wrapper System - Use Z.ai GLM models with Claude Code while keeping API keys secure in platform credential storage.

## Prerequisites

### Required

- **Node.js** (v18 or higher recommended)
- **npx** (comes with Node.js)

### Platform-Specific Requirements

#### macOS
- `security` command (built-in)

#### Linux
- `secret-tool` from libsecret-tools
  - Ubuntu/Debian: `sudo apt-get install libsecret-tools`
  - Fedora/RHEL: `sudo dnf install libsecret-tools`
  - Arch: `sudo pacman -S libsecret`

#### Windows
- PowerShell (built-in)
- Environment variable `ZAI_API_KEY` must be set manually

### Verify Prerequisites

```bash
# Check Node.js
node --version

# Check npx
npx --version

# macOS: check security command
security help | head -5        # macOS only

# Linux: check secret-tool
secret-tool --version          # Linux only

# Windows: check PowerShell
powershell.exe -Command "echo OK"  # Windows only
```

## Installation Steps

### 1. Clone or Download

```bash
cd /path/to/your/projects
git clone <repository-url> claude-by-glm_safety_setting
cd claude-by-glm_safety_setting
```

### 2. Run Install Script

```bash
./scripts/install.sh
```

The installer will:
- Verify dependencies (Node.js, npx, platform-specific tools)
- Create directory structure at `~/.glm-mcp/`
- Copy executable files
- Set appropriate permissions (500 for scripts)
- Prompt for PATH configuration
- Prompt for API key registration
- Prompt for MCP server configuration

### 3. Installation Prompts

#### PATH Configuration

```
PATH Configuration
INFO: Would you like to add ~/.glm-mcp/bin to your PATH?

Options:
  1) Yes - Add to shell config (recommended)
  2) No  - Skip (you can manually add it later)
  3) Skip - Don't ask again for this installation

Choose [1/2/3]:
```

- **Option 1**: Automatically adds to your shell config (`~/.zshrc`, `~/.bashrc`, or `~/.config/fish/config.fish`)
- **Option 2**: Manually add later (see below)
- **Option 3**: Creates `.no-path-prompt` flag to skip future prompts

#### MCP Server Configuration

```
MCP Server Configuration
Enable MCP server?
 - Yes: Use Z.ai MCP tools (environment variable exposure risk)
 - No:  More secure, but no MCP tools

Enable MCP server? [Y/n]:
```

- **Yes** (default): Enables MCP server with Z.ai MCP tools
  - Creates `~/.glm-mcp/config/mcp.conf` with `GLM_USE_MCP=1`
  - Environment variable `ZAI_API_KEY` will be exposed to subprocesses
- **No**: Disables MCP server for enhanced security
  - Creates `~/.glm-mcp/config/mcp.conf` with `GLM_USE_MCP=0`
  - No environment variable exposure
  - No MCP tools available

**Security Note**: MCP server requires the API key to be available as an environment variable to the Z.ai MCP server process. While the wrapper minimizes exposure time (using `unset` and `ulimit -c 0`), there is a brief window where the key could be accessed via `ps` or `/proc`. If you need maximum security, choose "No" to disable MCP.

#### API Key Registration

```
API Key Registration
Register Z.ai API key now? (y/N):
```

- **Yes**: Runs `install-key.sh` to store API key in platform credential storage
- **No**: You can register later using `~/.glm-mcp/bin/install-key.sh`

**Important**: The system uses a **single** Z.ai API key for:
- Direct model API calls (via `claude-by-glm`)
- Z.ai MCP server tools (via `glm-mcp-wrapper`)

Both components read from the same credential entry: `z.ai-api-key`

## Post-Installation

### 1. Register API Key

The system uses a **single** Z.ai API key for both model API and MCP server.

```bash
~/.glm-mcp/bin/install-key.sh
```

This stores your API key with:
- **Service**: `z.ai-api-key`
- **Account**: Your username (`$USER`)

**Platform Storage**:
- **macOS**: Keychain (security command)
- **Linux**: libsecret (secret-tool)
- **Windows**: Environment variable `ZAI_API_KEY` (set manually)

Get your API key from: https://z.ai/subscribe?ic=EBGYZCJRYJ

**How it works**: Both `claude-by-glm` (for model API) and `glm-mcp-wrapper` (for MCP server) fetch from the same credential storage entry.

### 2. Configure Claude Code

Edit `~/.claude.json` and add the MCP server:

```json
{
  "mcpServers": {
    "glm-mcp-wrapper": {
      "type": "stdio",
      "command": "/Users/YOUR_USERNAME/.glm-mcp/bin/glm-mcp-wrapper",
      "args": []
    }
  }
}
```

Replace `YOUR_USERNAME` with your actual username.

### 3. Verify Installation

```bash
# Test GLM mode activation
GLM_MODE=1 ~/.glm-mcp/bin/glm-mcp-wrapper
# Should connect to Z.ai MCP server (may error if API key not set)

# Test claude-by-glm launcher
~/.glm-mcp/bin/claude-by-glm --version
# Should show Claude Code version
```

## Manual PATH Configuration

If you chose not to configure PATH during installation, add this to your shell config:

### Zsh (`~/.zshrc`)

```bash
# GLM MCP Wrapper
export PATH="$HOME/.glm-mcp/bin:$PATH"
```

### Bash (`~/.bashrc`)

```bash
# GLM MCP Wrapper
export PATH="$HOME/.glm-mcp/bin:$PATH"
```

### Fish (`~/.config/fish/config.fish`)

```bash
# GLM MCP Wrapper
fish_add_path $HOME/.glm-mcp/bin
```

Reload your shell:

```bash
source ~/.zshrc   # or ~/.bashrc for bash
```

## Usage

### Running claude-by-glm

```bash
# If PATH is configured
claude-by-glm [arguments]

# If PATH is not configured
~/.glm-mcp/bin/claude-by-glm [arguments]
```

### How It Works

1. **`claude-by-glm`** fetches API key from credential storage (`z.ai-api-key`)
2. Sets environment variables for Z.ai GLM models
3. Loads MCP configuration from `~/.glm-mcp/config/mcp.conf`
4. If `GLM_USE_MCP=1`, sets `GLM_MODE=1` to activate MCP wrapper
5. Launches `claude` command
6. **MCP wrapper** detects `GLM_MODE=1`, fetches API key from credential storage, connects to Z.ai MCP server

### Official Claude (without GLM)

When running `claude` directly (not via `claude-by-glm`):
- `GLM_MODE` is not set
- MCP wrapper stays inactive (sleeps)
- Uses official Anthropic models

## Configuration

### MCP Server Toggle

You can enable or disable MCP server after installation:

```bash
# Enable MCP server (with tools, has env var exposure risk)
echo "GLM_USE_MCP=1" > ~/.glm-mcp/config/mcp.conf

# Disable MCP server (more secure, no MCP tools)
echo "GLM_USE_MCP=0" > ~/.glm-mcp/config/mcp.conf
```

### Verify Current Configuration

```bash
cat ~/.glm-mcp/config/mcp.conf
```

## Uninstallation

```bash
~/.glm-mcp/scripts/uninstall.sh
```

The uninstaller will:
- Remove PATH from shell config (optional)
- Remove API key from credential storage (platform-specific)
- Move installation directory to trash (or permanently delete if trash unavailable)
- Prompt to edit `~/.claude.json` to remove MCP server configuration

## Installation Directory

```
~/.glm-mcp/
├── bin/
│   ├── glm-mcp-wrapper      # MCP wrapper script
│   ├── install-key.sh       # API key registration
│   └── claude-by-glm        # Main launcher
├── config/
│   └── mcp.conf             # MCP server configuration (GLM_USE_MCP)
├── credentials/
│   ├── common.sh            # Credential abstraction layer
│   ├── macos.sh             # macOS Keychain implementation
│   ├── linux.sh             # Linux libsecret implementation
│   └── windows.sh           # Windows env var implementation
├── scripts/
│   ├── install.sh           # This installer
│   └── uninstall.sh         # Uninstaller
└── backups/
    └── .claude.json.backup.*  # Config backups
```

## File Permissions

All executable scripts have permission `500` (owner read/execute only):

```bash
chmod 500 ~/.glm-mcp/bin/*
chmod 500 ~/.glm-mcp/scripts/*
```

## Next Steps

- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- See [SECURITY.md](SECURITY.md) for security information
- See [README.md](README.md) for overview
