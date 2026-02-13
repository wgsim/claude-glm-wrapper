# External Security Review

**Date**: 2026-02-12
**Reviewers**: Gemini (Analysis), ChatGPT/Codex (Code Review)
**Status**: 🔴 **CRITICAL ISSUES FOUND** - Must fix before public release

## Executive Summary

Both AI models conducted comprehensive security reviews. **12 security issues identified**, including **6 HIGH severity** vulnerabilities that must be fixed before making the repository public.

### Severity Breakdown
- 🔴 **HIGH**: 6 issues (path traversal, permissions, credential handling, environment exposure)
- 🟠 **MEDIUM**: 4 issues (config parsing, supply chain, validation)
- 🟡 **LOW**: 2 issues (error handling, xargs)

---

## 🔴 CRITICAL Issues (Must Fix)

### 1. Arbitrary File Deletion via Path Traversal
**Severity**: HIGH
**File**: `bin/glm-cleanup-sessions:170,172,179`
**Reporter**: ChatGPT/Codex

**Issue**:
```bash
# User input not validated - can escape SESSIONS_DIR
glm-cleanup-sessions --session ../../../etc/passwd
```

**Impact**: User can delete arbitrary files. Severe if run with elevated privileges.

**Fix**:
```bash
# Validate session ID format strictly
if [[ ! "$session_id" =~ ^glm-[0-9]+-[0-9]+$ ]]; then
    print_error "Invalid session ID format"
    exit 1
fi

# Canonicalize and verify path
session_path="$(realpath -m "$SESSIONS_DIR/$session_id.json")"
if [[ "$session_path" != "$SESSIONS_DIR"/* ]]; then
    print_error "Session path outside sessions directory"
    exit 1
fi
```

---

### 2. Session Files Created Without Restrictive Permissions
**Severity**: HIGH
**File**: `bin/claude-by-glm:208,222,229`
**Reporter**: ChatGPT/Codex

**Issue**: No explicit `umask 077` or `chmod 600` on session files.

**Impact**: On permissive umask, other local users may read session configs.

**Fix**:
```bash
# At start of claude-by-glm main()
umask 077

# After mkdir
mkdir -p "$glm_sessions_dir"
chmod 700 "$glm_sessions_dir"

# After creating session file
chmod 600 "$session_settings"
```

---

### 3. macOS Keychain Process Exposure
**Severity**: HIGH
**File**: `credentials/macos.sh:65`
**Reporter**: Gemini, ChatGPT/Codex

**Issue**:
```bash
# Password visible in process list
security add-generic-password -w "$password" -s "$service" -a "$account"
```

**Impact**: API key briefly visible via `ps` on multi-user systems.

**Fix**:
```bash
# Pass password via stdin instead
printf "%s" "$password" | security add-generic-password \
    -w -s "$service" -a "$account"
```

---

### 4. macOS Credential Operations Ignore Account
**Severity**: HIGH
**File**: `credentials/macos.sh:54,88,106`
**Reporter**: ChatGPT/Codex

**Issue**: Fetch/delete only use `-s "$service"`, ignoring account parameter.

**Impact**: Wrong credential may be used/deleted if multiple entries share service name.

**Fix**:
```bash
# Add -a "$account" to all security commands
security find-generic-password -s "$service" -a "$account" -w
security delete-generic-password -s "$service" -a "$account"
```

---

### 5. Secrets Remain Exposed in Process Environment
**Severity**: HIGH
**File**: `bin/claude-by-glm:190`, `bin/glm-mcp-wrapper:114`
**Reporter**: ChatGPT/Codex

**Issue**:
```bash
# API key exported and remains in environment for entire process lifetime
export ANTHROPIC_AUTH_TOKEN="$api_key"
# Later: exec claude --model opus "$@"
# Key remains readable via /proc/<pid>/environ on Linux
```

**Impact**: Same-user processes can read API key from environment.

**Current Mitigation**: Parent shell protection (subprocess), but child process tree has exposure.

**Fix** (Defense in Depth):
```bash
# Minimize environment exposure with allowlist
exec env -i \
    PATH="$PATH" \
    HOME="$HOME" \
    ANTHROPIC_AUTH_TOKEN="$api_key" \
    CLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR" \
    CLAUDE_SETTINGS="$session_settings" \
    claude --model opus "$@"
```

**Note**: This is inherent to how Claude Code accepts credentials. Consider documenting the risk clearly.

---

### 6. Cleanup Script Points to Wrong Directory
**Severity**: HIGH (data loss risk)
**File**: `bin/glm-cleanup-sessions:109`
**Reporter**: ChatGPT/Codex

**Issue**:
```bash
# Cleanup uses old path
SESSIONS_DIR="$HOME/.claude/glm-sessions"

# Runtime uses new path (since v2.0.0)
local glm_sessions_dir="$CLAUDE_CONFIG_DIR/glm-sessions"  # ~/.claude-glm/
```

**Impact**: Cleanup doesn't work, old sessions accumulate.

**Fix**:
```bash
SESSIONS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude-glm}/glm-sessions"
```

---

## 🟠 MEDIUM Issues (Should Fix)

### 7. Config Parsing Literal Variable
**Severity**: MEDIUM
**File**: `credentials/security.conf:8`, `credentials/common.sh:66`
**Reporter**: ChatGPT/Codex

**Issue**:
```bash
# security.conf has literal text, not expanded
KEYCHAIN_ACCOUNT="${USER:-$LOGNAME}"

# Loaded as literal string, not shell expansion
```

**Impact**: Account mismatch, credential lookup fails.

**Fix**:
```bash
# In security.conf, use concrete value
KEYCHAIN_ACCOUNT="$USER"

# OR expand during load in common.sh
eval "account=\"$KEYCHAIN_ACCOUNT\""
```

---

### 8. Unpinned NPX Package (Supply Chain Risk)
**Severity**: MEDIUM
**File**: `bin/glm-mcp-wrapper:126,130`
**Reporter**: ChatGPT/Codex

**Issue**:
```bash
npx -y @z_ai/mcp-server@latest
```

**Impact**: Compromise risk if upstream package is tampered.

**Fix**:
```bash
# Use pinned version from config
npx -y @z_ai/mcp-server@"${ZAI_MCP_VERSION:-1.0.0}"
```

---

### 9. API Key Regex Mismatch
**Severity**: MEDIUM
**File**: `bin/install-key.sh:89` vs `bin/glm-mcp-wrapper:63`
**Reporter**: Gemini, ChatGPT/Codex

**Issue**: Different patterns - install allows more characters than runtime.

**Impact**: Valid keys stored but rejected at runtime.

**Fix**: Align to single regex:
```bash
# Use consistent pattern everywhere
API_KEY_REGEX='^[a-zA-Z0-9._+/=-]+$'
```

---

### 10. Pre-commit Permission Check Warning-Only
**Severity**: MEDIUM
**File**: `.git/hooks/pre-commit:79,84`
**Reporter**: ChatGPT/Codex

**Issue**: Warns about bad permissions but doesn't block commit.

**Impact**: Security policy bypass.

**Fix**:
```bash
if [[ "$perms" != "500" && "$perms" != "600" ]]; then
    echo -e "${RED}❌ Error: $file has permissions $perms${NC}"
    exit 1  # Block commit
fi
```

---

## 🟡 LOW Issues (Nice to Fix)

### 11. Scan Result Handling Bug
**Severity**: LOW
**File**: `scripts/security-scan.sh:108`
**Reporter**: ChatGPT/Codex

**Issue**: Checks `$?` after intervening commands.

**Fix**:
```bash
gitleaks detect --verbose
scan_exit=$?
if [[ $scan_exit -eq 0 ]]; then
    ...
fi
```

---

### 12. xargs Edge Case
**Severity**: LOW
**File**: `credentials/common.sh:65-69`
**Reporter**: Gemini

**Fix**:
```bash
xargs -r  # Add -r flag
```

---

## Additional Recommendations

### Security Testing (ChatGPT/Codex)

Add BATS tests for:
1. Path traversal: `--session ../../` must fail
2. File permissions: Assert 700/600 after operations
3. Credential consistency across platforms
4. Regex parity tests
5. CI enforcement (gitleaks in CI, shellcheck)

### Architecture Improvements

1. **Minimize environment exposure**:
   ```bash
   exec env -i PATH="$PATH" ANTHROPIC_AUTH_TOKEN="$api_key" claude --model opus "$@"
   ```

2. **Set umask globally** in all security-sensitive scripts:
   ```bash
   umask 077
   ```

3. **Pin dependencies** by default (ZAI_MCP_VERSION)

---

## Overall Assessment

### Gemini's Verdict
> "The GLM MCP Wrapper is a well-engineered, security-conscious project. Its implementation of platform-specific credential storage and session isolation is superior to many similar CLI tools. By addressing the minor macOS process exposure and regex alignment, it will be in excellent shape for a public release."

### ChatGPT/Codex's Verdict
> "Main exploitable input issue is path traversal in cleanup, not command injection. No direct privilege escalation found in normal flow. Good quoting discipline throughout. With fixes, this will be production-ready."

---

## Action Plan

### Before Public Release (REQUIRED)

1. ✅ Fix HIGH severity issues (#1-6)
2. ✅ Fix MEDIUM severity issues (#7-10)
3. ⚠️ Consider LOW issues (#11-12)
4. ✅ Add security tests
5. ✅ Re-scan with gitleaks
6. ✅ External review of fixes

### Priority Order

1. **Path traversal** (critical security)
2. **File permissions** (multi-user safety)
3. **macOS keychain** (credential exposure)
4. **Cleanup directory** (functional bug)
5. **Config/regex alignment** (reliability)
6. **Pre-commit enforcement** (policy)
7. **Supply chain pinning** (best practice)

---

**Status**: 🔴 Not ready for public release until HIGH issues fixed
**Next Step**: Implement critical fixes, re-test, re-scan
**ETA**: ~2-3 hours for all fixes + testing

**Review Credits**:
- Gemini (Google): Architectural security analysis
- ChatGPT/Codex (OpenAI): Code-level vulnerability assessment
