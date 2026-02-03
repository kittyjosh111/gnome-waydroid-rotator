#!/bin/bash

# This is the part of the script meant to be run from the ROOT, NOT USER
# All it does is wait for the user script to write to /tmp/gnome-waydroid-rotator.now, then takes said value and passes it to the waydroid rotator

## Polling is expensive. Let us use inotify.
## also, we don't do any checking lmao xd

if [ ! -f "/tmp/gwr/tell_root" ]; then
  echo "/tmp/gwr/tell_root not found. Waiting..."
  inotifywait --monitor --format '%f' --event modify,create /tmp/gwr/ | while read -r filename; do
    if [ "$filename" == "tell_root" ]; then
      echo "/tmp/gwr/tell_root found! Restarting service..."
      systemctl restart gnome-waydroid-rotator_root
    fi
  done
fi

inotifywait --monitor --format "%e %w%f" --event modify,create /tmp/gwr/tell_root | while read changed; do
  rot_value=$(cat /tmp/gwr/tell_root)
  waydroid shell wm user-rotation lock $rot_value
done
