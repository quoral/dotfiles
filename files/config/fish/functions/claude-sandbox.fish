function claude-sandbox --description "Create sandboxed Claude Code agent environment"
    set dockerfile_dir ~/.config/docker/claude-sandbox
    set image_name claude-sandbox:latest

    # Parse auth flag (check early to allow combination with other flags)
    set -l auth_mode $CLAUDE_AUTH_MODE
    if contains -- --aws $argv
        set auth_mode aws
        set argv (string match -v -- --aws $argv)
    else if contains -- --sso $argv
        set auth_mode sso
        set argv (string match -v -- --sso $argv)
    end

    # Check for --rebuild flag
    if test "$argv[1]" = "--rebuild"
        echo "Rebuilding claude-sandbox image..."
        docker rmi $image_name 2>/dev/null
        if not docker build --platform linux/arm64 -t $image_name $dockerfile_dir
            echo "Error: Failed to build docker image"
            return 1
        end
        echo "Image rebuilt successfully"
        return 0
    end

    # Handle --feedback flag
    if test "$argv[1]" = "--feedback"
        set sandbox_base ~/Code/Freda/sandbox

        if not test -d "$sandbox_base"
            echo "No sandboxes directory found"
            return 1
        end

        # Find all session feedback files
        set feedback_files (fd --hidden --full-path '\.sandbox/session-feedback\.md$' "$sandbox_base" 2>/dev/null | fzf --multi --preview 'head -80 {}' --prompt="Select feedback files (TAB to multi-select): ")

        if test -z "$feedback_files"
            echo "No feedback files selected."
            return 1
        end

        echo "Selected "(count $feedback_files)" feedback file(s)"

        set files_list (string join "\n- " $feedback_files)
        claude "I want to improve the claude-sandbox tooling based on session feedback.

Read these session feedback files:
- $files_list

Analyze the feedback and identify:
1. Common environment/tooling issues to fix in Docker setup or fish functions
2. Patterns in challenges that could be addressed with better defaults
3. Specific improvements to propose for claude-sandbox.fish or entrypoint.sh

Be specific about which files to modify and what changes to make."
        return 0
    end

    # Check for --resume flag
    if test "$argv[1]" = "--resume" -o "$argv[1]" = "-r"
        set sandbox_base ~/Code/Freda/sandbox
        if not test -d "$sandbox_base"
            echo "No sandboxes directory found"
            return 1
        end

        set sandbox (ls -1 "$sandbox_base" | fzf --prompt="Select sandbox to resume: ")
        if test -z "$sandbox"
            echo "No sandbox selected"
            return 1
        end

        set sandbox_dir "$sandbox_base/$sandbox"
        set extra_args $argv[2..-1]

        # Ensure .sandbox directory exists for resumed sandboxes
        if not test -d "$sandbox_dir/.sandbox"
            mkdir -p "$sandbox_dir/.sandbox"
        end

        # Ensure claude directories exist with proper permissions for container user
        mkdir -p "$sandbox_dir/.sandbox/claude-projects"
        touch "$sandbox_dir/.sandbox/claude-history.jsonl"
        chmod -R 777 "$sandbox_dir/.sandbox/claude-projects" "$sandbox_dir/.sandbox/claude-history.jsonl"
    else
        # Step 1: Get prefix (arg or prompt)
        set prefix $argv[1]
        if test -z "$prefix"
            read -P "Sandbox prefix: " prefix
        end

        if test -z "$prefix"
            echo "Error: Prefix is required"
            return 1
        end

        # Step 2: Generate sandbox name with timestamp and hash
        set timestamp (date +%Y-%m-%d)
        set hash (openssl rand -hex 3)
        set sandbox_name "$prefix-$timestamp-$hash"
        set sandbox_dir ~/Code/Freda/sandbox/$sandbox_name

        # Step 3: Create sandbox directory
        mkdir -p "$sandbox_dir"
        echo "Created sandbox: $sandbox_dir"

        # Create .sandbox directory for metadata and feedback
        mkdir -p "$sandbox_dir/.sandbox"

        # Create claude directories with proper permissions for container user (uid 1000)
        mkdir -p "$sandbox_dir/.sandbox/claude-projects"
        touch "$sandbox_dir/.sandbox/claude-history.jsonl"
        chmod -R 777 "$sandbox_dir/.sandbox/claude-projects" "$sandbox_dir/.sandbox/claude-history.jsonl"

        # Create feedback template
        echo "# Sandbox Session Feedback - $sandbox_name

## Session Summary
- **Sandbox:** $sandbox_name
- **Objective:** <!-- Copy from CLAUDE.md -->
- **Outcome:** <!-- completed/partial/abandoned -->

## What Worked Well
<!-- Effective approaches, tools, or patterns -->

## Challenges Encountered
<!-- Blockers, confusion points, or inefficiencies -->

## Environment Issues
<!-- Sandbox-specific: credentials, dependencies, Docker -->

## Tooling Improvements
<!-- Suggestions for improving claude-sandbox -->
" > "$sandbox_dir/.sandbox/feedback-template.md"

        # Step 4: Select and clone repos (like freda-team)
        echo "Fetching repos from freda-ab..."
        set repos (gh repo list freda-ab --limit 100 --json name --jq '.[].name' | fzf --multi --prompt="Select repos (TAB to select, ENTER to confirm): ")

        if test -n "$repos"
            for repo in $repos
                set repo_path "$sandbox_dir/$repo"
                echo "Cloning $repo..."
                gh repo clone freda-ab/$repo "$repo_path"
            end
        end

        # Step 5: Create CLAUDE.md with feedback instructions
        echo "# Sandbox: $sandbox_name

## Repositories" > "$sandbox_dir/CLAUDE.md"
        for repo in $repos
            echo "- $repo" >> "$sandbox_dir/CLAUDE.md"
        end
        echo "
## Context
<!-- Add context for the autonomous agent -->

## Objective
<!-- Define the task for the agent -->

---

## Session Feedback

Before ending the session, capture learnings in \`.sandbox/session-feedback.md\`:

1. Copy \`.sandbox/feedback-template.md\` to \`.sandbox/session-feedback.md\`
2. Document what worked well
3. Note challenges encountered
4. Flag any environment/tooling issues
5. Suggest improvements

This feedback helps improve future sandbox sessions.
" >> "$sandbox_dir/CLAUDE.md"

        set extra_args $argv[2..-1]
    end

    # Verify GITHUB_SANDBOX_TOKEN
    if test -z "$GITHUB_SANDBOX_TOKEN"
        echo "Warning: GITHUB_SANDBOX_TOKEN not set. GitHub operations will fail."
        echo "Set it with: set -gx GITHUB_SANDBOX_TOKEN <your-fine-grained-pat>"
    end

    # Ensure shared cache directories exist with proper permissions
    mkdir -p ~/Code/Freda/.shared-cache/pnpm
    mkdir -p ~/Code/Freda/.shared-cache/aws
    mkdir -p ~/Code/Freda/.shared-cache/gcloud
    mkdir -p ~/Code/Freda/.shared-cache/claude
    chmod -R 777 ~/Code/Freda/.shared-cache/aws ~/Code/Freda/.shared-cache/gcloud ~/Code/Freda/.shared-cache/claude

    # Only export AWS credentials when in AWS/Bedrock mode
    if test "$auth_mode" = "aws"
        # Ensure AWS credentials are available in shared cache
        set shared_aws ~/Code/Freda/.shared-cache/aws

        # Create minimal config for sandbox (no SSO - use exported credentials instead)
        echo "[profile dev]
region = eu-central-1
output = json" > "$shared_aws/config"

        # Export current SSO credentials to shared cache
        echo "Refreshing AWS credentials for sandbox..."
        if set -l creds (aws configure export-credentials --profile dev --format env 2>/dev/null)
            # Parse exported env vars into credentials file format
            set -l access_key (echo $creds | grep -o 'AWS_ACCESS_KEY_ID=[^[:space:]]*' | cut -d= -f2)
            set -l secret_key (echo $creds | grep -o 'AWS_SECRET_ACCESS_KEY=[^[:space:]]*' | cut -d= -f2)
            set -l session_token (echo $creds | grep -o 'AWS_SESSION_TOKEN=[^[:space:]]*' | cut -d= -f2)

            echo "[dev]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token" > "$shared_aws/credentials"
            chmod 600 "$shared_aws/credentials"
            echo "✓ AWS credentials refreshed"
        else
            echo "⚠️  Could not export AWS credentials. Run: aws sso login --profile dev"
        end
    end

    # Build docker image if needed
    if not docker image inspect $image_name &>/dev/null
        echo "Building claude-sandbox image..."
        if not docker build --platform linux/arm64 -t $image_name $dockerfile_dir
            echo "Error: Failed to build docker image"
            return 1
        end
    end

    # Run container
    echo "Starting sandbox container in $sandbox_dir..."
    docker run -it --rm \
        -v "$sandbox_dir:/workspace" \
        (test "$auth_mode" = "aws"; and echo "-v $HOME/Code/Freda/.shared-cache/aws:/home/sandbox/.aws") \
        -v "$HOME/Code/Freda/.shared-cache/gcloud:/home/sandbox/.config/gcloud" \
        -v "$HOME/.claude:/mnt/claude:ro" \
        -v "$HOME/.gitconfig:/mnt/gitconfig:ro" \
        -v "$HOME/Code/Freda/.shared-cache/pnpm:/home/sandbox/.local/share/pnpm" \
        -v "$HOME/Code/Freda/.shared-cache/claude:/home/sandbox/.claude-cache" \
        -e GITHUB_TOKEN="$GITHUB_SANDBOX_TOKEN" \
        -e CLAUDE_AUTH_MODE="$auth_mode" \
        (test "$auth_mode" = "aws"; and echo "-e AWS_PROFILE=dev -e AWS_REGION=eu-central-1 -e AWS_DEFAULT_REGION=eu-central-1 -e CLAUDE_CODE_USE_BEDROCK=1") \
        -e CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
        $image_name $extra_args
end
