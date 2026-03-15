FROM ubuntu:24.04

# Install base tools
RUN apt-get update && apt-get install -y \
    git curl jq unzip build-essential ca-certificates gnupg python3 python3-pip python3-venv sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install AWS CLI v2 (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    else \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    fi && \
    unzip awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip

# Install gcloud CLI
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update && apt-get install -y google-cloud-cli

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh

# Create non-root user with passwordless sudo (Claude needs to install packages)
RUN useradd -m -s /bin/bash sandbox \
    && echo "sandbox ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sandbox

# Switch to sandbox user for remaining setup
USER sandbox
WORKDIR /home/sandbox

# Install Claude Code (native installer)
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/sandbox/.claude/bin:$PATH"

# Install mise
RUN curl https://mise.run | sh
ENV PATH="/home/sandbox/.local/bin:$PATH"

# Create config directories (settings copied from host at runtime)
RUN mkdir -p /home/sandbox/.claude /home/sandbox/.config

WORKDIR /workspace

COPY --chown=sandbox:sandbox entrypoint.sh /home/sandbox/entrypoint.sh
RUN chmod +x /home/sandbox/entrypoint.sh

ENTRYPOINT ["/home/sandbox/entrypoint.sh"]
