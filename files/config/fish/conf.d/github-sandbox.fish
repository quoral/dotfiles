# Load GitHub sandbox token from secrets file
# Create token at: https://github.com/settings/tokens?type=beta
# Save to: ~/.config/secrets/github-sandbox-token

set -l token_file ~/.config/secrets/github-sandbox-token

if test -f $token_file
    set -gx GITHUB_SANDBOX_TOKEN (cat $token_file | string trim)
end
