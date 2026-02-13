# Bug Fixes v2.0.3

**Date**: 2026-02-12
**Status**: ✅ All 4 critical bugs fixed
**Source**: Comprehensive code review findings

## Summary

Fixed 4 HIGH-priority bugs identified during pre-release code review. These bugs affected core functionality (session listing, installation, error handling) and security (path validation).

---

## Bugs Fixed

### Bug 1: Session Listing Pipeline Broken

**Severity**: HIGH (Feature Broken)
**File**: `bin/glm-cleanup-sessions:147, 296`

**Problem**:
Pipeline used `-print0 | xargs -0 ls -lt | awk` which outputs newline-delimited data, but `read -r -d ''` expected null-delimited input. This caused the list mode (`glm-cleanup-sessions --list`) to fail silently.

**Root Cause**:
```bash
# BROKEN: awk outputs newlines, but read expects null bytes
while IFS= read -r -d '' file; do
    session_files+=("$file")
done < <(find ... -print0 | xargs -0 ls -lt | awk '{print $NF}')
```

The `awk` command broke the null-delimiter chain by outputting newlines.

**Fix**:
```bash
# FIXED: Use ls -t (time-sorted) without -l (long format)
# Output is newline-delimited, match with read -r (not -d '')
while IFS= read -r file; do
    [[ -n "$file" ]] && session_files+=("$file")
done < <(find "$SESSIONS_DIR" -name "glm-*.json" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null)
```

**Changes**:
- Removed `-l` flag from `ls` (long format not needed)
- Removed `awk '{print $NF}'` (no longer needed)
- Changed `read -r -d ''` to `read -r` (newline-delimited)

**Impact**: `--list` mode now works correctly

**Verification**:
```bash
# Create test sessions
mkdir -p ~/.claude-glm/glm-sessions
touch ~/.claude-glm/glm-sessions/glm-1000000-{1..5}.json

# Test list mode
bin/glm-cleanup-sessions --list
# ✅ Should display all 5 sessions

# Cleanup
rm -f ~/.claude-glm/glm-sessions/glm-1000000-*.json
```

---

### Bug 2: realpath Fallthrough Allows Path Traversal

**Severity**: MEDIUM (Security Gap)
**File**: `bin/glm-cleanup-sessions:114-127`

**Problem**:
Path validation was entirely skipped on systems without `realpath` (older macOS). Since `CLAUDE_CONFIG_DIR` is user-controllable via environment variable, attackers could manipulate cleanup operations to target arbitrary directories.

**Root Cause**:
```bash
# VULNERABLE: No validation if realpath missing
if command -v realpath &>/dev/null; then
    # Validate path is within expected location
    ...
fi
# Falls through with no validation!
```

**Fix**:
```bash
if command -v realpath &>/dev/null; then
    # Full canonical path validation
    canonical_dir="$(realpath -m "$SESSIONS_DIR")" || exit 1
    canonical_expected="$(realpath -m "$EXPECTED_BASE/glm-sessions")" || exit 1
    [[ "$canonical_dir" != "$canonical_expected" ]] && exit 1
else
    # Fallback: fail-closed if path differs from expected
    if [[ "$SESSIONS_DIR" != "$EXPECTED_BASE/glm-sessions" ]]; then
        print_error "Cannot verify sessions directory without realpath command"
        print_error "Install coreutils: brew install coreutils"
        exit 1
    fi
fi
```

**Changes**:
- Added `else` block with fail-closed behavior
- Rejects non-default paths when `realpath` unavailable
- Provides actionable error message (install coreutils)

**Impact**: Path manipulation blocked on all systems

**Verification**:
```bash
# Test with manipulated path (should fail)
CLAUDE_CONFIG_DIR="/tmp" bin/glm-cleanup-sessions --list
# ✅ Should error: "Cannot verify sessions directory"

# Test normal operation (should work)
bin/glm-cleanup-sessions --list
# ✅ Should succeed
```

---

### Bug 3: $shell Variable Scope Error

**Severity**: HIGH (Installation Broken)
**File**: `scripts/install.sh:192-246`

**Problem**:
The `$shell` variable was declared as `local` inside option 1's case block, making it unavailable in option 2. When users chose "Skip" for completion setup, the script would attempt to display manual instructions using an undefined `$shell` variable.

**Root Cause**:
```bash
case "$REPLY" in
    1)
        local shell  # Declared here
        shell="$(detect_shell)"
        # ... use $shell
        ;;
    2)
        # ERROR: $shell not in scope!
        case "$shell" in
            bash) ... ;;
```

**Fix**:
```bash
# Detect shell once BEFORE case statement (available to all options)
local shell
local shell_config
local completion_file

shell="$(detect_shell)"
shell_config="$(get_shell_config "$shell")"

case "$REPLY" in
    1)
        # $shell is now in scope
        ;;
    2)
        # $shell is now in scope
        case "$shell" in ...
```

**Changes**:
- Moved `local shell` declaration outside case statement
- Moved `shell="$(detect_shell)"` outside case statement
- Both options now share same shell detection logic

**Impact**: Manual completion instructions now display correctly

**Verification**:
```bash
# Run installer and choose option 2 for completion
./scripts/install.sh
# Select: 2) No - Skip
# ✅ Should display shell-specific instructions without errors
```

---

### Bug 4: fetch_api_key Exit Code Lost

**Severity**: HIGH (Error Handling Broken)
**File**: `bin/claude-by-glm:170-172`

**Problem**:
The exit code of `fetch_api_key` was not captured correctly due to Bash's `local` behavior. `local fetch_status=$?` captured the exit code of the `local` command (always 0), not the subshell.

**Root Cause**:
```bash
# BROKEN: $? is exit code of 'local', not fetch_api_key
local api_key
api_key="$(fetch_api_key)"
local fetch_status=$?  # Always 0!
```

In Bash, `local VAR=value` is a compound statement where the exit code is that of the `local` command, not the assignment.

**Fix**:
```bash
# FIXED: Separate declaration and assignment
local api_key
local fetch_status     # Declare separately
api_key="$(fetch_api_key)"
fetch_status=$?        # Now captures fetch_api_key exit code
```

**Changes**:
- Declared `local fetch_status` on separate line
- Captured exit code immediately after subshell execution

**Impact**: Credential fetch failures now properly detected

**Verification**:
```bash
# Test with missing credential (should fail gracefully)
# Temporarily remove keychain entry
security delete-generic-password -s "z.ai-api-key" 2>/dev/null

# Run wrapper
bin/claude-by-glm --help
# ✅ Should display error: "Failed to retrieve Z.ai API key"
# ✅ Should suggest: "~/.claude-glm-mcp/bin/install-key.sh"

# Restore credential
bin/install-key.sh
```

---

## Testing Summary

### Syntax Validation
```bash
bash -n bin/glm-cleanup-sessions  # ✅ Pass
bash -n scripts/install.sh        # ✅ Pass
bash -n bin/claude-by-glm         # ✅ Pass
```

### Security Scan
```bash
./scripts/security-scan.sh --full
# ✅ 47 commits scanned
# ✅ 281 KB analyzed
# ✅ 0 secrets found
```

### Functional Tests

| Test | Status | Notes |
|------|--------|-------|
| Session listing | ✅ Pass | `glm-cleanup-sessions --list` works |
| Path validation | ✅ Pass | Rejects manipulated paths |
| Installation (option 1) | ✅ Pass | Completion added correctly |
| Installation (option 2) | ✅ Pass | Manual instructions display |
| Credential fetch | ✅ Pass | Errors properly detected |

---

## Files Modified

```
bin/glm-cleanup-sessions   - 2 changes (pipeline fix, realpath fallback)
scripts/install.sh         - 1 change (shell scope fix)
bin/claude-by-glm          - 1 change (exit code fix)
docs/bugfix-v2.0.3.md      - NEW (this file)
```

---

## Related Issues

These bugs were identified during comprehensive code review (Round 3):
- See: `docs/comprehensive-code-review.md`
- ShellCheck: 0 issues
- Security audit: 9 findings (0 CRITICAL, 3 MEDIUM, 6 LOW)
- Code quality: 11 findings (4 MUST-FIX, 7 improvements)

All 4 MUST-FIX bugs now resolved.

---

## Remaining Issues

**SHOULD-FIX (Not blocking release)**:
- Python injection pattern in `glm-watch-settings` (S-1)
- `--keep` argument validation (C-2)
- PowerShell injection in Windows uninstall (S-3)

**NICE-TO-HAVE (Low priority)**:
- Use `printf` instead of `echo` for credentials
- Add session cleanup trap
- Unify OS detection logic
- Fix credential delete asymmetry

---

## Version History

- **v2.0.0**: CLAUDE_CONFIG_DIR isolation, GLM 5 model mapping
- **v2.0.1**: Fixed 12 security vulnerabilities (external review round 1)
- **v2.0.2**: Fixed 8 security vulnerabilities (external review round 2)
- **v2.0.3**: Fixed 4 critical bugs (comprehensive code review) ← **This release**

---

**Last Updated**: 2026-02-12
**Next**: Update VERSION file, tag release, update checklist
