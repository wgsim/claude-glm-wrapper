#glm-completion.zsh - Zsh completion for GLM MCP Wrapper commands
#
# Installation:
#   # Add to ~/.zshrc:
#   source ~/.claude-glm-mcp/completion/glm-completion.zsh
#
#   # Or copy to zsh completion directory:
#   cp ~/.claude-glm-mcp/completion/glm-completion.zsh ~/.zsh/completion/_glm
#   # Then add to ~/.zshrc:
#   fpath=(~/.zsh/completion $fpath)
#   autoload -U compinit && compinit

#compdef glm-cleanup-sessions glm-update claude-by-glm install-key.sh

_glm() {
    local -a commands

    commands=(
        'glm-cleanup-sessions:Clean up old GLM session settings'
        'glm-update:Update GLM MCP Wrapper installation'
        'claude-by-glm:Claude Code launcher for GLM models'
        'install-key.sh:Register Z.ai API key'
    )

    if (( CURRENT == 2 )); then
        _describe -t commands 'GLM commands' commands
    else
        local cmd="${words[2]}"

        case "$cmd" in
            glm-cleanup-sessions)
                _glm_cleanup_sessions
                ;;
            glm-update)
                _glm_update
                ;;
            claude-by-glm)
                # No specific completion for claude-by-glm
                _message 'passing through to Claude Code'
                ;;
            install-key.sh)
                # No options for install-key.sh
                _message 'no options'
                ;;
        esac
    fi
}

_glm_cleanup_sessions() {
    local -a sessions

    # Get session IDs for --session completion
    local sessions_dir="$HOME/.claude/glm-sessions"
    if [[ -d "$sessions_dir" ]]; then
        sessions=($(ls -1 "$sessions_dir" 2>/dev/null | grep -v '^\.' | sed 's/\.json$//'))
    fi

    _arguments -C \
        '--dry-run[Show what would be deleted without actually deleting]' \
        '--keep[Keep the last N sessions]:number:(1 5 10 20 50 100)' \
        '--all[Remove all session files]' \
        '--list[List all sessions with details]' \
        '--session[Delete specific session(s)]:session:(${sessions})' \
        '*'{-h,--help}'[Show help message]'
}

_glm_update() {
    _arguments -C \
        '--from[Source directory]:directory:_directories' \
        '--to[Installation directory]:directory:_directories' \
        '--force[Force update even if versions match]' \
        '--dry-run[Show what would be updated without actually updating]' \
        '*'{-h,--help}'[Show help message]'
}

_glm "$@"
