#!/usr/bin/env bash
set -euo pipefail

pid=$(swaymsg -t get_tree | jq '.. | select(.type?) | select(.type=="con") | select(.focused==true).pid')
ppid=$(pgrep --newest --parent ${pid})
cwd=$(readlink /proc/${ppid}/cwd || echo $HOME)

args=""
if [[ $1 == "kitty" ]]
then
    args="--directory=${cwd}"
fi

swaymsg exec "$1 $args"
