# claude-by-glm Update Instructions

## Note: New Installation Available

If you're setting up fresh, use the new installation system instead:

```bash
cd /path/to/claude-by-glm_safety_setting
./scripts/install.sh
```

This will install a complete system including `~/.glm-mcp/bin/claude-by-glm`.

---

## Historical Migration Guide (v1.0.0 → v1.1.0)

This guide documents the migration from the old two-key system to the unified single-key system.

### What Changed in v1.1.0

| Old (v1.0.0) | New (v1.1.0+) |
|--------------|---------------|
| Keychain: `glm-coding-plan` (model API) | Keychain: `z.ai-api-key` (both) |
| Keychain: `z.ai-api-key` (MCP wrapper) | ← Unified |
| No GLM_MODE | `GLM_MODE=1` activates MCP wrapper |
| macOS only | Multi-platform (macOS, Linux, Windows) |

### Legacy Migration (If you have old credentials)

If you have the old `glm-coding-plan` keychain entry from v1.0.0:

```bash
# Verify old entry exists
security find-generic-password -s "glm-coding-plan" -a "$USER" -w

# Remove old entry (no longer needed)
security delete-generic-password -s "glm-coding-plan" -a "$USER"

# The new unified entry is: z.ai-api-key
security find-generic-password -s "z.ai-api-key" -a "$USER" -w
```

### Current System (v1.1.0+)

The system now uses a **single** Z.ai API key (`z.ai-api-key`) for both:
- Direct model API calls (claude-by-glm)
- Z.ai MCP server tools (glm-mcp-wrapper)

Configuration is centralized in `credentials/security.conf`.

## Verification

Verify your installation:

```bash
# Check API key in credential storage
# macOS:
security find-generic-password -s "z.ai-api-key" -a "$USER" -w

# Linux:
secret-tool lookup "glm-wrapper-service" "z.ai-api-key" "glm-wrapper-account" "$USER"

# Test the wrapper directly
GLM_MODE=1 ~/.glm-mcp/bin/glm-mcp-wrapper
```
