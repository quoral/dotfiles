function self-review --description "Ingest reviewer feedback from recent PRs to improve self-review patterns"
    if test "$argv[1]" != "--feedback"
        echo "Usage: self-review --feedback"
        echo ""
        echo "Fetches review comments from your merged PRs in the last 180 days,"
        echo "filters out already-processed ones, and updates feedback-patterns.md"
        return 1
    end

    set -l skill_path "$HOME/Code/Own/devsible/roles/dotfiles/files/config/claude/skills/self-review"
    set -l tombstone_file "$HOME/.claude/self-review-feedback-used.txt"

    if not test -d "$skill_path"
        echo "Error: Skill source not found at $skill_path"
        return 1
    end

    # Ensure tombstone file exists
    touch "$tombstone_file"

    # Find merged PRs authored by me in the last 180 days
    echo "Fetching your merged PRs from the last 180 days..."
    set -l cutoff_date (date -v-180d +%Y-%m-%d 2>/dev/null; or date -d '180 days ago' +%Y-%m-%d)
    set -l prs (gh search prs --author=@me --merged --sort=updated --limit=50 --created=">=$cutoff_date" --json repository,number,title,url 2>/dev/null)

    if test -z "$prs" -o "$prs" = "[]"
        echo "No merged PRs found in the last 180 days."
        return 0
    end

    # Filter out already-processed PRs and those without review comments
    set -l candidates
    set -l candidate_labels

    for pr in (echo $prs | jq -r '.[] | "\(.repository.nameWithOwner)#\(.number)\t\(.title)\t\(.url)"')
        set -l pr_id (echo "$pr" | cut -f1)
        set -l pr_title (echo "$pr" | cut -f2)
        set -l pr_url (echo "$pr" | cut -f3)

        # Skip if already processed
        if grep -qF "$pr_id" "$tombstone_file" 2>/dev/null
            continue
        end

        # Check if PR has review comments
        set -l repo (echo "$pr_id" | string replace -r '#.*' '')
        set -l number (echo "$pr_id" | string replace -r '.*#' '')
        set -l comment_count (gh api "repos/$repo/pulls/$number/comments" --jq 'length' 2>/dev/null)

        if test -n "$comment_count" -a "$comment_count" -gt 0
            set -a candidates "$pr_id"
            set -a candidate_labels "$pr_id - $pr_title ($comment_count comments)"
        end
    end

    if test (count $candidates) -eq 0
        echo "No unprocessed PRs with review comments found."
        return 0
    end

    echo "Found "(count $candidates)" PR(s) with review comments."
    echo ""
    echo "Select PRs to process (TAB to multi-select, ENTER to confirm):"

    set -l selected (printf '%s\n' $candidate_labels | fzf --multi --preview-window=hidden)

    if test -z "$selected"
        echo "No PRs selected."
        return 0
    end

    # Extract PR IDs from selected labels
    set -l selected_ids
    for label in $selected
        set -a selected_ids (echo "$label" | string replace -r ' - .*' '')
    end

    echo "Selected "(count $selected_ids)" PR(s). Fetching review comments..."

    # Collect all review comments
    set -l tmp_comments (mktemp)
    for pr_id in $selected_ids
        set -l repo (echo "$pr_id" | string replace -r '#.*' '')
        set -l number (echo "$pr_id" | string replace -r '.*#' '')

        echo "## $pr_id" >> "$tmp_comments"
        echo "" >> "$tmp_comments"
        gh api "repos/$repo/pulls/$number/comments" --jq '.[] | "**\(.path):\(.line // .original_line // "general")** by \(.user.login):\n\(.body)\n"' >> "$tmp_comments" 2>/dev/null
        # Also get review-level comments (not inline)
        gh api "repos/$repo/pulls/$number/reviews" --jq '.[] | select(.body != "" and .body != null) | "**Review by \(.user.login)** (\(.state)):\n\(.body)\n"' >> "$tmp_comments" 2>/dev/null
        echo "" >> "$tmp_comments"
    end

    echo "Launching Claude to distill patterns..."
    echo ""

    cd "$skill_path"

    claude "I want to update feedback-patterns.md with patterns from new reviewer feedback.

Read feedback-patterns.md first to understand existing patterns.

Here are review comments from my recent PRs:

$(cat $tmp_comments)

Distill these into recurring patterns. Merge into existing categories in feedback-patterns.md or create new ones. Include specific examples (PR reference + what was flagged). Don't just append — synthesize and deduplicate."

    # Mark processed PRs in tombstone
    for pr_id in $selected_ids
        echo "$pr_id" >> "$tombstone_file"
    end

    rm -f "$tmp_comments"
    echo ""
    echo "Marked "(count $selected_ids)" PR(s) as processed."
end
