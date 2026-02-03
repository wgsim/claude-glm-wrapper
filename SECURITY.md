# Security Policy

## Overview

GLM MCP Wrapper stores your Z.ai API key securely in macOS keychain and never writes credentials to plaintext files.

## Credential Storage

### Single API Key

This system uses **ONE** Z.ai API key stored in macOS keychain:

| Setting | Value |
|---------|-------|
| **Keychain Service** | `z.ai-api-key` |
| **Keychain Account** | Your username (`$USER`) |
| **Access Control** | Only node, npx processes |

Both `claude-by-glm` and `glm-mcp-wrapper` use the same API key from keychain.

### Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        claude-by-glm                                │
│  (fetches z.ai-api-key from keychain → ANTHROPIC_AUTH_TOKEN)       │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Claude Code with GLM_MODE=1                                       │
│  • Uses GLM models (glm-4.5-air, glm-4.6, glm-4.7)                 │
│  • Activates MCP wrapper via ~/.claude.json                        │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    glm-mcp-wrapper                                 │
│  (fetches z.ai-api-key from keychain → ZAI_API_KEY)                │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Z.ai MCP Server                                 │
│  (npx @z_ai/mcp-server)                                            │
└─────────────────────────────────────────────────────────────────────┘
```

## Security Features

- **No plaintext storage**: API key never written to files
- **Keychain encryption**: Key stored encrypted by macOS
- **Restrictive permissions**: Scripts set to mode 500 (owner read/execute only)
- **Input validation**: API key format validated before storage
- **No `-U` flag**: Keychain ACLs restrict access to specific processes only

## Security Best Practices

### For Users

1. **Lock your keychain** when not in use
   ```bash
   security lock-keychain ~/Library/Keychains/login.keychain-db
   ```

2. **Use strong keychain password**
   - Set in: System Settings → Privacy & Security → Keychain
   - Use unique password, not your account password

3. **Review keychain access regularly**
   ```bash
   # List GLM-related entry
   security find-generic-password -s "z.ai-api-key" -a "$USER" -w
   ```

4. **Never share your API key**
   - Keys are tied to your Z.ai account
   - Sharing may result in account suspension

5. **Keep macOS updated** for security patches

### For Developers

1. Never hardcode credentials in source code
2. Always validate user input before use
3. Use restrictive file permissions (500 for scripts)
4. Never use `-U` flag in keychain operations
5. Log security-relevant events for audit trails

## Known Limitations

| Issue | Impact | Mitigation |
|-------|--------|------------|
| macOS only | Keychain integration requires macOS | Linux/Windows need alternative storage |
| **Environment variable exposure** | **API key visible to child processes** | **See below for details** |
| No rate limiting | Keychain access not throttled | Protect keychain password |
| No audit logging | Keychain access not logged | Review keychain access manually |

### Environment Variable Exposure Risk

When MCP is enabled (`GLM_USE_MCP=1`), the API key is temporarily exported as an environment variable (`ZAI_API_KEY`) to pass it to the Z.ai MCP server.

**Risks:**
- The API key is visible to all child processes during the MCP server's lifetime
- On Linux, the key can be read from `/proc/[pid]/environ` by processes with the same UID
- The key may appear in process listings with `ps eww` or similar tools
- Core dumps could contain the key (mitigated by `ulimit -c 0`)

**Mitigations:**
- The wrapper minimizes exposure time by immediately `exec`ing the MCP server
- Core dumps are prevented via `ulimit -c 0`
- The key is never logged or written to files

**Recommendations:**
1. Disable MCP if you don't need MCP tools (`GLM_USE_MCP=0`)
2. Run on trusted systems only
3. Use a dedicated API key with minimal permissions
4. Consider using alternative credential methods for high-security environments

## Reporting Vulnerabilities

To report a security vulnerability:

1. **Do not** create a public GitHub issue
2. Email details to: [your security contact]
3. Include:
   - Vulnerability description
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if known)

We will respond within 48 hours and coordinate disclosure timeline.

## Security Audits

| Date | Version | Findings | Status |
|------|---------|----------|--------|
| 2026-02-01 | 1.0 | 11 issues addressed | Resolved |

## Compliance

This project follows security best practices from:

- **OWASP ASVS** - Application Security Verification Standard
- **CSC** - CIS Critical Security Controls
- **CWE** - Common Weakness Enumeration

## License

MIT License - See LICENSE file for details.
