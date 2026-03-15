function claude-teams --description "List and cd to existing team workspaces"
    set teams_dir $CLAUDE_WORKSPACE_DIR/teams
    if not test -d "$teams_dir"
        echo "No teams directory found"
        return 1
    end

    set team (ls -1 "$teams_dir" | fzf --prompt="Select team: ")
    if test -n "$team"
        cd "$teams_dir/$team"
    end
end
