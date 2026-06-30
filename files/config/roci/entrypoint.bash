#!/usr/bin/env bash
set -euo pipefail

# Root init: fix Docker socket permissions, then drop to roci user.
if [ "$(id -u)" = "0" ]; then
    if [ -S /var/run/docker.sock ]; then
        chmod 666 /var/run/docker.sock
    fi
    exec gosu roci "$0" "$@"
fi

# Mark onboarding complete and pre-trust /workspace so Claude Code
# doesn't prompt for trust or onboarding in containers.
mkdir -p ~/.claude
echo '{"hasCompletedOnboarding":true,"projects":{"/workspace":{"hasTrustDialogAccepted":true}}}' > ~/.claude.json

# Copy host claude config if mounted.
if [ -d /mnt/host-claude ]; then
    cp /mnt/host-claude/settings.json ~/.claude/settings.json 2>/dev/null || true
    cp /mnt/host-claude/CLAUDE.md ~/.claude/CLAUDE.md 2>/dev/null || true
    cp -r /mnt/host-claude/skills ~/.claude/skills 2>/dev/null || true
fi

# Copy project-specific memories and CLAUDE.md.
# ROCI_PROJECT_MAPS: newline-separated "src_dir:dst_dir" pairs.
if [ -n "${ROCI_PROJECT_MAPS:-}" ]; then
    while IFS=: read -r src_dir dst_dir; do
        [ -z "$src_dir" ] && continue
        dst="$HOME/.claude/projects/$dst_dir"
        if [ -d "/mnt/host-claude/projects/$src_dir/memory" ]; then
            mkdir -p "$dst" && \
            cp -r "/mnt/host-claude/projects/$src_dir/memory" "$dst/memory" || true
        fi
        if [ -f "/mnt/host-claude/projects/$src_dir/CLAUDE.md" ]; then
            mkdir -p "$dst" && \
            cp "/mnt/host-claude/projects/$src_dir/CLAUDE.md" "$dst/CLAUDE.md" || true
        fi
    done <<< "$ROCI_PROJECT_MAPS"
fi

# Copy host git config to a writable location and sanitise for the container.
if [ -f /mnt/host-gitconfig ]; then
    cp /mnt/host-gitconfig ~/.gitconfig
    # Remove credential helpers that reference host-specific binaries.
    git config --global --remove-section 'credential "https://github.com"' 2>/dev/null || true
    git config --global --remove-section 'credential "https://gist.github.com"' 2>/dev/null || true
fi

# Mark all directories as safe (host-mounted repos have different UIDs).
git config --global safe.directory '*'

# Regenerate mise shims (they break across container rebuilds).
mise reshim 2>/dev/null || true

# Configure GitHub auth if a token is available.
if [ -n "${GH_TOKEN:-}" ]; then
    echo "$GH_TOKEN" | gh auth login --with-token 2>/dev/null || true
    gh auth setup-git 2>/dev/null || true
fi

exec claude "$@"
