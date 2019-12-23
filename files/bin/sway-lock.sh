#!/usr/bin/env bash

set -e

LOCKSCREEN_PATH=/tmp/sway-lock.png

grim - | ffmpeg -i pipe: -vf gblur=sigma=5 -y $LOCKSCREEN_PATH
swaylock --image $LOCKSCREEN_PATH
