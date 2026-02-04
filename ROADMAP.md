# GLM MCP Wrapper System - Roadmap

Future development plans and potential improvements for the GLM MCP Wrapper System.

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.7.1 | 2026-02-04 | Documentation update (INSTALL, TROUBLESHOOTING, ROADMAP) |
| v1.7.0 | 2026-02-03 | Add `--list` and `--session` options to glm-cleanup-sessions |
| v1.7.0 | 2026-02-03 | Add glm-update and glm-cleanup-sessions utilities |
| v1.6.0 | 2026-02-03 | Session isolation for GLM settings |
| v1.5.0 | 2026-02-03 | Input validation for account names and API keys |
| v1.4.3 | 2026-02-02 | Keychain unlock for SSH sessions |
| v1.3.4 | 2026-02-01 | Shell detection fixes, platform detection fixes |

---

## Planned Features

### Priority: High

#### GLM Model Selection Enhancements
**Planned**: Support for all GLM model variants with smart defaults.

**New Models from 2026**:
- **GLM-4.7-Flash** (30B MoE, lightweight, open source)
  - Faster response times
  - Lower cost for simple tasks
  - Best model in 30B class

**Features**:
- Model-specific profiles (Flash for quick tasks, 4.7 for complex)
- Auto-switch based on task complexity
- Visual code comprehension mode (GLM-4.7)

**References**:
- [GLM-4.7 Official Docs](https://docs.z.ai/guides/llm/glm-4.7)
- [GLM-4.7-Flash Announcement](https://www.zhipuai.cn/en/news/148)

#### MCP Server Mode (Claude Code as MCP Server)
**Current**: Wrapper connects to Z.ai MCP server.

**Planned**: Make claude-by-glm function as an MCP server itself.

**Features**:
- Other MCP clients can connect to GLM models through our wrapper
- Unified interface for GLM capabilities
- Tool exposing for advanced workflows

**References**:
- [Claude Code Changelog](https://code.claude.com/docs/en/changelog)
- [MCP Server Specification](https://modelcontextprotocol.io/specification/2025-06-18/server)

#### Shell Completion Scripts
**Planned**: Bash/zsh/fish completion for all commands.

**Features**:
- Command option completion
- Session ID completion for glm-cleanup-sessions
- Model name completion

**Example**:
```bash
# Tab completion for commands
glm-cleanup-sessions --<TAB>
# --dry-run  --keep  --all  --list  --session

# Session ID completion
glm-cleanup-sessions --session <TAB>
# glm-1738634123-1234  glm-1738634256-5678
```

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

#### Repository Indexing (Inspired by Aider/Cursor)
**Planned**: Index repository for context-aware operations.

**Features**:
- Repository structure awareness
- Dependency tracking
- Smart file selection based on task context
- Multi-file editing support

**References**:
- [Aider vs Cursor Comparison](https://brlikhon.engineer/blog/claude-code-vs-cursor-vs-aider-the-terminal-ai-coding-battle-of-2026-complete-performance-cost-breakdown-)
- [Best AI Coding Agents 2026](https://www.faros.ai/blog/best-ai-coding-agents-2026)

#### MCP Tool Optimization (Lazy Loading)
**Current**: All MCP tools loaded at startup.

**Planned**: Implement lazy loading for MCP tools.

**Benefits**:
- Faster startup time
- Reduced memory usage
- Better performance (one of Claude Code's most requested features)

**References**:
- [Claude Code MCP Tool Search](https://venturebeat.com/orchestration/claude-code-just-got-updated-with-one-of-the-most-requested-user-features)
- [MCP Best Practices](https://www.cdata.com/blog/mcp-server-best-practices-2026)

#### Task Management with Dependencies
**Planned**: Track tasks with dependency tracking.

**Features**:
- Task creation with dependencies
- Block/blocked-by relationships
- Status tracking (pending/in_progress/completed)
- Task list visualization

**References**:
- [Claude Code 2.1 Features](https://medium.com/@joe.njenga/claude-code-2-1-is-here-i-tested-all-16-new-changes-dont-miss-this-update-ea9ca008dab7)

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

#### MCP Protocol Enhancements (2025-06-18 Specification)
**Planned**: Support latest MCP protocol features.

**New Capabilities**:
- **Elicitation**: Better context gathering
- **Structured content**: Richer data exchange
- **OAuth authentication**: Enhanced security
- **Workflow cancellation**: Graceful operation cancellation
- **Read-only modes**: Safe operations
- **Collaborator metadata**: Multi-user support

**References**:
- [MCP Specification 2025-06-18](https://modelcontextprotocol.io/specification/2025-06-18/server)
- [MCP Security Best Practices](https://www.akto.io/blog/mcp-security-best-practices)

#### LSP Integration
**Planned**: Language Server Protocol support for code intelligence.

**Features**:
- Code completion
- Go to definition
- Find references
- Diagnostics

**References**:
- [Claude Code V3 LSP Support](https://www.gradually.ai/changelogs/claude-code/)

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

## 2026 Industry Trends & Competitive Analysis

### AI CLI Tools Landscape (2026)

Based on market analysis of leading AI CLI tools:

| Tool | Type | Key Features | Cost vs Cursor |
|------|------|--------------|----------------|
| **Aider** | CLI | Repository indexing, dependency tracking | 40-60% lower |
| **Cursor** | IDE | Native AI integration, multi-file editing | Baseline |
| **Continue** | IDE Extension | Open source, cross-platform | Free |
| **Claude Code** | CLI | MCP integration, agent orchestration | Official |

**Sources**:
- [Claude Code vs Cursor vs Aider](https://brlikhon.engineer/blog/claude-code-vs-cursor-vs-aider-the-terminal-ai-coding-battle-of-2026-complete-performance-cost-breakdown-)
- [Best AI Tools for Coding 2026](https://dev.to/lightningdev123/best-ai-tools-for-coding-in-2026-a-practical-guide-for-modern-developers-22hk)
- [AI Coding Agents 2026](https://www.faros.ai/blog/best-ai-coding-agents-2026)

### MCP Server Trends (2026)

**Predictions**:
- Every PR will have AI-assisted reviews as standard
- Startups will universally adopt MCP servers
- Agents will become portable across platforms
- MCP will become universal interface for AI-tool interactions

**Emerging Categories**:
- Browser automation (Playwright MCP)
- DevOps workflow automation
- Database integration
- Security-focused servers
- Media/content management

**Sources**:
- [Why Every Startup Will Have an MCP Server](https://codingplainenglish.medium.com/why-every-startup-will-have-an-mcp-server-by-2026-88c5d16cecab)
- [Best MCP Servers 2026](https://www.builder.io/blog/best-mcp-servers-2026)
- [MCP Future Roadmap](https://www.getknit.dev/blog/the-future-of-mcp-roadmap-enhancements-and-whats-next)

### GLM Model Evolution (2025-2026)

| Model | Release | Key Improvement | Context Window |
|-------|---------|-----------------|----------------|
| GLM-4.5 | July 2025 | Agentic optimization | 128K in / 96K out |
| GLM-4.6 | Sep 2025 | +15% token efficiency | 128K-200K |
| GLM-4.7 | Dec 2025 | +5.8% multilingual coding | 200K in / 128K out |
| GLM-4.7-Flash | Jan 2026 | 30B lightweight model | Same as 4.7 |

**Sources**:
- [GLM-4.7 Official Docs](https://docs.z.ai/guides/llm/glm-4.7)
- [Zhipu AI Open Platform](https://open.bigmodel.cn/)
- [GLM-4.5 Review](https://www.analyticsvidhya.com/blog/2025/07/glm-4-5-and-glm-4-5-air-launched-by-z-ai/)

---

## Potential Improvements

### Code Quality

- [x] Add Shell completion scripts (bash/zsh/fish) - Planned
- [ ] Add automated tests (Bats for shell scripts)
- [ ] Add ShellCheck to CI/CD pipeline
- [ ] Improve error messages with actionable suggestions
- [ ] Add `--verbose` flag for debugging output
- [ ] Add `--dry-run` to all destructive operations

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
