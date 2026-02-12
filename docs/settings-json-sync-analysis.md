# settings.json Sync Analysis

## Problem

GLM sessions and official Claude Code sessions share `~/.claude/settings.json`, causing model configuration to leak between sessions. When a user changes the model in the official Claude UI, the change propagates to GLM sessions (and vice versa).

## Evidence (from glm-watch-settings logs)

- `settings.json` is written by Claude Code on every model change via `/model` command or UI
- The `"model"` key in `settings.json` is the primary sync vector
- `CLAUDE_SETTINGS` env var (session-level settings file) only overrides at load time; Claude Code still writes back to the shared `settings.json`
- `.claude.json` (`projects.*.lastModelUsage`) also reflects model state but is read-only from the session perspective

### Timeline of observed sync events

1. GLM session starts, reads `settings.json` with `"model": "opus"`
2. User opens official Claude Code in another terminal
3. Official session writes `"model": "sonnet"` to `settings.json`
4. GLM session picks up the change on next settings reload

## Root Cause

`~/.claude/settings.json` is a **shared global config** file. Both GLM and official Claude Code sessions read and write to it. The `CLAUDE_SETTINGS` mechanism provides per-session overrides but does not prevent Claude Code from also writing to the global file.

## Solution: CLAUDE_CONFIG_DIR Separation (v2.0.0)

Setting `CLAUDE_CONFIG_DIR=~/.claude-glm` gives GLM sessions a completely separate config directory. This means:

- GLM reads/writes `~/.claude-glm/settings.json` (isolated copy)
- Official Claude reads/writes `~/.claude/settings.json` (unaffected)
- Shared resources (plugins, commands, projects, CLAUDE.md) are symlinked

### Directory Structure

```
~/.claude-glm/
├── settings.json        <- copied (GLM-specific, isolated)
├── settings.local.json  <- copied (GLM-specific, isolated)
├── plugins/             <- symlink -> ~/.claude/plugins/
├── commands/            <- symlink -> ~/.claude/commands/
├── projects/            <- symlink -> ~/.claude/projects/
├── todos/               <- symlink -> ~/.claude/todos/
├── statsig/             <- symlink -> ~/.claude/statsig/
├── CLAUDE.md            <- symlink -> ~/.claude/CLAUDE.md
└── glm-sessions/        <- real directory (GLM session files)
```

### Defense in Depth

The existing `CLAUDE_SETTINGS` session isolation is retained as a secondary layer. Even if `CLAUDE_CONFIG_DIR` were bypassed, per-session settings files still prevent cross-contamination within GLM sessions.

## Validation

1. `ls -la ~/.claude-glm/` - verify symlinks and settings copies
2. `env | grep CLAUDE_CONFIG_DIR` inside a `claude-by-glm` session
3. Change model in official `claude` -> verify no effect on GLM session
4. `glm-watch-settings --report` should show no more cross-session model changes
