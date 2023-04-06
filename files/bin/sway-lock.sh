#!/usr/bin/env bash

set -e

sway_screens=$(swaymsg -t get_outputs | jq --raw-output  "del(.[] | select(.active == false)) | .[].name")
#!/bin/sh
for o in $sway_screens
do
    echo $o
	grim -o "$o" "/tmp/$o.png"
	corrupter "/tmp/$o.png" "/tmp/$o.png" &
done
wait
exec gtklock -s ~/.config/gtklock/style.css "$@"
