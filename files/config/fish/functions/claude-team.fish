function claude-team --description "Set up a Claude Code team workspace"
    # Step 1: Get team-id (arg or prompt)
    set team_id $argv[1]
    if test -z "$team_id"
        read -P "Team ID: " team_id
    end

    if test -z "$team_id"
        echo "Error: Team ID is required"
        return 1
    end

    set team_dir $CLAUDE_WORKSPACE_DIR/teams/$team_id

    # Step 2: Check if team exists
    if test -d "$team_dir"
        echo "Team '$team_id' already exists at $team_dir"
        read -P "Add more repos? [y/N] " add_more
        if test "$add_more" != "y" -a "$add_more" != "Y"
            cd "$team_dir"
            return 0
        end
    else
        mkdir -p "$team_dir"
    end

    # Step 3: Fetch repos from org and multi-select with fzf
    echo "Fetching repos from $CLAUDE_GITHUB_ORG..."
    set repos (gh repo list $CLAUDE_GITHUB_ORG --limit 100 --json name --jq '.[].name' | fzf --multi --prompt="Select repos (TAB to select, ENTER to confirm): ")

    if test -z "$repos"
        echo "No repos selected"
        cd "$team_dir"
        return 0
    end

    # Step 4: Clone selected repos
    for repo in $repos
        set repo_path "$team_dir/$repo"
        if test -d "$repo_path"
            echo "Repo '$repo' already exists, skipping..."
        else
            echo "Cloning $repo..."
            gh repo clone $CLAUDE_GITHUB_ORG/$repo "$repo_path"
        end
    end

    # Step 5: Enable Claude Code teams feature in settings.json
    set claude_settings ~/.claude/settings.json
    if test -f "$claude_settings"
        # Check if already enabled
        if not grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$claude_settings"
            echo "Enabling Claude Code agent teams..."
            # Use jq to add the env setting
            set tmp_file (mktemp)
            jq '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"' "$claude_settings" > "$tmp_file"
            mv "$tmp_file" "$claude_settings"
        end
    else
        # Create settings.json with teams enabled
        mkdir -p ~/.claude
        echo '{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}' | jq '.' > "$claude_settings"
    end

    # Step 6: Create CLAUDE.md template if it doesn't exist
    set claude_md "$team_dir/CLAUDE.md"
    if not test -f "$claude_md"
        echo "Creating CLAUDE.md template..."
        echo "# Team: $team_id

## Repositories

All repositories are located under this team's current working directory.
" > "$claude_md"
        for repo in $repos
            echo "- $repo" >> "$claude_md"
        end
        echo "
## Rules

- Always run \`mise lint\` in all repositories before committing or creating pull requests
- Before showing the plan, align on API design with the user and ask them to specifically confirm it
- Before showing the plan, align on database schema with the user and ask them to specifically confirm it

## Team Objectives
<!-- Describe the team's goals and what you're trying to accomplish -->

## Context
<!-- Add any relevant context about the project, architecture, or constraints -->

## Notes
<!-- Working notes, decisions made, links to relevant docs -->
" >> "$claude_md"
    end

    # Step 7: cd to team directory
    echo "Team workspace ready at: $team_dir"
    cd "$team_dir"
end
