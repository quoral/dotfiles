#!/usr/bin/env bash
set -uo pipefail

args=""
pid=$(swaymsg -t get_tree | jq '.. | select(.type?) | select(.type=="con") | select(.focused==true).pid')
RESULT=$?
if [ $RESULT == 0 ]; then
    ppid=$(pgrep --newest --parent ${pid})
    cwd=$(readlink /proc/${ppid}/cwd || echo $HOME)

    if [ ! -d "$cwd" ]; then
        cwd="$HOME"
    fi

    if [[ $1 == "kitty" ]]; then
        args="--directory=${cwd}"
    fi
fi


swaymsg exec "$1 $args"
