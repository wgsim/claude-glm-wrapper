# Security Automation

**Status**: ✅ Active
**Version**: v2.0.0
**Last Updated**: 2026-02-12

## Overview

Automated security controls to prevent accidental exposure of secrets and sensitive data.

## Components

### 1. Pre-commit Hook (Recommendation #1 & #4)

**Location**: `.git/hooks/pre-commit`

**Functionality**:
- ✅ Shows `git diff --cached` for review before commit
- ✅ Scans staged changes for secrets with gitleaks
- ✅ Validates file permissions on security-sensitive files
- ✅ Blocks commits containing detected secrets

**Usage**:
```bash
# Normal commit (hook runs automatically)
git commit -m "your message"

# Bypass hook (use with extreme caution)
git commit --no-verify -"your message"
```

**Example Output**:
```
========================================
Pre-commit checks
========================================

📝 Staged changes (git diff --cached):
 .gitignore | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

🔍 Scanning for secrets with gitleaks...
✅ No secrets detected

🔒 Checking file permissions...
✅ File permissions OK

========================================
✅ All pre-commit checks passed!
========================================
```

**Configuration**: `.gitleaks.toml`
- Custom rules for Z.ai and Anthropic API keys
- JWT token detection
- Generic API key patterns
- Allowlist for false positives

### 2. Periodic Security Scanning (Recommendation #2)

**Location**: `scripts/security-scan.sh`

**Functionality**:
- ✅ Scans entire git history for leaked secrets
- ✅ Generates detailed JSON reports
- ✅ Scans staged changes only (faster)
- ✅ Identifies secrets missed in past commits

**Usage**:
```bash
# Scan entire git history
./scripts/security-scan.sh --full

# Scan only staged changes
./scripts/security-scan.sh --staged

# Generate detailed report
./scripts/security-scan.sh --full --report
```

**Scheduled Scanning**:

Add to cron for weekly scans:
```bash
# Edit crontab
crontab -e

# Add weekly scan (every Monday at 9am)
0 9 * * 1 cd ~/AI_development/claude-by-glm_safety_setting && ./scripts/security-scan.sh --full --report 2>&1 | mail -s "Weekly Security Scan" your@email.com
```

Or use GitHub Actions (see `.github/workflows/security-scan.yml`):
```yaml
name: Security Scan
on:
  schedule:
    - cron: '0 9 * * 1'  # Weekly on Monday
  push:
    branches: [main]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history
      - uses: gitleaks/gitleaks-action@v2
```

### 3. Gitleaks Configuration

**Location**: `.gitleaks.toml`

**Custom Rules**:

1. **Z.ai API Keys** (CRITICAL)
   - Pattern: `zai_api_key = "..."`
   - Severity: CRITICAL

2. **Anthropic API Keys** (CRITICAL)
   - Pattern: `sk-ant-...`
   - Severity: CRITICAL

3. **Generic API Keys** (HIGH)
   - Pattern: `api_key = "..."`
   - Severity: HIGH

4. **JWT Tokens** (HIGH)
   - Pattern: `eyJ...`
   - Severity: HIGH

**Allowlist**:
- Documentation files (README.md, SECURITY.md)
- Configuration files with example/sample values
- Test fixtures with placeholder data

### 4. .gitignore Protection

**Location**: `.gitignore`

**Patterns** (140+ entries):
- Credentials (`.env`, `*.pem`, `*.key`, `*secret*`)
- Session files (`*.session`, `.last-session`)
- Backups (`*.backup`, `.claude.json.backup*`)
- Logs (`*.log`, `*.pid`)
- User configs (`*.local.json`)

See `docs/gitignore-security-audit.md` for full details.

## Verification

### Test Pre-commit Hook

```bash
# Create test file with fake secret
echo 'API_KEY="sk-ant-test123456789012345678901234567890"' > test-secret.txt
git add test-secret.txt
git commit -m "test"

# Expected: Commit blocked, secret detected
```

### Test Periodic Scan

```bash
# Scan entire history
./scripts/security-scan.sh --full

# Expected: "✅ No secrets found" or list of findings
```

### Verify .gitignore

```bash
# Create test files
echo "test" > .env
echo "test" > test.backup

# Check status
git status

# Expected: Files not shown (ignored)
```

## Incident Response

### If Secret Detected in Staged Changes

1. **DO NOT COMMIT** - Hook will block automatically
2. Remove secret from file
3. Use environment variable or secret store instead
4. Re-stage and commit

### If Secret Found in Git History

1. **ROTATE SECRET IMMEDIATELY** - Assume compromised
2. Remove from git history:
   ```bash
   # Option 1: git filter-repo (recommended)
   git filter-repo --path <file> --invert-paths

   # Option 2: BFG Repo-Cleaner
   bfg --delete-files <file>
   ```
3. Force push (if remote):
   ```bash
   git push --force-with-lease
   ```
4. Notify team members to re-clone

### False Positives

Add to `.gitleaks.toml` allowlist:
```toml
[allowlist]
paths = [
    '''path/to/file.txt''',
]

# Or by commit
commits = [
    '''commit-sha''',
]
```

## Maintenance

### Update Gitleaks

```bash
brew upgrade gitleaks
```

### Update Rules

Edit `.gitleaks.toml` to add project-specific patterns:
```toml
[[rules]]
id = "custom-secret"
description = "Custom Secret Pattern"
regex = '''your-pattern-here'''
severity = "CRITICAL"
```

### Review Scan Reports

```bash
# Generate and review report
./scripts/security-scan.sh --full --report
cat security-scan-*.json | jq
```

## Metrics

**Current Status** (as of 2026-02-12):
- ✅ Git history scanned: 43 commits, 210 KB
- ✅ Secrets found: 0
- ✅ Pre-commit hook: Active
- ✅ Gitleaks config: Custom rules for Z.ai/Anthropic
- ✅ .gitignore: 140+ security patterns

**Coverage**:
- Pre-commit: 100% of new commits
- Periodic scan: Entire git history
- .gitignore: All sensitive file types

## References

- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [OWASP Secret Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [Git Filter-Repo](https://github.com/newren/git-filter-repo)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)

## Related Documentation

- `docs/gitignore-security-audit.md` - .gitignore security rationale
- `SECURITY.md` - Security policy and vulnerability reporting
- `.gitleaks.toml` - Gitleaks configuration
- `scripts/security-scan.sh` - Periodic scanning script
