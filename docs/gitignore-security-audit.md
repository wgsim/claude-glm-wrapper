# .gitignore Security Audit

**Date**: 2026-02-12
**Version**: v2.0.0

## Audit Summary

Comprehensive review of files that should be excluded from version control to prevent accidental exposure of sensitive information.

## Security-Critical Patterns

### 1. Credentials and Secrets (CRITICAL)

**Risk**: Hardcoded API keys, tokens, passwords committed to repository

**Ignored Patterns**:
- `.env`, `.env.*` - Environment variables often contain API keys
- `*.pem`, `*.key`, `*.p12`, `*.pfx` - Private keys and certificates
- `*secret*`, `*token*`, `*password*` - Files likely containing credentials
- `api-key*`, `credentials.json` - API key storage files

**Rationale**: Even in private repos, committed secrets can be:
- Exposed via repo forks or mirrors
- Extracted from git history even after removal
- Leaked if repo visibility changes
- Accessed by compromised CI/CD systems

### 2. Session Files (HIGH)

**Risk**: Runtime session files may contain API tokens in headers or memory dumps

**Ignored Patterns**:
- `*.session`, `*.session.json` - Session state files
- `*-session-*` - Session-related temporary files
- `.last-session` - Last session tracking

**Rationale**: Session files created by `claude-by-glm` contain:
- Temporary settings that may reference API keys
- Session IDs that could be used for replay attacks
- User-specific configuration not meant for sharing

### 3. Backup Files (HIGH)

**Risk**: Backups often contain snapshots of sensitive configuration

**Ignored Patterns**:
- `*.backup`, `*.backup.*`, `.claude.json.backup*`
- `*.bak`, `*.old`, `*.orig`

**Rationale**: Backup files may contain:
- Previous versions of configs with hardcoded secrets
- User-specific settings inadvertently committed
- Sensitive data from before security hardening

**Example**: `~/.claude-glm-mcp/backups/.claude.json.backup.*` contains full Claude config including potential API keys

### 4. Log Files (MEDIUM-HIGH)

**Risk**: Logs may expose system paths, API responses, or error details useful for attacks

**Ignored Patterns**:
- `*.log`, `*.log.*`, `logs/`
- `*.pid` - Process ID files (may indicate running services)

**Rationale**: Logs can leak:
- API endpoint URLs and request patterns
- System paths revealing installation locations
- Error traces exposing internal architecture
- Timing information useful for side-channel attacks

### 5. User-Specific Files (MEDIUM)

**Risk**: Personal configuration leaking user preferences or local paths

**Ignored Patterns**:
- `.claude/settings.local.json` - User-specific Claude settings
- `config.local.*`, `*.local.json`, `*.local.conf`

**Rationale**: Local config files may contain:
- User-specific API endpoints
- Development/testing credentials
- Local file paths exposing directory structure

## Files Currently Protected

✓ **bin/glm-watch-settings** - Development monitoring tool (not for distribution)
✓ **.claude/settings.local.json** - User-specific settings
✓ **All patterns above** - Comprehensive coverage

## Verification

```bash
# Check no sensitive files are tracked
git ls-files | grep -E "\.(log|pid|session|backup|env|pem|key)$"
# Should return: No matches

# Verify .gitignore is working
echo "test-token" > .env
git status
# Should not show .env as untracked
```

## Best Practices

1. **Never commit secrets** - Use environment variables or secure secret stores
2. **Review before commit** - Run `git diff --cached` before committing
3. **Audit git history** - Use tools like `gitleaks` or `trufflehog` to scan for secrets
4. **Rotate exposed secrets** - If a secret is committed, rotate it immediately
5. **Use .gitignore early** - Add patterns before sensitive files are created

## Related Files

- `.gitignore` - Main ignore file with security patterns
- `credentials/security.conf` - Security configuration (tracked - no secrets)
- `SECURITY.md` - Security policy and reporting guidelines

## References

- [OWASP Secret Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [GitGuardian Best Practices](https://blog.gitguardian.com/secrets-api-management/)
