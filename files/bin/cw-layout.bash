#!/bin/bash
set -euo pipefail

# Creates 3-pane layout in an AeroSpace workspace:
#   +----------+---------+
#   |          | Claude  |
#   |  Neovim  |---------|
#   |          | Terminal|
#   +----------+---------+

WS="$1"
DIR="$2"

window_ids() {
  aerospace list-windows --workspace "$WS" --format '%{window-id}' 2>/dev/null || true
}

wait_for_new_window() {
  local before_ids="$1"
  local elapsed=0
  while [ "$elapsed" -lt 30 ]; do
    local current_ids
    current_ids=$(window_ids)
    local new_id
    new_id=$(comm -13 <(echo "$before_ids" | sort) <(echo "$current_ids" | sort) | head -1)
    if [ -n "$new_id" ]; then
      echo "$new_id"
      return 0
    fi
    sleep 0.3
    elapsed=$((elapsed + 1))
  done
  return 1
}

aerospace workspace "$WS"

# Window 1: Neovim (takes full workspace)
BEFORE=$(window_ids)
open -na Ghostty.app --args --working-directory="$DIR" -e fish -c nvim
NVIM_WID=$(wait_for_new_window "$BEFORE")
sleep 0.3

# Pre-split horizontally so next window goes right
aerospace split --window-id "$NVIM_WID" horizontal

# Window 2: Claude Code
BEFORE=$(window_ids)
open -na Ghostty.app --args --working-directory="$DIR" -e fish -c "claude --continue"
CLAUDE_WID=$(wait_for_new_window "$BEFORE")
sleep 0.3

# Pre-split vertically so next window goes below Claude
aerospace split --window-id "$CLAUDE_WID" vertical

# Window 3: Plain terminal
BEFORE=$(window_ids)
open -na Ghostty.app --args --working-directory="$DIR"
wait_for_new_window "$BEFORE" >/dev/null
sleep 0.3

# Resize nvim to take ~60% width
aerospace focus --window-id "$NVIM_WID"
aerospace resize width +200

# Focus nvim as default
aerospace focus --window-id "$NVIM_WID"
