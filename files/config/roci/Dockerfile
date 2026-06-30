FROM debian:bookworm-slim

# System dependencies, Docker CLI (client-only), and gosu (privilege drop).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl git jq ca-certificates gnupg gosu socat && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian bookworm stable" > \
        /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user (Claude Code refuses bypass permissions as root).
RUN useradd -m -s /bin/bash roci
USER roci

# Install mise (tool version manager).
RUN curl https://mise.run | sh
ENV PATH="/home/roci/.local/bin:/home/roci/.local/share/mise/shims:${PATH}"
# Auto-trust workspace mise configs (repos may specify their own tool versions).
ENV MISE_YES=1

# Install node, gh, and pnpm via mise.
RUN mise use -g node@20 gh@latest pnpm@latest

# Install Claude Code via native installer (independent of mise node version).
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/roci/.claude/bin:${PATH}"

# Fix PATH for login shells: /etc/profile hardcodes PATH and clobbers the
# Docker ENV. Append our paths so mise shims and claude are available when
# Claude Code spawns `bash -l`.
USER root
RUN echo 'PATH="/home/roci/.claude/bin:/home/roci/.local/bin:/home/roci/.local/share/mise/shims:$PATH"' >> /etc/profile

# Container entrypoint: copies host config, sets up auth, launches claude.
COPY --chown=roci:roci entrypoint.bash /home/roci/entrypoint.bash
RUN chmod +x /home/roci/entrypoint.bash

# Project directory — host repos are mounted here at runtime.
WORKDIR /workspace

# Run entrypoint as root so it can fix Docker socket permissions,
# then drop to roci via gosu.
USER root
ENTRYPOINT ["/home/roci/entrypoint.bash"]
