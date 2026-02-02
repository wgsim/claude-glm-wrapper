# Installation Guide

GLM MCP Wrapper System - Use Z.ai GLM models with Claude Code while keeping API keys secure in macOS keychain.

## Prerequisites

### Required

- **Node.js** (v18 or higher recommended)
- **npx** (comes with Node.js)
- **macOS** (primary support), Linux (partial), Windows (partial)

### Verify Prerequisites

```bash
# Check Node.js
node --version

# Check npx
npx --version

# Check macOS security command
security help | head -5
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
- Verify dependencies (Node.js, npx, security)
- Create directory structure at `~/.glm-mcp/`
- Copy executable files
- Set appropriate permissions (500 for scripts)
- Prompt for PATH configuration
- Prompt for API key registration

### 3. Installation Prompts

#### API Key Registration

```
API Key Registration
Register Z.ai API key now? (y/N):
```

- **Yes**: Runs `install-key.sh` to store API key in macOS keychain
- **No**: You can register later using `~/.glm-mcp/bin/install-key.sh`

**Important**: The system uses a **single** Z.ai API key for:
- Direct model API calls (via `claude-by-glm`)
- Z.ai MCP server tools (via `glm-mcp-wrapper`)

Both components read from the same keychain entry: `z.ai-api-key`

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

#### API Key Registration

```
API Key Registration
Register Z.ai API key now? (y/N):
```

- **Yes**: Runs `install-key.sh` to store API key in macOS keychain
- **No**: You can register later using `~/.glm-mcp/bin/install-key.sh`

## Post-Installation

### 1. Register API Key

The system uses a **single** Z.ai API key for both model API and MCP server.

```bash
~/.glm-mcp/bin/install-key.sh
```

This stores your API key with:
- **Service**: `z.ai-api-key`
- **Account**: Your username (`$USER`)

Get your API key from: https://z.ai/subscribe?ic=EBGYZCJRYJ

**How it works**: Both `claude-by-glm` (for model API) and `glm-mcp-wrapper` (for MCP server) fetch from the same keychain entry.

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

1. **`claude-by-glm`** fetches GLM model API key from keychain (`glm-coding-plan`)
2. Sets environment variables for Z.ai GLM models
3. Sets `GLM_MODE=1` to activate MCP wrapper
4. Launches `claude` command
5. **MCP wrapper** detects `GLM_MODE=1`, fetches wrapper API key, connects to Z.ai MCP server

### Official Claude (without GLM)

When running `claude` directly (not via `claude-by-glm`):
- `GLM_MODE` is not set
- MCP wrapper stays inactive (sleeps)
- Uses official Anthropic models

## Uninstallation

```bash
~/.glm-mcp/scripts/uninstall.sh
```

The uninstaller will:
- Remove PATH from shell config (optional)
- Remove GLM model API key from keychain (macOS only)
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
│   └── claude-by-glm-update.md
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
