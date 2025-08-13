#!/bin/bash

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)
default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)

# Check if we're on the default branch
if [ "$current_branch" = "$default_branch" ]; then
  echo "Warning: You are on the default branch ($default_branch)"
  read -p "Would you like to create a new branch? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter new branch name: " branch_name
    git checkout -b "$branch_name"
    echo "Switched to new branch: $branch_name"
  else
    echo "Continuing on default branch..."
  fi
fi

# Get the base branch
base_branch=$(git merge-base HEAD origin/$default_branch 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Fetching updates from remote..."
  git fetch
  base_branch=$(git merge-base HEAD origin/$default_branch)
fi

# Get the diff and status
diff_output=$(git diff $base_branch)
status_output=$(git status)

# Create a temporary working directory
tmp_dir=$(mktemp -d)
tmp_file="$tmp_dir/diff.txt"

# Write the prompt, status, and diff to the temp file
cat >"$tmp_file" <<EOL
Please analyze this git diff and status to generate a concise, clear commit message that summarizes the changes.
Focus on the what and why of the changes.
Format the message in conventional commit style. Only write the commit message, do not include any other text.
Write the commit message in the present tense, and use imperative mood.

Git Status:
$status_output

Git Diff:
$diff_output
EOL

# API configuration
API_ENDPOINT="https://api.anthropic.com/v1/messages"
API_MODEL="claude-3-5-sonnet-20241022"

# Use API key from environment
API_KEY=${ANTHROPIC_API_KEY}
if [ -z "$API_KEY" ]; then
  echo "Error: No API key found. Set ANTHROPIC_API_KEY environment variable."
  exit 1
fi

# Prepare the API request - properly escape the content
prompt=$(cat "$tmp_file" | jq -sR .)
json_payload=$(jq -n \
  --arg model "$API_MODEL" \
  --arg content "$prompt" \
  '{
    "model": $model,
    "messages": [
      {
        "role": "user",
        "content": $content
      }
    ],
    "max_tokens": 1000
  }')

# Make the API request
response=$(curl -s \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d "$json_payload" \
  "$API_ENDPOINT")
# Extract the response content and handle the commit flow
if echo "$response" | jq -e 'has("error")' >/dev/null; then
  echo "Error from API:" >&2
  echo "$response" | jq -r '.error.type,.error.message' >&2
  exit 1
else
  commit_msg=$(echo "$response" | jq -r '.content[0].text')
  echo -e "\nProposed commit message:\n-------------------\n$commit_msg\n-------------------\n"

  read -p "Do you want to (a)ccept, (e)dit, or (r)eject this commit message? [a/e/r] " -n 1 -r
  echo
  case $REPLY in
  [Aa]*)
    echo "$commit_msg" | git commit -a -F -
    echo "Changes committed!"
    ;;
  [Ee]*)
    echo "$commit_msg" >"$tmp_dir/COMMIT_MSG"
    if [ -n "$EDITOR" ]; then
      $EDITOR "$tmp_dir/COMMIT_MSG"
    else
      vim "$tmp_dir/COMMIT_MSG"
    fi
    cat "$tmp_dir/COMMIT_MSG" | git commit -F -
    echo "Changes committed with edited message!"
    ;;
  [Rr]*)
    echo "Commit cancelled."
    ;;
  *)
    echo "Invalid choice. Commit cancelled."
    ;;
  esac
fi

# Clean up
rm -rf "$tmp_dir"
