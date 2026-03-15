function claude-creds --description "Refresh shared sandbox credentials"
    set shared_cache $CLAUDE_WORKSPACE_DIR/.shared-cache

    switch "$argv[1]"
        case aws
            echo "Refreshing AWS credentials..."
            mkdir -p "$shared_cache/aws"

            # Create minimal config (no SSO settings - those don't work in container)
            echo "[profile dev]
region = eu-central-1
output = json" > "$shared_cache/aws/config"

            # Export current SSO credentials to shared cache
            if set -l creds (aws configure export-credentials --profile dev --format env 2>/dev/null)
                set -l access_key (echo $creds | grep -o 'AWS_ACCESS_KEY_ID=[^[:space:]]*' | cut -d= -f2)
                set -l secret_key (echo $creds | grep -o 'AWS_SECRET_ACCESS_KEY=[^[:space:]]*' | cut -d= -f2)
                set -l session_token (echo $creds | grep -o 'AWS_SESSION_TOKEN=[^[:space:]]*' | cut -d= -f2)

                echo "[dev]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token" > "$shared_cache/aws/credentials"
                chmod 600 "$shared_cache/aws/credentials"
                echo "✓ AWS credentials refreshed in shared cache"
            else
                echo "⚠️  Could not export AWS credentials. Run: aws sso login --profile dev"
            end

        case gcloud
            echo "Refreshing gcloud credentials..."
            mkdir -p "$shared_cache/gcloud"
            chmod 777 "$shared_cache/gcloud"

            # Set gcloud config dir to shared cache
            set -lx CLOUDSDK_CONFIG "$shared_cache/gcloud"
            gcloud auth login --no-browser
            echo "✓ gcloud credentials refreshed in shared cache"

        case '*'
            echo "Usage: claude-creds <aws|gcloud>"
            echo ""
            echo "Commands:"
            echo "  aws     Refresh AWS session credentials"
            echo "  gcloud  Run gcloud auth login"
    end
end
