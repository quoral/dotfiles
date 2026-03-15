function claude-auth --description "Set Claude Code authentication method"
    switch "$argv[1]"
        case aws
            set -U CLAUDE_AUTH_MODE aws
            # Apply immediately
            set -gx CLAUDE_CODE_USE_BEDROCK 1
            set -gx AWS_REGION eu-central-1
            set -gx ANTHROPIC_MODEL 'eu.anthropic.claude-opus-4-5-20251101-v1:0'
            set -gx ANTHROPIC_SMALL_FAST_MODEL 'eu.anthropic.claude-haiku-4-5-20251001-v1:0'
            echo "Claude auth set to: AWS Bedrock"
        case sso
            set -U CLAUDE_AUTH_MODE sso
            # Clear Bedrock env vars immediately
            set -e CLAUDE_CODE_USE_BEDROCK
            set -e ANTHROPIC_MODEL
            set -e ANTHROPIC_SMALL_FAST_MODEL
            echo "Claude auth set to: SSO (Pro Max)"
        case ''
            # Show current mode
            set -l mode (test -n "$CLAUDE_AUTH_MODE"; and echo $CLAUDE_AUTH_MODE; or echo "sso")
            echo "Claude auth mode: $mode"
            echo ""
            echo "Usage: claude-auth <aws|sso>"
        case '*'
            echo "Unknown mode: $argv[1]"
            echo "Usage: claude-auth <aws|sso>"
            return 1
    end
end
