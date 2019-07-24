#!/bin/sh
# Copied/Modified from http://stackoverflow.com/questions/4404242/programmatically-launch-terminal-app-with-a-specified-command-and-custom-colors

echo '
on run argv
  if length of argv is equal to 0
    set command to ""
  else
    set command to item 1 of argv
  end if

  if application "Terminal" is not running then
    set useWindow1 to true
  else
    set useWindow1 to false
  end if

  tell application "Terminal"
    reopen
    activate
    if useWindow1 then
      do script command in window 1
    else
      do script command
    end if
  end tell
end run
' | osascript - "$@" > /dev/null
