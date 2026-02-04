# glm-completion.bash - Bash completion for GLM MCP Wrapper commands
#
# Installation:
#   source ~/.claude-glm-mcp/completion/glm-completion.bash
#
# Or add to ~/.bashrc or ~/.bash_profile:
#   source ~/.claude-glm-mcp/completion/glm-completion.bash

_glm_completion() {
    local cur prev words cword
    _init_completion || return

    local commands="glm-cleanup-sessions glm-update claude-by-glm install-key.sh"

    # If completing the command itself
    if [[ ${cword} -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return 0
    fi

    # Get the command
    local cmd="${words[1]}"

    case "$cmd" in
        glm-cleanup-sessions)
            _glm_cleanup_sessions_completion
            ;;
        glm-update)
            _glm_update_completion
            ;;
        claude-by-glm)
            # claude-by-glm passes through to claude, no specific completion
            COMPREPLY=()
            ;;
        install-key.sh)
            # install-key.sh has no options
            COMPREPLY=()
            ;;
    esac
}

_glm_cleanup_sessions_completion() {
    local opts="--dry-run --keep --all --list --session --help -h"

    # If previous word is --keep, complete with numbers
    if [[ "${prev}" == "--keep" ]]; then
        COMPREPLY=($(compgen -W "{1..100}" -- "$cur"))
        return 0
    fi

    # If previous word is --session, complete with session IDs
    if [[ "${prev}" == "--session" ]]; then
        local sessions_dir="$HOME/.claude/glm-sessions"
        if [[ -d "$sessions_dir" ]]; then
            local sessions=($(ls -1 "$sessions_dir" 2>/dev/null | grep -v '^\.' | sed 's/\.json$//'))
            COMPREPLY=($(compgen -W "${sessions[*]}" -- "$cur"))
        fi
        return 0
    fi

    # Otherwise complete with options
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

_glm_update_completion() {
    local opts="--from --to --force --dry-run --help -h"

    # If previous word is --from or --to, complete with directories
    if [[ "${prev}" == "--from" ]] || [[ "${prev}" == "--to" ]]; then
        COMPREPLY=($(compgen -d -- "$cur"))
        return 0
    fi

    # Otherwise complete with options
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

complete -F _glm_completion glm-cleanup-sessions glm-update claude-by-glm install-key.sh
