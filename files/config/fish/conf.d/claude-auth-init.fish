# Set default Claude auth mode if not already set
if not set -q CLAUDE_AUTH_MODE
    set -U CLAUDE_AUTH_MODE sso
end

# Configure Claude Code environment based on auth mode
if test "$CLAUDE_AUTH_MODE" = aws
    # AWS Bedrock configuration
    set -gx CLAUDE_CODE_USE_BEDROCK 1
    set -gx AWS_REGION eu-central-1

    set -gx CLAUDE_CODE_MAX_OUTPUT_TOKENS 4096
    set -gx MAX_THINKING_TOKENS 1024

    set -gx ANTHROPIC_MODEL 'eu.anthropic.claude-opus-4-5-20251101-v1:0'
    set -gx ANTHROPIC_SMALL_FAST_MODEL 'eu.anthropic.claude-haiku-4-5-20251001-v1:0'
else
    # SSO (Pro Max) - clear Bedrock env vars
    set -e CLAUDE_CODE_USE_BEDROCK
    set -e ANTHROPIC_MODEL
    set -e ANTHROPIC_SMALL_FAST_MODEL
end
