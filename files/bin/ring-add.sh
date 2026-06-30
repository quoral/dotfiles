#!/opt/homebrew/bin/bash
set -euo pipefail

AERO=/opt/homebrew/bin/aerospace
STATE_FILE="$HOME/.local/state/aerospace/ring-slot"

slot=1
[[ -f "$STATE_FILE" ]] && slot=$(cat "$STATE_FILE")

window_id=$($AERO list-windows --focused --format '%{window-id}') || exit 0
[[ -z "$window_id" ]] && exit 0

$AERO move-node-to-workspace --window-id "$window_id" "R${slot}"
