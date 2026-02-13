# Public Release Checklist

**Status**: 🟡 In Progress
**Target**: Make repository public on GitHub

## ✅ Pre-Release Security Review

- [x] **Full security scan completed** (gitleaks)
  - 45 commits scanned
  - 224 KB analyzed
  - 0 secrets found
- [x] **Pre-commit hooks active**
- [x] **.gitignore comprehensive** (140+ patterns)
- [x] **External security review** (Gemini, ChatGPT/Codex) - 12 issues found & fixed
- [x] **Manual code review** for sensitive patterns - All fixes verified

## ✅ Legal & Licensing

- [x] **LICENSE file** created (MIT)
- [x] **Copyright holder** set (wgsim)
- [x] **LICENSE referenced** in README.md
- [ ] **Review all dependencies** for license compatibility

## ✅ Documentation

- [x] **README.md** updated
  - [x] License badge added
  - [x] Version badge added
  - [x] Contributing section
  - [x] License section
- [x] **CONTRIBUTING.md** created
- [x] **CODE_OF_CONDUCT.md** created
- [x] **SECURITY.md** exists
- [x] **Installation guide** complete (INSTALL.md)
- [x] **Troubleshooting guide** complete (TROUBLESHOOTING.md)
- [ ] **API documentation** review

## ✅ Repository Setup

- [ ] **Repository description** set
- [ ] **Repository topics** added
- [ ] **GitHub Pages** (optional)
- [ ] **Issue templates** created
- [ ] **PR template** created
- [ ] **Branch protection** rules
- [ ] **Required status checks**

## ✅ Code Quality

- [x] **Security automation** in place
  - [x] Pre-commit hooks
  - [x] Periodic scanning script
  - [x] Gitleaks configuration
- [x] **Error handling** comprehensive
- [x] **File permissions** correct (500/600)
- [x] **No hardcoded secrets**
- [ ] **Code review** complete

## ✅ Privacy & Sensitive Data

- [x] **No API keys** in code or history
- [x] **No personal information** in commits
- [x] **No private paths** exposed
- [ ] **Email addresses** reviewed
- [ ] **User data** references checked

## ✅ Testing

- [ ] **Fresh install** tested
- [ ] **Update process** tested
- [ ] **Multi-platform** testing
  - [ ] macOS
  - [ ] Linux
  - [ ] Windows (if supported)
- [ ] **Security scenarios** tested
  - [ ] API key protection
  - [ ] Keychain access
  - [ ] MCP enable/disable

## 🔧 GitHub Repository Settings

When ready to make public:

### 1. Repository Settings
```
Settings → General
- Visibility: Public
- Features: Enable Issues, Discussions
- Branch protection: main branch
```

### 2. Description & Topics
```
Description:
"Secure wrapper to use Z.ai GLM models (GLM 5, 4.7, 4.6) with Claude Code - credential protection, session isolation, automated secret scanning"

Topics:
claude-code, glm, z-ai, anthropic, api-wrapper,
security, credential-management, mcp, developer-tools
```

### 3. About Section
```
- Website: (if you have docs site)
- Topics: (see above)
- Include in the home page: ✓
```

### 4. Branch Protection (main)
```
Settings → Branches → Add rule
- Branch name pattern: main
- Require pull request reviews: ✓
- Require status checks to pass: ✓
```

### 5. Security
```
Settings → Security
- Enable Dependabot alerts: ✓
- Enable Dependabot security updates: ✓
- Private vulnerability reporting: ✓
```

## 📋 Pre-Publication Review

**Manual checks before going public:**

1. **Search for usernames/emails**:
   ```bash
   git log --all --pretty=format:"%an <%ae>" | sort -u
   ```

2. **Search for private paths**:
   ```bash
   git grep -i "/Users/" | grep -v ".claude-glm-mcp"
   ```

3. **Search for sensitive terms**:
   ```bash
   git grep -i -E "(password|secret|token|key)" | grep -v -E "(install-key|api-key|keychain)"
   ```

4. **Review commit messages**:
   ```bash
   git log --oneline --all | less
   ```

## 🚀 Publication Steps

1. **Complete this checklist**
2. **Get external security review** ✓
3. **Tag release**: `git tag v2.0.0`
4. **Push tags**: `git push origin v2.0.0`
5. **Create GitHub Release** with changelog
6. **Change visibility** to Public
7. **Announce** (if desired)

## 📊 Post-Publication

- [ ] Monitor issues for security concerns
- [ ] Respond to first issues/PRs promptly
- [ ] Update documentation based on feedback
- [ ] Consider setting up CI/CD for automated testing

## 🔐 Rollback Plan

If security issue found after going public:

1. **Make repo private immediately**
2. **Rotate any exposed credentials**
3. **Fix the issue**
4. **Security scan again**
5. **Re-publish when safe**

---

**Last Updated**: 2026-02-12
**Prepared By**: Claude Code Assistant
