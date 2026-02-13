# Security Fixes v2.0.1

**Date**: 2026-02-12
**Status**: ✅ All issues fixed
**External Review**: Gemini + ChatGPT/Codex

## Summary

Fixed all 12 security issues identified in external security review before making repository public.

### Issues Fixed

#### 🔴 HIGH Severity (6 issues)

1. ✅ **Path Traversal** (`bin/glm-cleanup-sessions`)
   - Added session ID validation with strict regex
   - Added path canonicalization and verification
   - Prevents arbitrary file deletion

2. ✅ **Session File Permissions** (`bin/claude-by-glm`)
   - Added `umask 077` at start of main()
   - Added explicit `chmod 700` for directories
   - Added explicit `chmod 600` for session files

3. ✅ **macOS Keychain Process Exposure** (`credentials/macos.sh`)
   - Changed from command-line password argument to stdin
   - Prevents API key visibility in process list

4. ✅ **macOS Credential Account Mismatch** (`credentials/macos.sh`)
   - Added service+account matching for fetch/delete
   - Fallback to service-only for org-managed devices
   - Prevents wrong credential selection

5. ✅ **Environment Variable Exposure** (`bin/claude-by-glm`)
   - Changed from `exec` to `exec env -i` with allowlist
   - Minimizes environment variable exposure
   - Only passes essential variables

6. ✅ **Wrong Cleanup Directory** (`bin/glm-cleanup-sessions`)
   - Updated path from `~/.claude/glm-sessions` to `${CLAUDE_CONFIG_DIR}/glm-sessions`
   - Fixes cleanup for v2.0.0 isolated config

#### 🟠 MEDIUM Severity (4 issues)

7. ✅ **Config Parsing Literal Variable** (`credentials/common.sh`)
   - Added variable expansion for `${USER:-$LOGNAME}` pattern
   - Ensures correct account name resolution

8. ✅ **Unpinned NPX Package** (`credentials/security.conf`)
   - Changed default from `latest` to `1.0.0`
   - Reduces supply chain risk

9. ✅ **API Key Regex Mismatch** (`bin/glm-mcp-wrapper`, `bin/install-key.sh`)
   - Aligned validation to exclude dangerous characters
   - Allows common API key characters (+, /, =)

10. ✅ **Pre-commit Permission Check** (`.git/hooks/pre-commit`)
    - Changed from warning to blocking error
    - Enforces security policy

#### 🟡 LOW Severity (2 issues)

11. ✅ **Scan Result Handling** (`scripts/security-scan.sh`)
    - Capture exit code immediately in variable
    - Fixes false success/failure reporting

12. ✅ **xargs Edge Case** (`credentials/common.sh`)
    - Added `-r` flag to all xargs calls
    - Prevents unexpected behavior on empty input

## Files Modified

```
.git/hooks/pre-commit
bin/claude-by-glm
bin/glm-cleanup-sessions
bin/glm-mcp-wrapper
credentials/common.sh
credentials/macos.sh
credentials/security.conf
scripts/security-scan.sh
```

## Verification

### Security Scan
```bash
./scripts/security-scan.sh --full
# Result: ✅ 45 commits, 0 secrets found
```

### Syntax Check
```bash
bash -n [all modified files]
# Result: ✅ All pass
```

### Path Traversal Test
```bash
bin/glm-cleanup-sessions --session "../../../etc/passwd"
# Result: ✅ Blocked with "Invalid session ID format"
```

## External Review Credits

- **Gemini** (Google): Architectural security analysis
- **ChatGPT/Codex** (OpenAI): Code-level vulnerability assessment

Both AI models provided comprehensive reviews that identified all issues.

## Impact

- **Before**: 12 security vulnerabilities (6 HIGH, 4 MEDIUM, 2 LOW)
- **After**: 0 known vulnerabilities
- **Status**: ✅ Ready for public release

## Next Steps

1. ✅ All fixes implemented
2. ✅ All tests passing
3. ✅ Security scan clean
4. ⏭️ Commit fixes
5. ⏭️ Tag as v2.0.1
6. ⏭️ Update PUBLIC-RELEASE-CHECKLIST.md
7. ⏭️ Ready to make repository public
