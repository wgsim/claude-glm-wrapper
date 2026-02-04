# glm-completion.fish - Fish completion for GLM MCP Wrapper commands
#
# Installation:
#   # Copy to fish completions directory:
#   cp ~/.claude-glm-mcp/completion/glm-completion.fish ~/.config/fish/completions/glm-cleanup-sessions.fish
#   cp ~/.claude-glm-mcp/completion/glm-completion.fish ~/.config/fish/completions/glm-update.fish
#
#   # Or symlink:
#   ln -s ~/.claude-glm-mcp/completion/glm-completion.fish ~/.config/fish/completions/glm-cleanup-sessions.fish
#   ln -s ~/.claude-glm-mcp/completion/glm-completion.fish ~/.config/fish/completions/glm-update.fish

# glm-cleanup-sessions completion
complete -c glm-cleanup-sessions -f

complete -c glm-cleanup-sessions -l dry-run -d 'Show what would be deleted without actually deleting'
complete -c glm-cleanup-sessions -l keep -x -d 'Keep the last N sessions' -a "1 5 10 20 50 100"
complete -c glm-cleanup-sessions -l all -d 'Remove all session files'
complete -c glm-cleanup-sessions -l list -d 'List all sessions with details'
complete -c glm-cleanup-sessions -l session -x -d 'Delete specific session(s)' -a "(__fish_print_glm_sessions)"
complete -c glm-cleanup-sessions -s h -l help -d 'Show help message'

# glm-update completion
complete -c glm-update -f

complete -c glm-update -l from -x -d 'Source directory' -a "(__fish_complete_directories)"
complete -c glm-update -l to -x -d 'Installation directory' -a "(__fish_complete_directories)"
complete -c glm-update -l force -d 'Force update even if versions match'
complete -c glm-update -l dry-run -d 'Show what would be updated without actually updating'
complete -c glm-update -s h -l help -d 'Show help message'

# Helper function to get GLM sessions
function __fish_print_glm_sessions
    set -l sessions_dir "$HOME/.claude/glm-sessions"
    if test -d "$sessions_dir"
        ls -1 "$sessions_dir" 2>/dev/null | grep -v '^\.' | sed 's/\.json$//'
    end
end
