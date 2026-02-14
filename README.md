# GLM MCP Wrapper System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0.13-green)](https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.13)
[![Security](https://img.shields.io/badge/security-hardened-brightgreen)](SECURITY.md)
[![Gitleaks](https://img.shields.io/badge/secrets-0%20found-success)](https://github.com/gitleaks/gitleaks)
[![Shell](https://img.shields.io/badge/shell-bash%203.2%2B-blue)](bin/claude-by-glm)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)](INSTALL.md)

**Production-ready wrapper to use [Z.ai GLM models](https://z.ai/) (GLM 4.6, 4.7, 5) with Claude Code — with enterprise-grade credential protection.**

No more API keys in config files. No more credential leaks. Just secure, isolated sessions backed by your OS credential manager.

> **🔒 Security-First Design**: Comprehensive security review • Zero known vulnerabilities • PASS verdict from security auditors
>
> **🚀 Production Ready**: Automated secret scanning • Pre-commit hooks • Comprehensive credential protection • Session isolation

## Features

- **Single API Key**: Uses ONE Z.ai API key for both model API and Z.ai MCP server
- **Multi-Platform**: macOS (Keychain), Linux (libsecret), Windows (env var)
- **Secure Storage**: Platform credential storage, no hardcoded credentials in JSON
- **Dual Mode**: Same configuration works for both official Claude and GLM models
- **Optional Z.ai MCP**: Configurable Z.ai MCP server - enable tools or maximize security
- **Session Isolation**: GLM sessions use isolated settings, don't affect default Claude
- **Easy Updates**: Built-in update utility without full reinstall
- **Security Hardened**: Input validation, restrictive ACLs, core dump prevention, env var cleanup

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

# Check versions
claude-by-glm --version        # Claude Code version
claude-by-glm --glm-version    # GLM MCP Wrapper version
```

## Documentation

- [INSTALL.md](INSTALL.md) - Detailed installation guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [SECURITY.md](SECURITY.md) - Security information
- [ROADMAP.md](ROADMAP.md) - Future development plans

## Architecture

### High-Level Flow

```
User runs: claude-by-glm [arguments]
    ↓
1. Set CLAUDE_CONFIG_DIR=~/.claude-glm (session isolation)
2. Fetch API key from platform credential storage
   (macOS Keychain / Linux libsecret / Windows ENV)
3. Set GLM_MODE=1 (optional MCP activation)
4. Launch Claude Code with isolated config
    ↓
Claude Code reads ~/.claude.json
    ↓ (if GLM_MODE=1 and GLM_USE_MCP=1)
glm-mcp-wrapper
    ↓
Z.ai MCP Server (optional)
```

### Session Isolation (v2.0.0+)

GLM sessions use separate config directory to prevent settings pollution:

```
Official Claude:  uses ~/.claude/
GLM Sessions:     uses ~/.claude-glm/
                       ↓
                  Isolated settings, plugins, projects
                  No interference with official Claude sessions
```

### Security Architecture (v2.0.13)

```
Security Layers:
1. Trusted PATH (/usr/bin:/bin:/usr/sbin:/sbin)
2. All external commands use absolute paths
3. Session setup completes BEFORE credential fetch
4. Credentials never exposed to user-modifiable PATH
5. Platform credential storage (never in config files)
6. Session cleanup on exit
```

## Directory Structure

### Installation Directory (~/.claude-glm-mcp/)

Where the wrapper is installed:

```
~/.claude-glm-mcp/
├── bin/
│   ├── claude-by-glm        # Main launcher (sets up environment)
│   ├── glm-mcp-wrapper      # MCP wrapper (GLM_MODE aware)
│   ├── install-key.sh       # API key registration utility
│   └── glm-cleanup-sessions # Session cleanup utility
├── config/
│   └── mcp.conf             # MCP configuration (GLM_USE_MCP=0/1)
├── credentials/
│   ├── common.sh            # Platform abstraction layer
│   ├── macos.sh             # macOS Keychain operations
│   ├── linux.sh             # Linux libsecret operations
│   ├── windows.sh           # Windows environment variable
│   └── security.conf        # Credential storage configuration
├── scripts/
│   ├── common-utils.sh      # Shared utility functions
│   ├── install.sh           # Installation script
│   └── uninstall.sh         # Uninstallation script
└── backups/
    └── .claude.json.backup.* # Automatic backups
```

### Runtime Directory (~/.claude-glm/)

Where GLM sessions run (v2.0.0+ session isolation):

```
~/.claude-glm/
├── settings.json            # GLM session settings (isolated)
├── settings.local.json      # Local overrides (isolated)
├── glm-sessions/            # Temporary session files
│   └── glm-<timestamp>-<pid>.json
├── plugins/        → symlink to ~/.claude/plugins/
├── commands/       → symlink to ~/.claude/commands/
├── projects/       → symlink to ~/.claude/projects/
├── todos/          → symlink to ~/.claude/todos/
└── CLAUDE.md       → symlink to ~/.claude/CLAUDE.md
```

**Key Design**: Settings are isolated, but plugins/projects are shared via symlinks.

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

## 🤝 Contributing

Contributions are welcome! This project follows security-first development practices.

**Before contributing:**
1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Review [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
3. Check [SECURITY.md](SECURITY.md) for security guidelines

**Quick contribution flow:**
```bash
# Fork & clone
git clone https://github.com/YOUR_USERNAME/claude-glm-wrapper.git

# Create feature branch
git checkout -b feature/your-feature

# Make changes, test thoroughly
./scripts/security-scan.sh --full

# Commit (pre-commit hook runs automatically)
git commit -m "feat: your feature"

# Push & open PR
git push origin feature/your-feature
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**What this means:**
- ✅ Free to use commercially
- ✅ Free to modify and distribute
- ✅ No warranty provided
- ✅ Must include license and copyright notice

## 🙏 Acknowledgments

- [Z.ai](https://z.ai/) for GLM models and API
- [Anthropic](https://www.anthropic.com/) for Claude Code
- [Gitleaks](https://github.com/gitleaks/gitleaks) for secret scanning
- All contributors who help improve this project

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/wgsim/claude-glm-wrapper/issues)
- **Security**: See [SECURITY.md](SECURITY.md) for vulnerability reporting
- **Discussions**: [GitHub Discussions](https://github.com/wgsim/claude-glm-wrapper/discussions)

## 🗺️ Roadmap

See [ROADMAP.md](ROADMAP.md) for planned features and improvements.

---

**Made with ❤️ for the Claude Code community**
