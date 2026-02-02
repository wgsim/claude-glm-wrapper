# GLM MCP Wrapper System

Use Z.ai GLM models (glm-4.5-air, glm-4.6, glm-4.7) with Claude Code while keeping API keys secure in macOS keychain.

## Features

- **Single API Key**: Uses ONE Z.ai API key for both model API and MCP server
- **Secure Storage**: macOS keychain, no hardcoded credentials in JSON
- **Dual Mode**: Same configuration works for both official Claude and GLM models
- **MCP Tools**: Access to Z.ai MCP server tools when in GLM mode
- **macOS Native**: Full keychain integration, secure credential management

## Quick Start

```bash
# Install
./scripts/install.sh

# Register your Z.ai API key (single key for both purposes)
~/.glm-mcp/bin/install-key.sh

# Add to ~/.claude.json
# "glm-mcp-wrapper": {
#   "type": "stdio",
#   "command": "/Users/YOUR_USERNAME/.glm-mcp/bin/glm-mcp-wrapper",
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
~/.glm-mcp/
├── bin/
│   ├── glm-mcp-wrapper      # MCP wrapper (GLM_MODE aware)
│   ├── install-key.sh       # API key registration
│   └── claude-by-glm        # Main launcher
├── scripts/
│   ├── install.sh           # Installer
│   └── uninstall.sh         # Uninstaller
└── config/
    └── claude-by-glm-update.md
```

## Requirements

- Node.js (v18+) with npx
- macOS (primary), Linux (partial)
- Claude Code installed

## License

MIT
