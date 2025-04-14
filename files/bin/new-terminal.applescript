#!/usr/bin/osascript

tell application "Ghostty"
	if it is running then
		activate
		tell application "System Events" to keystroke "n" using {command down}
	else
		activate
	end if
end tell