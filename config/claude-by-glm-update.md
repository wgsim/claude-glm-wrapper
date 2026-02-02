# claude-by-glm Update Instructions

## Note: New Installation Available

If you're setting up fresh, use the new installation system instead:

```bash
cd /path/to/claude-by-glm_safety_setting
./scripts/install.sh
```

This will install a complete system including `~/.glm-mcp/bin/claude-by-glm`.

---

## Manual Update (Existing Users)

If you prefer to keep your existing `~/bin/claude-by-glm`, update it to use the new keychain service and activate MCP wrapper.

## Required Changes

### 1. Update Keychain Service

Change from `glm-coding-plan` to `z.ai-api-key`:

```bash
# Old (deprecated)
security find-generic-password -s glm-coding-plan -a ${USER} -w

# New (current)
security find-generic-password -s z.ai-api-key -a ${USER} -w
```

### 2. Add GLM_MODE Export

Add `GLM_MODE=1` export before the `exec claude` command.

### Example Updated Script

```bash
#!/usr/bin/env zsh

# Set GLM_MODE flag to activate the MCP wrapper
export GLM_MODE=1

# Existing configuration (updated keychain service)
ANTHROPIC_AUTH_TOKEN="$(
  security find-generic-password -s z.ai-api-key -a ${USER} -w
)" \
ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" \
ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.6" \
ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.7" \
CLAUDE_SETTINGS="$HOME/.claude/settings.glm.json" \
exec claude "$@"
```

### What Changed

| Old | New |
|-----|-----|
| Keychain: `glm-coding-plan` | Keychain: `z.ai-api-key` |
| No GLM_MODE | `GLM_MODE=1` activates MCP wrapper |

### What GLM_MODE Does

- When `GLM_MODE=1`: The wrapper activates and loads Z.ai MCP server from keychain
- When not set or `GLM_MODE=0`: The wrapper stays idle (no MCP tools provided)

This allows the same `~/.claude.json` configuration to work for both:
- Official Claude (wrapper stays idle)
- claude-by-glm (wrapper activates Z.ai MCP)

## Single API Key

The system now uses a **single** Z.ai API key (`z.ai-api-key`) for both:
- Direct model API calls (claude-by-glm)
- Z.ai MCP server tools (glm-mcp-wrapper)

## Verification

After updating, verify with:

```bash
# Check that GLM_MODE is set
env | grep GLM_MODE

# Test the wrapper directly
GLM_MODE=1 ~/.glm-mcp/bin/glm-mcp-wrapper

# Verify API key in keychain
security find-generic-password -s "z.ai-api-key" -a "$USER" -w
```
