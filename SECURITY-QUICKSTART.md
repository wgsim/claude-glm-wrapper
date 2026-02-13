# Security Quick Start

**Status**: ✅ Active
**Setup**: Complete

## Automated Security Controls

All security recommendations (#1, #2, #4) are now active:

### ✅ 1. Pre-commit Review Hook

**What it does:**
- Shows `git diff --cached` before every commit
- Scans for secrets with gitleaks
- Validates file permissions

**Usage:**
```bash
# Normal commit (hook runs automatically)
git commit -m "your message"

# You'll see:
# ========================================
# Pre-commit checks
# ========================================
#
# 📝 Staged changes (git diff --cached):
# [shows your changes]
#
# 🔍 Scanning for secrets...
# ✅ No secrets detected
#
# ========================================
# ✅ All checks passed!
# ========================================
```

**Bypass** (use with extreme caution):
```bash
git commit --no-verify -m "message"
```

### ✅ 2. Periodic Security Scanning

**What it does:**
- Scans entire git history for leaked secrets
- Can run on schedule (cron/CI)

**Usage:**
```bash
# Quick scan
./scripts/security-scan.sh --full

# Generate detailed report
./scripts/security-scan.sh --full --report
```

**Schedule weekly scans:**
```bash
# Edit crontab
crontab -e

# Add: Every Monday at 9am
0 9 * * 1 cd ~/AI_development/claude-by-glm_safety_setting && ./scripts/security-scan.sh --full
```

### ✅ 4. .gitignore Protection

**What it does:**
- Prevents accidental commits of 140+ sensitive file patterns
- Credentials, secrets, sessions, backups, logs, etc.

**Patterns protected:**
```
.env, *.pem, *.key, *secret*, *token*
*.session, .last-session, *.backup
*.log, *.pid
.claude/settings.local.json
```

## Quick Tests

### Test pre-commit hook:
```bash
echo 'api_key="sk-ant-test123"' > test.txt
git add test.txt
git commit -m "test"
# Should be blocked if pattern matches
```

### Test .gitignore:
```bash
echo "test" > .env
git status
# .env should NOT appear
```

### Run security scan:
```bash
./scripts/security-scan.sh --full
# Should show: ✅ No leaks found
```

## Current Status

**Last Scan**: 2026-02-12
- ✅ 43 commits scanned
- ✅ 210 KB analyzed
- ✅ 0 secrets found
- ✅ Pre-commit hook active
- ✅ Gitleaks installed

## Emergency Response

**If secret detected in commit:**
1. Hook will block automatically
2. Remove secret from file
3. Use environment variable instead
4. Re-stage and commit

**If secret found in history:**
1. **ROTATE IMMEDIATELY** - assume compromised
2. Remove from git history:
   ```bash
   git filter-repo --path <file> --invert-paths
   ```
3. Force push (if applicable)
4. Notify team to re-clone

## Documentation

- 📖 **Full docs**: `docs/security-automation.md`
- 🔒 **Security audit**: `docs/gitignore-security-audit.md`
- ⚙️ **Config**: `.gitleaks.toml`
- 📜 **Policy**: `SECURITY.md`

## Tools Installed

- ✅ **gitleaks** (8.30.0) - Secret scanner
  - Install: `brew install gitleaks`
  - Docs: https://github.com/gitleaks/gitleaks

## Support

Questions? See:
- `docs/security-automation.md` - Detailed usage
- `./scripts/security-scan.sh --help` - Scan options
- `.gitleaks.toml` - Detection rules
