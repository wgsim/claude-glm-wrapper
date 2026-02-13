# Security Review Round 2 (Post-Fix Verification)

**Date**: 2026-02-12
**Status**: ❌ **8 NEW ISSUES FOUND** - NOT READY for public release
**External Review**: Gemini + ChatGPT/Codex

## Context

Second security review after fixing all 12 vulnerabilities from the first review. This review validates fixes and checks for regressions or new issues.

## Round 1 Fix Verification (12/12)

All 12 original fixes verified as correctly implemented:

| # | Issue | Status | Verification |
|---|-------|--------|--------------|
| 1 | Path Traversal | ✅ PASS | Regex ^glm-[0-9]+-[0-9]+$ + realpath |
| 2 | File Permissions | ✅ PASS | umask 077 + chmod 700/600 |
| 3 | Keychain Exposure | ✅ PASS | stdin password delivery |
| 4 | Account Mismatch | ✅ PASS | Service+account with fallback |
| 5 | Env Isolation | ✅ PASS | env -i with allowlist |
| 6 | Cleanup Directory | ✅ PASS | CLAUDE_CONFIG_DIR alignment |
| 7 | Config Parsing | ✅ PASS | Safe grep/sed parsing |
| 8 | Unpinned NPX | ✅ PASS | ZAI_MCP_VERSION=1.0.0 |
| 9 | Regex Mismatch | ✅ PASS | Pattern alignment |
| 10 | Pre-commit Check | ✅ PASS | Blocking error |
| 11 | Scan Handling | ✅ PASS | Immediate exit code capture |
| 12 | xargs Edge Case | ✅ PASS | xargs -r added (but see Issue #1) |

## New Issues Found (8 total)

### 🔴 HIGH Severity (2 issues)

#### Issue #1: macOS Regression - xargs -r Incompatibility

**Severity**: HIGH (Platform Blocker)
**File**: `credentials/common.sh:65-69`
**Reported By**: Gemini

**Problem**:
The `-r` flag (--no-run-if-empty) is a GNU extension. macOS uses BSD `xargs` which doesn't support this flag, resulting in:
```
xargs: illegal option -- r
```

Since `common.sh` is sourced with `set -e`, the application fails to start on macOS.

**Code**:
```bash
service=$(grep -E '^KEYCHAIN_SERVICE=' "$config_file" ... | xargs -r)
account=$(grep -E '^KEYCHAIN_ACCOUNT=' "$config_file" ... | xargs -r)
use_mcp=$(grep -E '^GLM_USE_MCP=' "$config_file" ... | xargs -r)
install_dir=$(grep -E '^GLM_INSTALL_DIR=' "$config_file" ... | xargs -r)
mcp_version=$(grep -E '^ZAI_MCP_VERSION=' "$config_file" ... | xargs -r)
```

**Fix**:
BSD xargs natively doesn't run on empty input for many operations. Remove `-r` flag for portability.

**Impact**: Critical - Breaks entire tool on macOS (primary platform)

---

#### Issue #2: PATH Poisoning Vulnerability

**Severity**: HIGH (Security)
**File**: `bin/claude-by-glm:273, 285`
**Reported By**: ChatGPT/Codex

**Problem**:
`PATH` is inherited from caller and `claude` is executed by name. A poisoned `PATH` can execute a malicious `claude` binary and exfiltrate `ANTHROPIC_AUTH_TOKEN`.

**Code**:
```bash
exec env -i \
    PATH="$PATH" \
    ...
    ANTHROPIC_AUTH_TOKEN="$api_key" \
    claude --model opus "$@"
```

**Fix**:
Resolve absolute `claude` path first, validate it, and use a minimal trusted PATH:

```bash
claude_bin="$(command -v claude)" || handle_error "claude not found"

# Validate claude is in trusted location
case "$claude_bin" in
    /usr/bin/claude|/usr/local/bin/claude|/opt/homebrew/bin/claude|"$HOME/.claude-glm-mcp/bin/claude")
        # Trusted path
        ;;
    *)
        handle_error "Untrusted claude path: $claude_bin"
        ;;
esac

# Use minimal trusted PATH
exec env -i \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.claude-glm-mcp/bin" \
    ...
    "$claude_bin" --model opus "$@"
```

**Impact**: Can lead to credential theft via PATH manipulation

---

### 🟠 MEDIUM Severity (5 issues)

#### Issue #3: Silent chmod Failures Weaken Defense

**Severity**: MEDIUM
**File**: `bin/claude-by-glm:218, 246`
**Reported By**: ChatGPT/Codex

**Problem**:
Permission hardening failures are silently ignored with `|| true`, weakening defense-in-depth.

**Code**:
```bash
chmod 700 "$glm_sessions_dir" 2>/dev/null || true
chmod 600 "$session_settings" 2>/dev/null || true
```

**Fix**:
Fail closed on chmod errors:
```bash
chmod 700 "$glm_sessions_dir" || handle_error "Failed to set session directory permissions"
chmod 600 "$session_settings" || handle_error "Failed to set session file permissions"
```

**Impact**: Permission violations may go unnoticed

---

#### Issue #4: Credential Confusion via Service-Only Fallback

**Severity**: MEDIUM
**File**: `credentials/macos.sh:102-106`
**Reported By**: ChatGPT/Codex

**Problem**:
Service-only fallback can return credentials for a different account if multiple entries exist, allowing credential confusion/substitution.

**Code**:
```bash
# Fallback to service-only for org-managed devices
password="$(security find-generic-password \
    -s "$service" \
    -w 2>/dev/null)" || return 1
```

**Fix**:
Make fallback opt-in via environment variable:
```bash
# Fallback to service-only (opt-in for org-managed devices)
if [[ "${GLM_ALLOW_SERVICE_ONLY_KEYCHAIN:-0}" == "1" ]]; then
    password="$(security find-generic-password \
        -s "$service" \
        -w 2>/dev/null)" || return 1
    echo "$password"
    return 0
else
    return 1
fi
```

**Impact**: May fetch wrong credentials in multi-user scenarios

---

#### Issue #5: Supply Chain Regression - ZAI_MCP_VERSION Default

**Severity**: MEDIUM
**File**: `credentials/common.sh:58`
**Reported By**: ChatGPT/Codex

**Problem**:
If `credentials/security.conf` is missing or unreadable, `ZAI_MCP_VERSION` defaults to `"latest"`, reintroducing supply-chain drift risk.

**Code**:
```bash
# In load_security_config()
ZAI_MCP_VERSION="${ZAI_MCP_VERSION:-latest}"
```

**Fix**:
Pin secure default in code too:
```bash
ZAI_MCP_VERSION="${ZAI_MCP_VERSION:-1.0.0}"
```

**Impact**: Unpredictable package versions if config file unavailable

---

#### Issue #6: NPM Version Not Format-Validated

**Severity**: MEDIUM
**File**: `bin/glm-mcp-wrapper:124-132`
**Reported By**: ChatGPT/Codex

**Problem**:
`ZAI_MCP_VERSION` is not format-validated. Non-semver npm spec forms (tags/aliases) are accepted, weakening version control policy.

**Code**:
```bash
package_spec="@z_ai/mcp-server@${ZAI_MCP_VERSION}"
exec npx -y "$package_spec"
```

**Fix**:
Enforce strict semver validation:
```bash
# Validate semver format (major.minor.patch[-prerelease][+build])
if [[ ! "$ZAI_MCP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)*$ ]]; then
    log_error "Invalid ZAI_MCP_VERSION format: $ZAI_MCP_VERSION (must be semver)"
    exit 1
fi

package_spec="@z_ai/mcp-server@${ZAI_MCP_VERSION}"
exec npx -y "$package_spec"
```

**Impact**: Allows npm tags like "latest", "beta", defeating version pinning

---

#### Issue #7: Cleanup Directory Manipulation Risk

**Severity**: MEDIUM
**File**: `bin/glm-cleanup-sessions:109, 264, 330`
**Reported By**: ChatGPT/Codex

**Problem**:
Cleanup target is controlled by ambient `CLAUDE_CONFIG_DIR`. If environment is manipulated, cleanup may operate outside intended GLM location.

**Code**:
```bash
SESSIONS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude-glm}/glm-sessions"
...
find "$SESSIONS_DIR" -name "glm-*.json" -type f -delete
```

**Fix**:
Pin expected base directory and enforce canonical prefix check:
```bash
# Pin expected base directory
EXPECTED_BASE="$HOME/.claude-glm"
SESSIONS_DIR="${CLAUDE_CONFIG_DIR:-$EXPECTED_BASE}/glm-sessions"

# Validate sessions directory is within expected location
if command -v realpath &>/dev/null; then
    canonical_dir="$(realpath -m "$SESSIONS_DIR")" || handle_error "Cannot resolve sessions directory"
    canonical_expected="$(realpath -m "$EXPECTED_BASE/glm-sessions")" || handle_error "Cannot resolve expected directory"

    if [[ "$canonical_dir" != "$canonical_expected" ]]; then
        handle_error "Sessions directory outside expected location: $canonical_dir"
    fi
fi
```

**Impact**: Environment manipulation could cause unintended file deletion

---

### 🟡 LOW Severity (1 issue)

#### Issue #8: Missing jq Dependency Check

**Severity**: LOW
**File**: `scripts/security-scan.sh:105`
**Reported By**: Gemini

**Problem**:
Script relies on `jq` to parse gitleaks reports but doesn't check if `jq` is installed at the beginning (unlike gitleaks check).

**Code**:
```bash
leak_count=$(jq '. | length' "$REPORT_FILE" 2>/dev/null || echo "0")
```

**Fix**:
Add dependency check at script initialization:
```bash
# After gitleaks check
if [[ "$GENERATE_REPORT" == true ]] && ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  WARNING: jq not installed (needed for report parsing)${NC}"
    echo -e "${YELLOW}Install with: brew install jq${NC}"
fi
```

**Impact**: Script fails ungracefully if jq missing and --report used

---

## Summary

| Severity | Count | Issues |
|----------|-------|--------|
| 🔴 HIGH | 2 | #1 (macOS blocker), #2 (PATH poisoning) |
| 🟠 MEDIUM | 5 | #3-7 (chmod, credentials, version control) |
| 🟡 LOW | 1 | #8 (jq check) |
| **Total** | **8** | **All must be fixed for public release** |

## External Review Credits

- **Gemini** (Google): Architectural security analysis, macOS compatibility
- **ChatGPT/Codex** (OpenAI): Code-level vulnerability assessment, attack vectors

## Overall Assessment

**Status**: ❌ **NOT READY for public release**

**Blockers**:
1. Issue #1 (xargs -r) breaks the tool entirely on macOS
2. Issue #2 (PATH poisoning) is a credential theft vulnerability

**Recommendation**: Fix all 8 issues before proceeding with public release.

## Next Steps

1. ⏭️ Fix all 8 issues
2. ⏭️ Verify fixes with syntax check and manual testing
3. ⏭️ Re-run security scan
4. ⏭️ Consider third round of external review (optional)
5. ⏭️ Tag as v2.0.2
6. ⏭️ Update PUBLIC-RELEASE-CHECKLIST.md
7. ⏭️ Ready for public release

---

**Last Updated**: 2026-02-12
**Review Round**: 2 of 2 (or more if needed)
