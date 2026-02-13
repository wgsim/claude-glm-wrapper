# Contributing to GLM MCP Wrapper

Thank you for your interest in contributing! This project helps developers use Z.ai GLM models with Claude Code securely.

## 🚀 Quick Start

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/claude-glm-wrapper.git`
3. **Create a branch**: `git checkout -b feature/your-feature-name`
4. **Make changes** and test thoroughly
5. **Commit**: `git commit -m "feat: your feature description"`
6. **Push**: `git push origin feature/your-feature-name`
7. **Open a Pull Request**

## 🔒 Security First

This project handles API credentials - security is paramount:

### Before Submitting

✅ **Run security scan**:
```bash
./scripts/security-scan.sh --full
```

✅ **Pre-commit hook** runs automatically and will:
- Show your changes (`git diff --cached`)
- Scan for secrets with gitleaks
- Validate file permissions
- Block commits with detected secrets

✅ **Never commit**:
- API keys, tokens, passwords
- Real credentials (even for testing)
- `.env` files or secrets
- Session files or backups

See `docs/security-automation.md` for details.

## 📝 Code Standards

### Shell Scripts

- ✅ Use `set -euo pipefail` at the top
- ✅ Add comprehensive error checking (see existing scripts)
- ✅ Follow CLAUDE.md guidelines (no `rm` command, use trash)
- ✅ Test on multiple platforms (macOS, Linux if possible)
- ✅ Make scripts executable: `chmod +x script.sh`

### File Permissions

Security-sensitive files should have restrictive permissions:
- Scripts: `500` (owner execute only)
- Credentials: `600` (owner read/write only)

### Error Handling

Always provide clear, actionable error messages:
```bash
if ! some_command; then
    print_error "Failed to do X"
    print_info "Try: solution here"
    exit 1
fi
```

## 🧪 Testing

### Required Tests

Before submitting a PR:

1. **Manual Testing**:
   ```bash
   # Clean install
   ./scripts/install.sh

   # Test all platforms you can access
   # macOS, Linux, Windows (if possible)

   # Verify functionality
   claude-by-glm --glm-version
   ```

2. **Security Scan**:
   ```bash
   ./scripts/security-scan.sh --full
   # Should show: ✅ No leaks found
   ```

3. **Update Test** (for installer/updater changes):
   ```bash
   ./bin/glm-update --dry-run
   ```

### Test Checklist

- [ ] Fresh install works
- [ ] Update from previous version works
- [ ] Security scan passes
- [ ] No secrets in commits
- [ ] Scripts have correct permissions
- [ ] Error messages are helpful
- [ ] Works on target platforms

## 📚 Documentation

Update documentation when you:
- Add new features → Update README.md, relevant docs/
- Change behavior → Update TROUBLESHOOTING.md
- Add security controls → Update docs/security-*.md
- Change installation → Update INSTALL.md

## 🎯 Commit Message Format

Follow conventional commits:

```
type(scope): brief description

Longer description if needed

Co-Authored-By: Your Name <your@email.com>
```

**Types**:
- `feat:` - New feature
- `fix:` - Bug fix
- `security:` - Security improvement
- `docs:` - Documentation only
- `refactor:` - Code restructuring
- `test:` - Adding tests
- `chore:` - Maintenance

**Examples**:
```
feat(installer): Add support for Ubuntu 24.04

fix(security): Prevent API key exposure in error logs

security: Add gitleaks scanning to pre-commit hook

docs: Update macOS keychain troubleshooting guide
```

## 🐛 Reporting Issues

### Bug Reports

Include:
- **Environment**: OS, version, shell
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Logs/error messages** (with secrets redacted!)

### Security Vulnerabilities

**DO NOT** open public issues for security vulnerabilities.

See [SECURITY.md](SECURITY.md) for responsible disclosure.

## 💡 Feature Requests

Before requesting a feature:
1. Check existing issues
2. Check [ROADMAP.md](ROADMAP.md)
3. Explain the use case, not just the solution

## 🔄 Pull Request Process

1. **Ensure PR**:
   - ✅ Passes all pre-commit checks
   - ✅ Updates relevant documentation
   - ✅ Includes clear description
   - ✅ References related issues

2. **PR will be reviewed for**:
   - Code quality and standards
   - Security implications
   - Platform compatibility
   - Documentation completeness

3. **After approval**:
   - Maintainer will merge
   - Credit will be given in commit message

## 📋 Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/claude-glm-wrapper.git
cd claude-glm-wrapper

# Install gitleaks (for security scanning)
brew install gitleaks  # macOS
# or download from https://github.com/gitleaks/gitleaks

# Set up pre-commit hook (automatic)
# Already in .git/hooks/pre-commit

# Test install (in a safe environment)
./scripts/install.sh
```

## 🙏 Code of Conduct

Be respectful, inclusive, and constructive. We're all here to build better tools.

## 📞 Questions?

- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Open a discussion (not an issue) for questions
- Review existing issues and PRs

## 🎉 Thank You!

Your contributions help developers use GLM models securely. Every improvement matters!

---

**License**: By contributing, you agree your contributions will be licensed under the MIT License.
