#!/bin/bash
# Toggle an app: focus it if not focused, close its window if focused, open it if not running
# Usage: aerospace-toggle-app.sh "AppName"

APP="$1"

if [ -z "$APP" ]; then
  echo "Usage: aerospace-toggle-app.sh <AppName>" >&2
  exit 1
fi

FOCUSED=$(aerospace list-windows --focused --format '%{app-name}')

if [ "$FOCUSED" = "$APP" ]; then
  osascript -e "tell application \"System Events\" to perform action \"AXPress\" of (first button whose subrole is \"AXCloseButton\") of front window of process \"$APP\""
else
  WINDOW_ID=$(aerospace list-windows --all --format '%{window-id} %{app-name}' | grep " ${APP}$" | head -1 | awk '{print $1}')
  if [ -n "$WINDOW_ID" ]; then
    aerospace focus --window-id "$WINDOW_ID"
  else
    open -a "$APP"
  fi
fi
