# GLM MCP Wrapper System - Roadmap

Future development plans and potential improvements for the GLM MCP Wrapper System.

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.7.2 | 2026-02-04 | ROADMAP refocused on Phase 2 (GLM Team Mode) |
| v1.7.1 | 2026-02-04 | Documentation update (INSTALL, TROUBLESHOOTING, ROADMAP) |
| v1.7.0 | 2026-02-03 | Add `--list` and `--session` options to glm-cleanup-sessions |
| v1.7.0 | 2026-02-03 | Add glm-update and glm-cleanup-sessions utilities |
| v1.6.0 | 2026-02-03 | Session isolation for GLM settings |
| v1.5.0 | 2026-02-03 | Input validation for account names and API keys |
| v1.4.3 | 2026-02-02 | Keychain unlock for SSH sessions |
| v1.3.4 | 2026-02-01 | Shell detection fixes, platform detection fixes |

---

## Planned Features

### For Subscription Users (GLM Coding Plan)

> **Note**: Features in this section are available to users with Z.ai GLM Coding Plan subscription.
> Available models: GLM-4.7, GLM-4.6, GLM-4.5, GLM-4.5-Air, and Vision MCP (GLM-4.6V).

### Priority: High

#### GLM Team Mode ⭐ NEW (Phase 2)
**Planned**: Flexible multi-agent workflow with Solo/Team mode switching.

**Available Models** (via Z.ai GLM Coding Plan):

| Series | Models | Context | Best For |
|--------|--------|---------|----------|
| **GLM-4.7** | glm-4.7 | 200K+ | Complex tasks, orchestration |
| **GLM-4.6** | glm-4.6 | 200K | General coding, collaboration |
| **GLM-4.5** | glm-4.5, glm-4.5-air | 128K | Cost-effective, quick tasks |
| **Vision** | glm-4.6v (via MCP) | 128K | Screenshot analysis, OCR, diagrams |

**Three Modes with Flexible Switching**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    GLM Multi-Agent Modes                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Mode 1: Solo (단일 모드) ✅ 현재 지원                           │
│  ├─ 하나의 모델만 사용                                          │
│  ├─ 빠르고 간단한 작업                                          │
│  └─ 예: /model 4.7                                             │
│                                                                 │
│  Mode 2: Team (커스텀 팀) ⭐ Phase 2                             │
│  ├─ 사용자 정의 서브에이전트 팀                                 │
│  ├─ 유연한 역할/모델 할당                                       │
│  └─ 예: /team activate "my-glm-team"                           │
│                                                                 │
│  Mode 3: Swarm (자동 스웜) 🔮 미래 (Phase 3)                    │
│  ├─ 100+ 전문 에이전트 자동 조율                                │
│  ├─ 병렬 실행, task decomposition                               │
│  └─ 예: /swarm enable (Claude Code 공식화 후)                  │
│                                                                 │
│  모드 간 자유 전환 (유동성)                                      │
│  Solo ↔ Team ↔ Swarm                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Solo Mode Features** (현재 지원):
- `/model` command for quick switching
- Model capability display
- Current model indicator

**Team Mode Features** (Phase 2 구현 예정):
- `/team create` - Define custom agent teams
- `/team activate` - Switch to team mode
- `/team deactivate` - Return to solo mode
- `/team list` - Show all available teams
- Flexible role-to-model mapping
- Team configuration files

**Example**:
```bash
# Solo mode (current)
> /model 4.7
✓ Switched to glm-4.7 (most capable)

# Team mode (Phase 2)
> /team create "glm-reviewers"
Orchestrator: glm-4.7
Code Reviewer: glm-4.6
Quick Fixer: glm-4.5-air
Vision Expert: glm-4.6v (Vision MCP)
✓ Created team: glm-reviewers

> /team activate "glm-reviewers"
✓ Team mode activated (4 agents)

> [user uploads screenshot] "이 UI 문제 봐줘"
Orchestrator (glm-4.7): @VisionExpert 이 스크린샷 분석 부탁해
Vision Expert (glm-4.6v): [Vision MCP] 버튼 정렬 문제 발견...
Code Reviewer (glm-4.6): 수정 제안: flexbox 사용...

> /team deactivate
✓ Team mode deactivated, back to solo
```

**Agent Role System** (역할 ≠ 모델 분리):

| Agent Role | Default Model | Alternative Models |
|------------|---------------|-------------------|
| Orchestrator | glm-4.7 | glm-4.6, glm-4.5 |
| Code Specialist | glm-4.6 | glm-4.7, glm-4.5-air |
| Fast Coder | glm-4.5-air | glm-4.5, glm-4.6 |
| Vision Expert | glm-4.6v (MCP) | - |
| QA Specialist | glm-4.6 | glm-4.7 |

**Smart Task Detection** (자동 모드/모델 추천):
- Keyword-based task classification
- Suggest best mode (Solo vs Team)
- Recommend optimal model/role combination

**Example**:
```bash
> "복잡한 아키텍처 설계 검토해줘"
💡 Complex task detected. Recommending: Team mode
Orchestrator: glm-4.7 (coordination)
Code Specialist: glm-4.6 (architecture review)
Use /team activate "glm-reviewers" or /model 4.7 for solo

> "간단한 함수 리팩토링"
💡 Simple task detected. Solo mode sufficient
Use /model 4.5-air for quick results
```

**Differentiation**: Claude Code = manual agent creation vs. claude-by-glm = GLM-optimized teams with smart suggestions

**References**:
- [GLM-4.7 Official Docs](https://docs.z.ai/guides/llm/glm-4.7)
- [GLM-4.6 Official Docs](https://docs.z.ai/guides/llm/glm-4.6)
- [GLM-4.5 Official Docs](https://docs.z.ai/guides/llm/glm-4.5)
- [GLM-4-32B-0414-128K Docs](https://docs.z.ai/guides/llm/glm-4-32b-0414-128k)
- [GLM-4.6V (Vision) Docs](https://docs.z.ai/guides/vlm/glm-4.6v)
- [GLM-OCR Docs](https://docs.z.ai/guides/vlm/glm-ocr)
- [GLM-Image Docs](https://docs.z.ai/guides/image/glm-image)
- [GLM-ASR-2512 Docs](https://docs.z.ai/guides/audio/glm-asr-2512)
- [Function Calling Docs](https://docs.z.ai/guides/capabilities/function-calling)
- [Slide/Poster Agent Docs](https://docs.z.ai/guides/agents/slide)
- [Translation Agent Docs](https://docs.z.ai/guides/agents/translation)
- [Video Effect Template Agent Docs](https://docs.z.ai/guides/agents/video-template)
- [Zhipu AI Model Center](https://open.bigmodel.cn/dev/howuse/model)

**References** (Multi-Agent):
- [Create custom subagents - Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [How we built our multi-agent research system - Anthropic](https://www.anthropic.com/engineering/multi-agent-research-system)
- [When to use multi-agent systems - Anthropic](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them)

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

#### Statistics and Usage Tracking
**Planned**: Track API usage across sessions (upgrade from Low to High priority).

**Metrics**:
- Total requests per model
- Token usage and costs
- Session count and size
- Last cleanup time

**Benefits**:
- Cost monitoring and optimization
- Usage pattern analysis
- Quota management

#### Vision MCP Integration ⭐ NEW
**Planned**: Enhanced integration with Z.ai Vision MCP Server (included in subscription).

**Available Vision MCP Tools** (via GLM-4.6V):

| Tool | Capability | Use Case |
|------|------------|----------|
| **OCR** | Text extraction from images | Screenshot text, error messages |
| **UI Analysis** | Understand and analyze UI designs | Design review, layout analysis |
| **Diagram Understanding** | Interpret charts, graphs, diagrams | Technical documentation |
| **General Image Analysis** | Comprehensive image understanding | Any visual content |

**Features**:
- Automatic Vision MCP activation for image uploads
- Vision tool selection hints
- OCR-to-text workflow

**Example**:
```bash
> [uploads error screenshot]
💡 Image detected. Using Vision MCP (GLM-4.6V)
OCR Result: "Module not found: 'react-dom'"

> [uploads architecture diagram]
💡 Diagram detected. Using Vision MCP for analysis...
[Diagram analysis and explanation]
```

**References**:
- [Vision MCP Server - Z.ai Docs](https://docs.z.ai/devpack/mcp/vision-mcp-server)
- [GLM-4.6V Docs](https://docs.z.ai/guides/vlm/glm-4.6v)

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

---

### For API Users (Pay-as-you-go)

> **Note**: Features in this section require Z.ai API key (pay-as-you-go).
> These models are NOT available in GLM Coding Plan subscription.

#### GLM-Image Generation Support ⭐ NEW
**Planned**: Image generation using GLM-Image (launched January 14, 2026).

**Available GLM-Image** (via Z.ai API):

| Model | Features | Pricing |
|-------|----------|---------|
| **glm-image** | Text-to-image, image-to-image, image editing, multiple aspect ratios | $0.015/image |

**Features**:
- Text-to-image generation
- Image-to-image transformation
- Image editing capabilities
- Multiple aspect ratios (1:1, 3:4, 4:3, 16:9, etc.)

**Example**:
```bash
> "Generate a cat image"
💡 Image generation detected. Using GLM-Image API
Generated: cat_image.png (1024x1024)
Cost: $0.015

> [uploads photo] "Change this photo to a seascape"
💡 Image-to-image detected. Using GLM-Image API
Generated: seascape_edit.png
```

**Benefits**:
- Open-source alternative to Midjourney/DALL-E
- Lower cost per image
- Supports both generation and editing

**References**:
- [GLM-Image Docs](https://docs.z.ai/guides/image/glm-image)
- [GLM-Image Blog](https://z.ai/blog/glm-image)

#### GLM-ASR (Speech-to-Text) Support ⭐ NEW
**Planned**: Automatic speech recognition using GLM-ASR-2512.

**Available GLM-ASR** (via Z.ai API):

| Model | Parameters | Features | Pricing |
|-------|------------|----------|---------|
| **glm-asr-2512** | Cloud flagship | Real-time STT, 40+ languages | $0.03/MTok (~$0.0024/min) |
| **glm-asr-nano-2512** | 1.5B | Lightweight edge, dialect support | - |

**Features**:
- Real-time speech-to-text conversion
- Outperforms OpenAI Whisper V3 in benchmarks
- Multi-language, multi-accent support
- Chinese dialect recognition (Cantonese, etc.)
- Low CER in complex environments

**Example**:
```bash
> [uploads audio.mp3]
💡 Speech detected. Using GLM-ASR-2512 API
Transcribed: "Today we discussed the project schedule..."
Language: English (auto-detected)

> [uploads meeting.wav]
💡 Long-form audio detected. Using GLM-ASR-Nano-2512 API
Transcribed: 3,245 characters in 12.3 seconds
```

**Benefits**:
- Open-source alternative to Whisper
- Better performance on Chinese/dialects
- Lower cost than proprietary solutions

**References**:
- [GLM-ASR-2512 Docs](https://docs.z.ai/guides/audio/glm-asr-2512)
- [GLM-ASR GitHub](https://github.com/zai-org/GLM-ASR)

#### GLM-OCR Pipeline Integration ⭐ NEW
**Planned**: Fast text extraction using GLM-OCR (0.9B parameters).

**Available GLM-OCR** (via Z.ai API):

| Model | Parameters | Best For |
|-------|------------|----------|
| **glm-ocr** | 0.9B | Fast text extraction from images |

**Features**:
- Automatic OCR detection for image uploads
- PDF/document text extraction
- Screenshot-to-text conversion
- Multilingual OCR support

**Example**:
```bash
> [uploads PDF document]
💡 Document detected. Running GLM-OCR API for text extraction...
Extracted 3,245 characters in 2.1 seconds

> [uploads screenshot with error message]
💡 Screenshot detected. Using GLM-OCR API to extract error text...
Error: Module not found: 'react-dom'
```

**Benefits**:
- 80% faster than full multimodal models for pure OCR
- Cost-effective for batch document processing
- State-of-the-art OCR performance

**References**:
- [GLM-OCR Docs](https://docs.z.ai/guides/vlm/glm-ocr)

#### GLM Agent Integration ⭐ NEW
**Planned**: Native support for GLM's specialized agents.

**Available GLM Agents** (via Z.ai API):

| Agent | Features | Use Case |
|-------|----------|----------|
| **Slide/Poster Agent** (beta) | Creates slides/posters, web image integration | Presentations, marketing |
| **Translation Agent** | 40 languages, Classical Chinese, Cantonese | Multilingual content |
| **Video Effect Template Agent** | Image-to-video, special effects | Video content creation |

**Features**:
- Agent switching with `/agent` command
- Web image search and integration
- One-click content generation

**Example**:
```bash
> "Create presentation slides about AI technology"
💡 Using Slide/Poster Agent API
Generated: presentation.pptx (12 slides)

> "Translate this document from Korean to English"
💡 Using Translation Agent API
Translated: document_en.pdf (40 languages supported)

> [uploads photo] "Create video effects from this photo"
💡 Using Video Effect Template Agent API
Generated: video_effect.mp4
```

**References**:
- [Slide/Poster Agent Docs](https://docs.z.ai/guides/agents/slide)
- [Translation Agent Docs](https://docs.z.ai/guides/agents/translation)
- [Video Effect Template Agent Docs](https://docs.z.ai/guides/agents/video-template)

#### Extended Model Access (API Only)
**Planned**: Access to additional models available only via API key.

**Available Models** (API Only):

| Series | Models | Context | Best For |
|--------|--------|---------|----------|
| **GLM-4.7** | glm-4.7-flashx, glm-4.7-flash | 200K+ | Fast responses |
| **GLM-4.5** | glm-4.5v | 128K | Cost-effective vision |
| **GLM-4 32B** | glm-4-32b-0414-128k | 128K | Efficient, tool calling |
| **Vision** | glm-4.1v-thinking | 128K | Advanced vision reasoning |
| **Open Source** | glm-4-9b, glm-4-9b-chat, glm-4-9b-chat-1m | Up to 1M | Local deployment |

**References**:
- [GLM-4.7 Official Docs](https://docs.z.ai/guides/llm/glm-4.7)
- [GLM-4-32B-0414 Docs](https://docs.z.ai/guides/llm/glm-4-32b-0414-128k)
- [Zhipu AI Model Center](https://open.bigmodel.cn/dev/howuse/model)

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

---

## 2026 Industry Trends & Competitive Analysis

### AI CLI Tools Landscape (2026)

Based on market analysis of leading AI CLI tools:

| Tool | Type | Key Features | Cost vs Cursor | Differentiation |
|------|------|--------------|----------------|----------------|
| **Claudish** | Proxy | 580+ models via OpenRouter, multi-provider | Variable | Multi-model generalist |
| **Aider** | CLI | Repository indexing, dependency tracking | 40-60% lower | Git-focused workflows |
| **Cursor** | IDE | Native AI integration, multi-file editing | Baseline | IDE-first experience |
| **Continue** | IDE Extension | Open source, cross-platform | Free | IDE-agnostic |
| **Claude Code** | CLI | MCP integration, agent orchestration | Official | Anthropic ecosystem |
| **claude-by-glm** | Wrapper | 4+ GLM subscription models + Vision MCP, secure keychain | 85-95% lower | GLM subscription specialist |

**Sources**:
- [Claudish - Multi-model proxy for Claude](https://github.com/MadAppGang/claudish)
- [Claude Code vs Cursor vs Aider](https://brlikhon.engineer/blog/claude-code-vs-cursor-vs-aider-the-terminal-ai-coding-battle-of-2026-complete-performance-cost-breakdown-)
- [Best AI Tools for Coding 2026](https://dev.to/lightningdev123/best-ai-tools-for-coding-in-2026-a-practical-guide-for-modern-developers-22hk)
- [AI Coding Agents 2026](https://www.faros.ai/blog/best-ai-coding-agents-2026)

**Our Differentiation**: While Claudish provides access to 580+ models across multiple providers (OpenRouter, Anthropic, OpenAI, etc.), claude-by-glm focuses on being a **GLM Subscription Specialist**:
- Deep integration with Z.ai GLM Coding Plan (4+ models: GLM-4.7, 4.6, 4.5, 4.5-Air)
- Vision MCP support: GLM-4.6V for screenshot analysis, OCR, diagrams
- Secure credential storage (keychain, not environment variables)
- Platform-specific optimizations (macOS, Linux, Windows)
- Session isolation for GLM settings
- Cost-effective GLM subscription workflows (85-95% lower than Cursor)

> **Note**: API users (pay-as-you-go) get access to 15+ models including GLM-Image, GLM-ASR, GLM-OCR, and specialized agents. See "For API Users" section below.

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
| GLM-4-32B-0414 | Apr 2025 | Efficient 32B with tool calling | 128K |
| GLM-4.6 | Sep 2025 | +15% token efficiency, agents | 128K-200K |
| GLM-4.6V | Nov 2025 | Multimodal with function calling | 128K |
| GLM-4.7 | Dec 2025 | +5.8% multilingual coding | 200K in / 128K out |
| GLM-4.7-Flash | Jan 2026 | 30B lightweight model | Same as 4.7 |
| GLM-Image | Jan 2026 | Text-to-image, image editing | - |
| GLM-ASR-2512 | Dec 2025 | Outperforms Whisper V3 | - |

### GLM Model Categories

#### Subscription Models (GLM Coding Plan)

| Category | Models | Use Case |
|----------|--------|----------|
| **LLM (Chat)** | glm-4.7, glm-4.6, glm-4.5 | General chat, coding, reasoning |
| **Flash (Fast)** | glm-4.5-air | Quick responses, cost-effective |
| **Vision/Multimodal** | glm-4.6v (via MCP) | Screenshot analysis, diagrams, OCR |

#### API-Only Models (Pay-as-you-go)

| Category | Models | Use Case |
|----------|--------|----------|
| **LLM (Chat)** | glm-4-32b-0414-128k | Efficient, tool calling |
| **Flash (Fast)** | glm-4.7-flash, glm-4.7-flashx | Quick responses |
| **Vision/Multimodal** | glm-4.5v, glm-4.1v-thinking | Advanced vision reasoning |
| **Image Generation** | glm-image | Text-to-image, image editing |
| **OCR** | glm-ocr (0.9B) | Fast text extraction |
| **ASR (Speech)** | glm-asr-2512, glm-asr-nano-2512 (1.5B) | Speech-to-text, transcription |
| **Long Context** | glm-4-9b-chat-1m | Up to 1M context |
| **Open Source** | glm-4-9b, glm-4-9b-chat | Local deployment |

**Sources**:
- [GLM-4.7 Official Docs](https://docs.z.ai/guides/llm/glm-4.7)
- [GLM-4-32B-0414 Docs](https://docs.z.ai/guides/llm/glm-4-32b-0414-128k)
- [GLM-4.6V Docs](https://docs.z.ai/guides/vlm/glm-4.6v)
- [GLM-Image Docs](https://docs.z.ai/guides/image/glm-image)
- [GLM-ASR-2512 Docs](https://docs.z.ai/guides/audio/glm-asr-2512)
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

The following features were removed from the roadmap to avoid duplicating existing tools:

| Feature | Removed | Reason | Alternative |
|---------|---------|--------|-------------|
| **MCP Server Mode** | v1.7.1 | Claudish already provides multi-model proxy (580+ models) | [Claudish](https://github.com/MadAppGang/claudish) |
| **Repository Indexing** | v1.7.1 | Aider already has superior repository indexing | [Aider](https://github.com/paul-gauthier/aider) |
| **Task Management** | v1.7.1 | Claude Code has built-in task tracking with dependencies | Claude Code native |
| **Session Profiles** | v1.7.1 | User feedback indicated low priority | Environment-specific configs |
| **LSP Integration** | v1.7.1 | Claude Code V3 already has LSP support | Claude Code native |
| **MCP Tool Optimization** | v1.7.1 | Claude Code core development responsibility | Claude Code native |

**Differentiation Strategy**: "GLM Specialist" vs "Multi-Model Generalist"
- Focus on GLM-specific features (10+ models, smart suggestions, cost optimization)
- Leverage existing Claude Code capabilities instead of duplicating
- Provide secure credential storage and platform-specific optimizations

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
