#!/usr/bin/env python

# set -e

# LOCKSCREEN_PATH=/tmp/sway-lock
# sway_screens=$(swaymsg -t get_outputs | jq --raw-output  "del(.[] | select(.active == false)) | .[].name")
# echo -e $sway_screens | tr -d '\n' | xargs -d ' ' -I{} -P 4 sh -c "grim -o {} - | ffmpeg -i pipe: -vf gblur=sigma=5 -y $LOCKSCREEN_PATH-{}.png"
# backgrounds=$(echo -e $sway_screens | tr -d '\n' | xargs -d ' ' -I{} -P 4 echo "--image {}:$LOCKSCREEN_PATH-{}.png" | tr '\n' ' ')
# swaylock $backgrounds

def main():
    pass
