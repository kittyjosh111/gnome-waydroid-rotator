#!/bin/bash

# This is the part of the script meant to be run from the ROOT, NOT USER
# All it does is wait for the user script to write to /tmp/gnome-waydroid-rotator.now, then takes said value and passes it to the waydroid rotator

## Polling is expensive. Let us use inotify.
## also, we don't do any checking lmao xd

if [ ! -f "/tmp/gnome-waydroid-rotator.now" ]; then
  echo "/tmp/gnome-waydroid-rotator.now not found. Waiting..."
  inotifywait --monitor --format '%f' --event modify,create /tmp/ | while read -r filename; do
    if [ "$filename" == "gnome-waydroid-rotator.now" ]; then
      echo "/tmp/gnome-waydroid-rotator.now found! Restarting service..."
      systemctl restart gnome-waydroid-rotator_root
    fi
  done
fi

inotifywait --monitor --format "%e %w%f" --event modify,create /tmp/gnome-waydroid-rotator.now | while read changed; do
  rot_value=$(cat /tmp/gnome-waydroid-rotator.now)
  waydroid shell wm user-rotation lock $rot_value
done
