#!/bin/bash
#if [ "$(id -u)" != "0" ]; then
#   echo "Please run this script using sudo!" 1>&2
#   exit 1
#fi

trap 'kill 0' SIGINT SIGTERM EXIT

  echo "Starting root script..."
  sudo /usr/local/bin/gnome-waydroid-rotator_root.sh &

  echo "Starting user script..."
  /usr/local/bin/gnome-waydroid-rotator_user.sh &

wait