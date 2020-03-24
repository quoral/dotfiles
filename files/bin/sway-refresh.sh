#!/usr/bin/env bash
set -eux pipefail
swaymsg -t get_outputs \
            | jq --raw-output  ".[].name | select(. != \"eDP-1\")" \
            | tr -d '\n' \
            | xargs -d ' '  -0 -I{} sh -c "swaymsg output {} disable; sleep 10; swaymsg output {} enable"
