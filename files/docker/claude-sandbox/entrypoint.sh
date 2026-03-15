#!/bin/bash
set -e

# AWS: Use shared cache (mounted directly to ~/.aws) - only in AWS/Bedrock mode
if [ "$CLAUDE_AUTH_MODE" = "aws" ]; then
    if [ -f ~/.aws/credentials ]; then
        echo "✓ AWS credentials available from shared cache"
    else
        echo "⚠️  AWS credentials not found in shared cache."
        echo "   Run on your host machine: claude-creds aws"
        echo ""
    fi
fi

# GCloud: Use shared cache (mounted directly to ~/.config/gcloud)
mkdir -p ~/.config

# Claude: Restore cached SSO auth from shared cache
if [ -f "/home/sandbox/.claude-cache/.claude.json" ]; then
    cp /home/sandbox/.claude-cache/.claude.json ~/.claude.json
    echo "✓ Claude SSO auth restored from cache"
fi

# Save Claude auth back to shared cache on exit
save_claude_auth() {
    if [ -f ~/.claude.json ]; then
        cp ~/.claude.json /home/sandbox/.claude-cache/.claude.json
        echo "✓ Claude auth saved to shared cache"
    fi
}
trap save_claude_auth EXIT

# Claude: Copy settings from host, symlink history to workspace for persistence
mkdir -p ~/.claude
if [ -f "/mnt/claude/settings.json" ]; then
    cp /mnt/claude/settings.json ~/.claude/settings.json
    echo "✓ Claude settings loaded from host"
fi

# Symlink history to workspace - persists across container restarts
touch /workspace/.sandbox/claude-history.jsonl
ln -sf /workspace/.sandbox/claude-history.jsonl ~/.claude/history.jsonl
echo "✓ Claude history linked to workspace"

# Symlink projects directory for session data persistence
mkdir -p /workspace/.sandbox/claude-projects
ln -sf /workspace/.sandbox/claude-projects ~/.claude/projects

# pnpm: Use shared cache (mounted volume shared across all sandboxes)
export PNPM_HOME="/home/sandbox/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Copy gitconfig from host (mounted read-only, we need a writable copy)
if [ -f "/mnt/gitconfig" ]; then
    cp /mnt/gitconfig ~/.gitconfig
    echo "✓ Git config loaded from host"
fi

# Configure git and gh with GitHub token
if [ -n "$GITHUB_TOKEN" ]; then
    git config --global credential.helper store
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
    echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null && echo "✓ GitHub CLI authenticated"
fi


# Check AWS auth - if expired, user must refresh on host (only in AWS mode)
if [ "$CLAUDE_AUTH_MODE" = "aws" ]; then
    if [ -f ~/.aws/credentials ] && ! aws sts get-caller-identity --profile dev &>/dev/null; then
        echo "⚠️  AWS credentials expired or invalid."
        echo "   Run on your host machine: claude-creds aws"
        echo ""
    fi
fi

# Check gcloud auth - run interactive login if not authenticated
if ! gcloud auth print-access-token &>/dev/null 2>&1; then
    echo "GCloud not authenticated. Running auth..."
    gcloud auth login --no-browser
fi

# Run Claude with dangerous mode enabled (safe in sandbox)
# Note: not using exec so the EXIT trap can save Claude auth back to shared cache
if [ $# -eq 0 ]; then
    claude --dangerously-skip-permissions
else
    claude --dangerously-skip-permissions "$@"
fi
