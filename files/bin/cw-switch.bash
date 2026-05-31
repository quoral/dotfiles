#!/bin/bash
set -euo pipefail

# Fuzzy switch between active project workspaces.
# Two modes:
#   (no args)     — called from AeroSpace keybinding, opens Ghostty popup
#   --pick <file> — runs inside the popup, writes selection to file

STATE_FILE="$HOME/.local/state/cw/workspaces"

if [ "${1:-}" = "--pick" ]; then
  OUTFILE="${2:-}"

  WORKSPACES=$(aerospace list-workspaces --all | grep '^p:' | grep -v '[*\[\]\\]' || true)

  if [ -z "$WORKSPACES" ]; then
    echo "No active project workspaces"
    sleep 1
    exit 0
  fi

  LIST=""
  while IFS= read -r ws; do
    dir=""
    if [ -f "$STATE_FILE" ]; then
      dir=$(grep "^${ws}$(printf '\t')" "$STATE_FILE" 2>/dev/null | cut -f2 || true)
    fi
    name="${ws#p:}"
    if [ -n "$dir" ]; then
      short_dir="${dir/#$HOME/~}"
      LIST+="$(printf '%-20s %s' "$name" "$short_dir")"$'\n'
    else
      LIST+="$name"$'\n'
    fi
  done <<< "$WORKSPACES"

  SELECTED=$(echo -n "$LIST" | fzf --prompt="workspace > " --height=100% --reverse --no-info --no-border) || true

  if [ -n "$SELECTED" ] && [ -n "$OUTFILE" ]; then
    WS_NAME="p:$(echo "$SELECTED" | awk '{print $1}')"
    echo "$WS_NAME" > "$OUTFILE"
  fi
  exit 0
fi

# Called from AeroSpace keybinding — orchestrate the popup
WORKSPACES=$(aerospace list-workspaces --all | grep '^p:' | grep -v '[*\[\]\\]' || true)

if [ -z "$WORKSPACES" ]; then
  osascript -e 'display notification "No active project workspaces" with title "Workspace Switcher"'
  exit 0
fi

TMPFILE=$(mktemp /tmp/cw-switch-XXXXXX)

# Snapshot window IDs before opening
BEFORE_IDS=$(aerospace list-windows --all --format '%{window-id}' | sort)

# Open Ghostty popup running fzf picker
open -na Ghostty.app --args \
  --title=cw-switch \
  -e bash -c "$HOME/.local/bin/cw-switch --pick '$TMPFILE'"

# Wait for new window and get its ID
NEW_WID=""
ELAPSED=0
while [ "$ELAPSED" -lt 20 ]; do
  AFTER_IDS=$(aerospace list-windows --all --format '%{window-id}' | sort)
  NEW_WID=$(comm -13 <(echo "$BEFORE_IDS") <(echo "$AFTER_IDS") | head -1)
  if [ -n "$NEW_WID" ]; then
    break
  fi
  sleep 0.2
  ELAPSED=$((ELAPSED + 1))
done

# Float, resize, and center the popup
if [ -n "$NEW_WID" ]; then
  aerospace focus --window-id "$NEW_WID"
  aerospace layout floating

  osascript <<'APPLESCRIPT' 2>/dev/null || true
use framework "AppKit"

set winW to 700
set winH to 400

set screenFrame to current application's NSScreen's mainScreen()'s frame()
set screenW to item 1 of item 2 of screenFrame
set screenH to item 2 of item 2 of screenFrame

set posX to (screenW - winW) / 2
set posY to (screenH - winH) / 3

tell application "System Events"
  tell process "Ghostty"
    repeat with w in windows
      if name of w contains "cw-switch" then
        set size of w to {winW, winH}
        set position of w to {posX, posY}
      end if
    end repeat
  end tell
end tell
APPLESCRIPT
fi

# Wait for Ghostty popup to close
ELAPSED=0
while [ "$ELAPSED" -lt 60 ]; do
  if ! aerospace list-windows --all --format '%{window-title}' 2>/dev/null | grep -q '^cw-switch$'; then
    break
  fi
  sleep 0.3
  ELAPSED=$((ELAPSED + 1))
done

# Read selection and switch workspace (from this script, no window involved)
if [ -s "$TMPFILE" ]; then
  WS_NAME=$(cat "$TMPFILE")
  aerospace workspace "$WS_NAME"
fi

rm -f "$TMPFILE"
