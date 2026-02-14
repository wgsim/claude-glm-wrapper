# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.13] - 2026-02-14

### Security
- **PRODUCTION READY**: Achieved PASS verdict from external security reviewers (Codex & Gemini)
- Fixed last naked `security` command in `check_keychain_accessible()` - use absolute path `/usr/bin/security`
- Eliminated all PATH poisoning vulnerabilities through 10 rounds of external review

### Summary
Final security hardening release. All external commands now use absolute paths. Zero known vulnerabilities.

## [2.0.12] - 2026-02-14

### Security
- Use absolute paths for ALL remaining external commands: `/usr/bin/env`, `/bin/rm`
- Update all `security` commands in `credentials/macos.sh` to use `/usr/bin/security` (9 locations)
- Prevent PATH-dependent execution of security-critical operations

## [2.0.11] - 2026-02-14

### Security
- **MAJOR RESTRUCTURING**: Move ALL session setup operations before credential fetch
- Ensure no external commands execute after credentials enter environment
- Complete execution order: setup → validate → fetch credentials → launch
- Eliminate command execution vulnerability window

## [2.0.10] - 2026-02-14

### Security
- Fix command substitution in `load_mcp_config()` - move call before credentials
- Add Bash 3.2 compatibility for macOS default shell
- Use builtin `printf '%(%s)T'` for Bash 4.2+, fallback to `/bin/date` for older versions

### Fixed
- Bash compatibility issue on macOS (default Bash 3.2 doesn't support `printf '%(%s)T'`)

## [2.0.9] - 2026-02-14

### Security
- Fix command substitution timing issues after secret operations
- Move `claude_bin` resolution to start of `main()` before credential fetch

## [2.0.8] - 2026-02-14

### Security
- Fix 3 critical issues from external review round 4
- Improve command execution order relative to credential operations

## [2.0.7] - 2026-02-14

### Fixed
- Restore terminal colors in SSH sessions by preserving `TERM` environment variable
- Change `TERM=dumb` to `TERM="${TERM:-xterm-256color}"` for better SSH experience

## [2.0.6] - 2026-02-13

### Security
- Add portable path canonicalization function `canonicalize_path()` in `scripts/common-utils.sh`
- Replace all `realpath -m` calls with portable implementation (GNU/BSD compatible)

### Fixed
- Fix 5 critical regressions from v2.0.5:
  - Remove `readonly PATH` that conflicts with `setup_path()`
  - Fix `realpath -m` portability issue (GNU-only flag, not available on BSD/macOS)
  - Fix `local` keyword at top-level in `bin/glm-cleanup-sessions`

## [2.0.5] - 2026-02-13

### Security
- Fix all 9 critical issues from external review round 3 (Codex & Gemini)
- Comprehensive PATH hardening and command injection prevention
- Validate all external command paths
- Prevent PATH manipulation attacks

## [2.0.4] - 2026-02-12

### Fixed
- Fix all 7 remaining code quality issues from comprehensive review
- Improve error handling and edge cases

## [2.0.3] - 2026-02-12

### Fixed
- Fix 4 critical bugs from comprehensive code review
- Improve robustness and error handling

## [2.0.2] - 2026-02-12

### Security
- Fix all 8 vulnerabilities from external review round 2 (Codex & Gemini)
- Strengthen credential handling security
- Improve input validation

## [2.0.1] - 2026-02-12

### Security
- Fix all 12 vulnerabilities from external review round 1 (Codex & Gemini)
  - 6 HIGH severity
  - 4 MEDIUM severity
  - 2 LOW severity
- Initial comprehensive security hardening

### Added
- Security quick start guide
- Automated secret scanning with gitleaks
- Pre-commit hooks for credential protection

## [2.0.0] - 2026-02-11

### Added
- **CLAUDE_CONFIG_DIR isolation**: GLM sessions use separate `~/.claude-glm` config directory
- Session-specific settings for complete isolation from official Claude sessions
- Comprehensive error handling and validation
- Security automation:
  - Automated gitleaks secret scanning
  - Pre-commit hooks
  - Comprehensive `.gitignore` with 140+ security patterns

### Changed
- **BREAKING**: GLM sessions now use isolated config directory (`~/.claude-glm`)
- Default GLM model mappings updated for GLM 5 release (2026-02-11):
  - Haiku: `glm-4.5-air` → `glm-4.6`
  - Sonnet: `glm-4.6` → `glm-4.7`
  - Opus: `glm-4.7` → `glm-5`

### Fixed
- Settings.json sync issues between GLM and official Claude sessions
- Model selection persistence across sessions

## [1.7.1] - 2026-02-10

### Fixed
- Documentation updates for v1.7.0 features

## [1.7.0] - 2026-02-10

### Added
- Session cleanup utility: `glm-cleanup-sessions`
  - `--list`: View all sessions with details
  - `--keep N`: Keep last N sessions
  - `--session <id>`: Delete specific sessions
  - `--dry-run`: Preview deletions
- Update utility: `glm-update`
- Session-isolated settings for GLM (prevents UI state pollution)

### Changed
- Force opus model to override UI state caching
- Improved session management and cleanup

## [1.6.0] - 2026-02-09

### Added
- Session-isolated settings file per GLM invocation
- Prevent settings pollution between sessions
- Automatic cleanup on exit

### Changed
- Each `claude-by-glm` invocation creates isolated session config

## [1.5.0] - 2026-02-08

### Security
- Add comprehensive input validation
- Document environment variable exposure
- Improve credential handling security

## [1.4.3] - 2026-02-08

### Fixed
- Remove unsupported `-t` option from `security add-generic-password`
- Add keychain unlock for SSH/non-interactive sessions

## [1.4.2] - 2026-02-08

### Fixed
- Remove incorrect `-U` flag usage in `security add-generic-password`

## [1.4.1] - 2026-02-08

### Fixed
- Validate password before storing in keychain
- Check `security` command output for errors
- Better error messages for keychain operations

## [1.4.0] - 2026-02-08

### Added
- Interactive API key input with validation and retry loop
- Better user experience for key installation

## [1.3.9] - 2026-02-07

### Fixed
- Relax overly restrictive ACL permissions in macOS keychain
- Improve keychain accessibility

## [1.3.8] - 2026-02-07

### Fixed
- Handle unset `ZDOTDIR` variable in install script
- Improve zsh configuration detection

## [1.3.7] - 2026-02-07

### Added
- Interactive account name prompt in `install-key.sh`
- Better handling of custom account names

## [1.3.6] - 2026-02-07

### Changed
- Use service-only lookup for macOS Keychain (org-managed device compatibility)
- Add `GLM_ALLOW_SERVICE_ONLY_KEYCHAIN` opt-in flag

## [1.3.5] - 2026-02-07

### Fixed
- Handle macOS Keychain account name prefixes on org-managed devices
- Fallback to service-only lookup when needed

## [1.3.0] - 2026-02-06

### Changed
- **BREAKING**: Rename install directory from `.glm-mcp` to `.claude-glm-mcp`
- Improve clarity and avoid conflicts

## [1.2.0] - 2026-02-05

### Changed
- Centralize configuration in `credentials/security.conf`
- Fix critical security issues in credential handling

### Security
- Improve credential storage security
- Fix permission issues

## [1.1.0] - 2026-02-04

### Added
- Multi-platform credential storage support:
  - macOS: Keychain (`security` command)
  - Linux: libsecret (`secret-tool`)
  - Windows: Environment variable (`ZAI_API_KEY`)
- Platform abstraction layer for credentials

## [1.0.0] - 2026-02-03

### Added
- Initial release: GLM MCP Wrapper System
- Secure credential management with macOS Keychain
- Z.ai GLM model support (GLM 4.5-air, 4.6, 4.7)
- Optional Z.ai MCP server integration
- Installation and setup scripts
- Basic documentation

---

## Version Scheme

- **2.x.x**: Security-hardened production releases
- **1.x.x**: Feature development releases
- **0.x.x**: Pre-release/experimental

## Links

- [Repository](https://github.com/wgsim/claude-glm-wrapper)
- [Security Policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)

[2.0.13]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.13
[2.0.12]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.12
[2.0.11]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.11
[2.0.10]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.10
[2.0.9]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.9
[2.0.8]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.8
[2.0.7]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.7
[2.0.6]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.6
[2.0.5]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.5
[2.0.4]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.4
[2.0.3]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.3
[2.0.2]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.2
[2.0.1]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.1
[2.0.0]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v2.0.0
[1.7.1]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.7.1
[1.7.0]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.7.0
[1.6.0]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.6.0
[1.5.0]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.5.0
[1.4.3]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.4.3
[1.4.2]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.4.2
[1.4.1]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.4.1
[1.4.0]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.4.0
[1.3.9]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.3.9
[1.3.8]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.3.8
[1.3.7]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.3.7
[1.3.6]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.3.6
[1.3.5]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.3.5
[1.3.0]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.3.0
[1.2.0]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.2.0
[1.1.0]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.1.0
[1.0.0]: https://github.com/wgsim/claude-glm-wrapper/releases/tag/v1.0.0
