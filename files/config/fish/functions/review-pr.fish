function review-pr --description "Set up a PR review worktree and start Claude code review"
    # Parse auth flags
    set -l auth_mode $CLAUDE_AUTH_MODE
    set -l remaining_args
    for arg in $argv
        switch $arg
            case --aws
                set auth_mode aws
            case --sso
                set auth_mode sso
            case '*'
                set -a remaining_args $arg
        end
    end
    set argv $remaining_args

    # Parse arguments
    set -l pr_input $argv[1]

    if test -z "$pr_input"
        echo "Usage: review-pr <pr-number|org/repo#number|github-url>"
        echo ""
        echo "Examples:"
        echo "  review-pr 123                           # PR in current repo"
        echo "  review-pr org/repo#123                  # PR in specific repo"
        echo "  review-pr https://github.com/org/repo/pull/123"
        echo "  review-pr --feedback                    # Improve the skill from session feedback"
        return 1
    end

    # Handle --feedback flag
    if test "$pr_input" = "--feedback"
        set -l skill_path "$HOME/Code/Own/devsible/roles/dotfiles/files/config/claude/skills/code-reviewer"

        if not test -d "$skill_path"
            echo "Error: Skill source not found at $skill_path"
            return 1
        end

        # Find session feedback files, filtering out already-used ones (.feedback-used tombstone)
        echo "Select session feedback files to use (TAB to multi-select, ENTER to confirm):"
        set -l feedback_files (fd --hidden --full-path '\.review/[^/]+\.[mM][dD]$' ~/Code/reviews 2>/dev/null | while read -l f
            set -l review_dir (dirname "$f")
            if not test -f "$review_dir/.feedback-used"
                echo "$f"
            end
        end | fzf --multi --preview 'head -50 {}')

        if test -z "$feedback_files"
            echo "No feedback files selected. Starting without session context."
        else
            echo "Selected "(count $feedback_files)" feedback file(s)"
        end

        cd "$skill_path"
        echo ""
        echo "Entering code-reviewer skill feedback mode..."
        echo "Skill location: $skill_path"
        echo ""

        # Build prompt with selected files
        if test -n "$feedback_files"
            set -l files_list (string join ", " $feedback_files)
            claude "I want to improve the code-reviewer skill based on session feedback.

Read SKILL.md first to understand the current skill.

Then read these session feedback files for context on what worked and what needs improvement:
$files_list

Based on the feedback, propose specific edits to SKILL.md. Ask me questions if you need clarification on any feedback points."
        else
            claude "I want to give feedback on the code-reviewer skill. Read SKILL.md and help me improve it based on my experience using it. Ask what's not working well or what I'd like to change."
        end

        # Mark selected feedback as used
        if test -n "$feedback_files"
            for f in $feedback_files
                touch (dirname "$f")/.feedback-used
            end
        end
        return 0
    end

    # Variables to populate
    set -l org ""
    set -l repo ""
    set -l pr_number ""
    set -l repo_path ""

    # Parse different input formats
    if string match -rq '^https?://github\.com/([^/]+)/([^/]+)/pull/(\d+)' -- "$pr_input"
        # GitHub URL format
        set org (string match -r '^https?://github\.com/([^/]+)/([^/]+)/pull/(\d+)' -- "$pr_input")[2]
        set repo (string match -r '^https?://github\.com/([^/]+)/([^/]+)/pull/(\d+)' -- "$pr_input")[3]
        set pr_number (string match -r '^https?://github\.com/([^/]+)/([^/]+)/pull/(\d+)' -- "$pr_input")[4]

        # Search for repo in ~/Code by matching git remote
        set -l target_url "github.com/$org/$repo"
        for git_dir in (fd --glob -H -t d '**/.git' ~/Code -d 5 --min-depth 2 --no-ignore --exec dirname {})
            set -l remote_url (git -C "$git_dir" remote get-url origin 2>/dev/null)
            if string match -q "*$target_url*" -- "$remote_url"
                set repo_path "$git_dir"
                break
            end
        end

        if test -z "$repo_path"
            echo "Error: Could not find local clone of $org/$repo in ~/Code"
            echo "Clone the repo first: gh repo clone $org/$repo"
            return 1
        end

    else if string match -rq '^([^/]+)/([^#]+)#(\d+)$' -- "$pr_input"
        # org/repo#number format
        set org (string match -r '^([^/]+)/([^#]+)#(\d+)$' -- "$pr_input")[2]
        set repo (string match -r '^([^/]+)/([^#]+)#(\d+)$' -- "$pr_input")[3]
        set pr_number (string match -r '^([^/]+)/([^#]+)#(\d+)$' -- "$pr_input")[4]

        # Search for repo in ~/Code
        set -l target_url "github.com/$org/$repo"
        for git_dir in (fd --glob -H -t d '**/.git' ~/Code -d 5 --min-depth 2 --no-ignore --exec dirname {})
            set -l remote_url (git -C "$git_dir" remote get-url origin 2>/dev/null)
            if string match -q "*$target_url*" -- "$remote_url"
                set repo_path "$git_dir"
                break
            end
        end

        if test -z "$repo_path"
            echo "Error: Could not find local clone of $org/$repo in ~/Code"
            return 1
        end

    else if string match -rq '^\d+$' -- "$pr_input"
        # Just a PR number - use current directory
        set pr_number "$pr_input"

        # Must be in a git repo
        if not git rev-parse --git-dir >/dev/null 2>&1
            echo "Error: Not in a git repository. Provide full repo path or run from within a repo."
            return 1
        end

        set repo_path (git rev-parse --show-toplevel)

        # Extract org/repo from remote
        set -l remote_url (git -C "$repo_path" remote get-url origin 2>/dev/null)
        if string match -rq 'github\.com[:/]([^/]+)/([^/\.]+)' -- "$remote_url"
            set org (string match -r 'github\.com[:/]([^/]+)/([^/\.]+)' -- "$remote_url")[2]
            set repo (string match -r 'github\.com[:/]([^/]+)/([^/\.]+)' -- "$remote_url")[3]
        else
            echo "Error: Could not parse org/repo from remote: $remote_url"
            return 1
        end
    else
        echo "Error: Unrecognized format: $pr_input"
        echo "Expected: PR number, org/repo#number, or GitHub URL"
        return 1
    end

    # Create worktree path
    set -l worktree_path "$HOME/Code/reviews/$org/$repo/pr-$pr_number"

    # Check if worktree already exists
    if test -d "$worktree_path"
        echo "Worktree already exists at: $worktree_path"
        read -l -P "Continue with existing worktree? [Y/n] " confirm
        if test "$confirm" = "n" -o "$confirm" = "N"
            echo "Aborting. Remove the worktree manually if needed:"
            echo "  rm -rf $worktree_path"
            echo "  git -C $repo_path worktree prune"
            return 1
        end
    else
        # Fetch PR and create worktree
        echo "Fetching PR #$pr_number from $org/$repo..."

        # Fetch the PR ref
        git -C "$repo_path" fetch origin "pull/$pr_number/head:pr-$pr_number" 2>/dev/null
        or begin
            echo "Error: Could not fetch PR #$pr_number"
            return 1
        end

        # Create parent directories
        mkdir -p (dirname "$worktree_path")

        # Create worktree
        git -C "$repo_path" worktree add "$worktree_path" "pr-$pr_number"
        or begin
            echo "Error: Could not create worktree"
            return 1
        end
    end

    # Create .review directory and fetch PR metadata
    set -l review_dir "$worktree_path/.review"
    mkdir -p "$review_dir"

    echo "Fetching PR metadata..."
    gh pr view "$pr_number" --repo "$org/$repo" --json title,body,baseRefName,headRefName,commits,files,url,author,labels,reviewDecision > "$review_dir/pr-meta.json"
    or begin
        echo "Warning: Could not fetch PR metadata. Continuing without it."
    end

    echo "Fetching PR diff..."
    gh pr diff "$pr_number" --repo "$org/$repo" > "$review_dir/pr-diff.patch"
    or begin
        echo "Warning: Could not fetch PR diff. Continuing without it."
    end

    # Change to worktree directory
    cd "$worktree_path"

    # Auto-trust mise if config exists
    if test -f mise.toml -o -f .mise.toml -o -f .mise.local.toml
        echo "Found mise config, trusting directory..."
        mise trust --yes 2>/dev/null
    end

    echo ""
    echo "Review environment ready:"
    echo "  Worktree: $worktree_path"
    echo "  PR: $org/$repo#$pr_number"
    echo "  Metadata: .review/pr-meta.json"
    echo "  Diff: .review/pr-diff.patch"
    echo ""
    echo "Starting Claude with code-reviewer skill..."
    echo ""

    # Set auth environment
    if test "$auth_mode" = "aws"
        # Validate AWS credentials
        if not aws sts get-caller-identity &>/dev/null
            echo "Warning: AWS credentials may be invalid or expired"
            echo "Run: aws sso login --profile dev"
        end
        set -gx CLAUDE_CODE_USE_BEDROCK 1
    else
        set -e CLAUDE_CODE_USE_BEDROCK
    end

    # Start Claude with the code-reviewer skill context
    claude "/code-reviewer Review PR #$pr_number. Read .review/pr-meta.json for context."
end
