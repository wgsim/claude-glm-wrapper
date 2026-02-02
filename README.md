# GLM MCP Wrapper System

Use Z.ai GLM models (glm-4.5-air, glm-4.6, glm-4.7) with Claude Code while keeping API keys secure in platform credential storage.

## Features

- **Single API Key**: Uses ONE Z.ai API key for both model API and Z.ai MCP server
- **Multi-Platform**: macOS (Keychain), Linux (libsecret), Windows (env var)
- **Secure Storage**: Platform credential storage, no hardcoded credentials in JSON
- **Dual Mode**: Same configuration works for both official Claude and GLM models
- **Optional Z.ai MCP**: Configurable Z.ai MCP server - enable tools or maximize security
- **Security Hardened**: Restrictive ACLs, core dump prevention, env var cleanup

## Quick Start

```bash
# Install
./scripts/install.sh

# Register your Z.ai API key (single key for both purposes)
~/.claude-glm-mcp/bin/install-key.sh

# Configure MCP (optional)
echo "GLM_USE_MCP=1" > ~/.claude-glm-mcp/config/mcp.conf  # Enable Z.ai MCP
# OR
echo "GLM_USE_MCP=0" > ~/.claude-glm-mcp/config/mcp.conf  # Disable (more secure)

# Add to ~/.claude.json
# "glm-mcp-wrapper": {
#   "type": "stdio",
#   "command": "/Users/YOUR_USERNAME/.claude-glm-mcp/bin/glm-mcp-wrapper",
#   "args": []
# }

# Run
claude-by-glm [arguments]
```

## Documentation

- [INSTALL.md](INSTALL.md) - Detailed installation guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [SECURITY.md](SECURITY.md) - Security information

## Architecture

```
claude-by-glm
    ↓ (sets GLM_MODE=1)
Claude Code reads ~/.claude.json
    ↓
glm-mcp-wrapper (activated by GLM_MODE)
    ↓ (fetches API key from keychain)
Z.ai MCP Server
```

## Installation Directory

```
~/.claude-glm-mcp/
├── bin/
│   ├── glm-mcp-wrapper      # MCP wrapper (GLM_MODE aware)
│   ├── install-key.sh       # API key registration
│   └── claude-by-glm        # Main launcher
├── config/
│   └── mcp.conf             # MCP configuration (GLM_USE_MCP)
├── credentials/
│   ├── common.sh            # Credential abstraction layer
│   ├── macos.sh             # macOS Keychain
│   ├── linux.sh             # Linux libsecret
│   └── windows.sh           # Windows env var
├── scripts/
│   ├── install.sh           # Installer
│   └── uninstall.sh         # Uninstaller
└── backups/
    └── .claude.json.backup.*
```

## Requirements

- Node.js (v18+) with npx
- **macOS**: `security` command (built-in)
- **Linux**: `secret-tool` from libsecret-tools
- **Windows**: PowerShell (built-in), manual env var setup
- Claude Code installed

## MCP Configuration

The Z.ai MCP server can be enabled or disabled via configuration:

```bash
# Enable Z.ai MCP (default, has tools)
echo "GLM_USE_MCP=1" > ~/.claude-glm-mcp/config/mcp.conf

# Disable Z.ai MCP (more secure, no tools)
echo "GLM_USE_MCP=0" > ~/.claude-glm-mcp/config/mcp.conf
```

**Security Note**: When MCP is enabled, the API key is briefly exposed as an environment variable to the Z.ai MCP server. The wrapper minimizes this exposure with `unset` and `ulimit -c 0`, but there's a small window where the key could be accessed via `ps` or `/proc`. Disable MCP if you need maximum security.

## License

MIT
