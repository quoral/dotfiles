#!/opt/homebrew/bin/bash
set -euo pipefail

AERO=/opt/homebrew/bin/aerospace
STATE_FILE="$HOME/.local/state/aerospace/ring-slot"

last_slot=1
[[ -f "$STATE_FILE" ]] && last_slot=$(cat "$STATE_FILE")

current_ws=$($AERO list-workspaces --focused)

occupied=()
while IFS= read -r ws; do
  [[ "$ws" =~ ^R([0-9]+)$ ]] && occupied+=("${BASH_REMATCH[1]}")
done < <($AERO list-windows --all --format '%{workspace}' | sort -u)

IFS=$'\n' occupied=($(printf '%s\n' "${occupied[@]}" | sort -n | uniq)); unset IFS

current_n=""
[[ "$current_ws" =~ ^R([0-9]+)$ ]] && current_n="${BASH_REMATCH[1]}"

target=""

if [[ ${#occupied[@]} -eq 0 ]]; then
  target=1
elif [[ -z "$current_n" ]]; then
  target="${occupied[0]}"
else
  current_occupied=false
  for s in "${occupied[@]}"; do
    [[ "$s" == "$current_n" ]] && { current_occupied=true; break; }
  done

  if ! $current_occupied; then
    target="${occupied[0]}"
  else
    for s in "${occupied[@]}"; do
      if [[ "$s" -gt "$current_n" ]]; then
        target="$s"
        break
      fi
    done
    [[ -z "$target" ]] && target=$(( ${occupied[-1]} + 1 ))
  fi
fi

primary_monitor=""
while IFS=: read -r ws mid; do
  [[ "$ws" == "1" ]] && { primary_monitor="$mid"; break; }
done < <($AERO list-workspaces --all --format '%{workspace}:%{monitor-id}')

$AERO workspace "R${target}"
$AERO move-workspace-to-monitor --workspace "R${target}" "${primary_monitor:-1}"

mkdir -p "$(dirname "$STATE_FILE")"
echo "$target" > "$STATE_FILE"
