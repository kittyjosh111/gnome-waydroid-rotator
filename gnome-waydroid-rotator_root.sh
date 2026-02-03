#!/bin/bash

# This is the part of the script meant to be run from the ROOT, NOT USER
# All it does is wait for the user script to write to /tmp/gnome-waydroid-rotator.now, then takes said value and passes it to the waydroid rotator

## Polling is expensive. Let us use inotify.
## also, we don't do any checking lmao xd

first_message=true

until [ -s "/tmp/gwr/tell_root" ]; do
  if [ $first_message == true ]; then
    echo "/tmp/gwr/tell_root (bridge to user portion) not found. Waiting..."
    first_message=false
  fi
  sleep 1
done

echo "Starting main root loop..."

inotifywait --monitor --format "%e %w%f" --event modify,create /tmp/gwr/tell_root | while read changed; do
  rot_value=$(cat /tmp/gwr/tell_root)
  waydroid shell wm user-rotation lock $rot_value
done
