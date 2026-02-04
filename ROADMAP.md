# GLM MCP Wrapper System - Roadmap

Future development plans and potential improvements for the GLM MCP Wrapper System.

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.7.0 | 2026-02-03 | Add `--list` and `--session` options to glm-cleanup-sessions |
| v1.7.0 | 2026-02-03 | Add glm-update and glm-cleanup-sessions utilities |
| v1.6.0 | 2026-02-03 | Session isolation for GLM settings |
| v1.5.0 | 2026-02-03 | Input validation for account names and API keys |
| v1.4.3 | 2026-02-02 | Keychain unlock for SSH sessions |
| v1.3.4 | 2026-02-01 | Shell detection fixes, platform detection fixes |

---

## Planned Features

### Priority: High

#### Windows Credential Manager Integration
**Current**: Windows uses environment variables only (insecure).

**Planned**: Native Windows Credential Manager support.
```powershell
# Store in Windows Credential Manager
cmdkey /generic:z.ai-api-key /user:$env:USERNAME /pass:$env:ZAI_API_KEY

# Retrieve from Credential Manager
cmdkey /generic:z.ai-api-key | Select-String "Pass"
```

**Benefits**: Secure credential storage on Windows, matching macOS/Linux functionality.

---

### Priority: Medium

#### Configuration File Support
**Planned**: Support for `.glmrc` or `config.json` for user preferences.

**Features**:
- Default model selection
- MCP server toggle
- Session cleanup policy
- Update source directory

**Example**:
```json
{
  "defaultModel": "glm-4.7",
  "mcpEnabled": true,
  "sessionKeepCount": 10,
  "updateSource": "~/projects/claude-by-glm_safety_setting"
}
```

#### Automatic Update Check
**Planned**: Check for updates on startup or periodically.

**Features**:
- Compare installed vs source version
- Notify if update available
- Optional auto-update prompt

#### Session Profiles
**Planned**: Named session configurations for different use cases.

**Example**:
```bash
# Create session profiles
claude-by-glm --profile work    # Uses work-specific settings
claude-by-glm --profile personal # Uses personal settings
```

---

### Priority: Low

#### Multiple API Key Support
**Planned**: Support multiple Z.ai API keys for different purposes.

**Use cases**:
- Separate keys for development/production
- Different keys for different projects
- Key rotation without downtime

#### Logging and Diagnostics
**Planned**: Optional logging for troubleshooting.

**Features**:
- Configurable log level
- Log file rotation
- Diagnostic command (`glm-diagnostics`)

#### Statistics and Usage Tracking
**Planned**: Track API usage across sessions.

**Metrics**:
- Total requests per model
- Session count and size
- Last cleanup time

---

## Potential Improvements

### Code Quality

- [ ] Add automated tests (Bats for shell scripts)
- [ ] Add ShellCheck to CI/CD pipeline
- [ ] Improve error messages with actionable suggestions
- [ ] Add `--verbose` flag for debugging output

### Documentation

- [ ] Add video tutorial for installation
- [ ] Add architecture diagram
- [ ] Add contribution guidelines
- [ ] Translate documentation to Korean

### Security

- [ ] Audit credential storage implementations
- [ ] Add key rotation support
- [ ] Add certificate pinning for API calls
- [ ] Security audit by third party

### User Experience

- [ ] Interactive setup wizard
- [ ] Progress bars for long operations
- [ ] Better error recovery (auto-fix common issues)
- [ ] Shell completion scripts (bash/zsh/fish)

---

## Deprecated Features

None currently.

---

## Request for Comments

If you have suggestions for future features, please:
1. Check existing [GitHub Issues](https://github.com/wgsim/claude-glm-wrapper/issues)
2. Create a new issue with the `feature-request` label
3. Describe the use case and proposed solution

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.
