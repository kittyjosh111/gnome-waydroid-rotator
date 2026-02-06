#!/bin/bash
# This is the part of the script meant to be run from the USER, NOT ROOT
# You'll also need inotify tools installed. Refer to other instructions if you don't know how to install
# You'll also need to be using KDE!!!

######################################################################
## DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ##
######################################################################

USER_CONFIG="$1"
if [ ! -z "$USER_CONFIG" ]; then
  echo "User config file passed. Using config file at $USER_CONFIG"
  if [ -f "$USER_CONFIG" ]; then
    . "$USER_CONFIG"
  else
    echo "Config file not found. Exiting..."
    exit 1
  fi
else
  echo "Using default config file at /etc/gnome-waydroid-rotator.conf"
  . /etc/gnome-waydroid-rotator.conf
fi

## prevent root
if [ "$(id -u)" == "0" ]; then
   echo "This script can not be run as root!" 1>&2
   exit 1
fi

## define a function that returns True when we can grep, False otherwise
grep_check () {
  if [ ! -z "$(echo "$1" | grep "$2")" ]; then
    return 0 #pretend this is false
  else
    return 1 #and thats true
  fi
}

waydroid_check () {
  focus_win="$(kdotool getactivewindow getwindowname)"
  if grep_check "$focus_win" "Waydroid"; then
    if [[ $debug_mode == 1 ]]; then
      echo "  - Waydroid is focused."
    fi
    return 0
  else
    if [[ $debug_mode == 1 ]]; then
      echo "  - Waydroid is not focused."
    fi
    return 1
  fi
}

waydroid_rotate () {
  #we have to run two functions at once, one of which handles root waydroid stuff, the other userland gnome stuff
  echo "$1" > /tmp/gwr/tell_root 2>&1 &
}

actual_rot () {
  if grep_check "$1" "$device_landscape_normal"; then
    if [[ $debug_mode == 1 ]]; then
      echo "- Device in LANDSCAPE NORMAL orientation."
    fi
    gdrot="normal"
    wayrot=$normal
  elif grep_check "$1" "$device_left_portrait"; then
    if [[ $debug_mode == 1 ]]; then
      echo "- Device in LEFT PORTRAIT orientation."
    fi
    gdrot="left"
    wayrot=$left_up
  elif grep_check "$1" "$device_landscape_flipped"; then
    if [[ $debug_mode == 1 ]]; then
      echo "- Device in LANDSCAPE FLIPPED orientation."
    fi
    gdrot="inverted"
    wayrot=$flipped
  elif grep_check "$1" "$device_right_portrait"; then
    if [[ $debug_mode == 1 ]]; then
      echo "- Device in RIGHT PORTRAIT orientation."
    fi
    gdrot="right"
    wayrot=$right_up
  else
    if [[ $debug_mode == 1 ]]; then
      echo "- Edge case reached in rot_map."
    fi
    gdrot="false"
  fi
  #then we determine rotation logic
  if [ "$gdrot" != "false" ]; then
    if waydroid_check; then
      kscreen-doctor output.$gdmon.rotation.normal
      waydroid_rotate $wayrot
    else
      kscreen-doctor output.$gdmon.rotation.$gdrot
    fi
  fi
}

## and a function that maps the DEVICE rotation to WAYDROID rotation
rot_map () {
  if [ ! -f "/tmp/gwr/lock" ]; then
    rm /tmp/gwr/manual 2> /dev/null #just make sure its gone
    actual_rot "$(cat /tmp/gwr/device_rotation | grep 'orientation changed:' | tail -n1)" #being called by inotify
  else
    if [[ $debug_mode == 1 ]]; then
      echo "- Rotation is locked."
    fi
    if [ -f "/tmp/gwr/manual" ]; then
      given_orient="$(cat /tmp/gwr/manual)"
      if [[ $debug_mode == 1 ]]; then
        echo "- Manual rotation received: $given_orient"
      fi
      actual_rot "$given_orient"
    fi
  fi
}

## start running rotation logging
mkdir -p /tmp/gwr/ 2> /dev/null
rm -rf /tmp/gwr/device_rotation 2> /dev/null #clear the rotation stuff
rm -rf /tmp/gwr/manual 2> /dev/null #any leftover manual
rm -rf /tmp/gwr/lock 2> /dev/null #or locks
touch /tmp/gwr/tell_root 2> /dev/null #just set it up

## pre-run checks
echo "Starting prerun checks..."
check_ms=0
until [ $check_ms = 143 ]; do
  timeout --preserve-status 1s monitor-sensor
  check_ms=$?
  sleep 1
done
monitor-sensor --accel | grep --line-buffered "orientation" > /tmp/gwr/device_rotation 2>&1 &
echo "- Monitoring rotation status via monitor-sensor..."
sleep 2 #let files populate

## and now, we check the initial rotation. We only start the script if we are in "NORMAL"
# the first ever out from monitor-sensor uses oreintation:
if ! grep_check "$(cat /tmp/gwr/device_rotation | grep 'orientation:' | tail -n1)" "$device_landscape_normal"; then
  echo "Prerun checklist failed. We are not in NORMAL orientation."
  while : # use polling here to wait for the exit from tablet mode. Oh well. inotify somehow won't break the loop correctly
	do
	sleep 2
	if grep_check "$(cat /tmp/gwr/device_rotation | grep 'orientation' | tail -n1)" "$device_landscape_normal"; then
		echo "- Entered NORMAL orientation. We are now safe to start the script."
		break 2
	fi
	done
fi

## ready
rot_map "$device_landscape_normal" #cuz we are supposed to be in normal now
echo "Prerun checklist complete. We are ready to rotate."

trap 'kill 0' SIGINT SIGTERM

## Polling is expensive. Let us use inotify.
echo "Main loop started in background..."
(
  inotifywait --monitor --format "%e %w%f" --event modify,create /tmp/gwr/ --include '(device_rotation|manual)' | while read changed; do
    rot_map
  done
) &
echo "Watching for focused window changes..."
(
way_last=false #have a way to toggle between the rotation types
#still_waydroid=false
while true; do
  current_window="$(kdotool getactivewindow getwindowname 2>/dev/null)"
  if grep_check "$current_window" "Waydroid"; then
    if [[ $debug_mode == 1 ]]; then
      echo "  - kdotool reports Waydroid focused."
    fi
    way_last=true
    this_rot="$(cat /tmp/gwr/device_rotation | grep 'orientation changed:' | tail -n1)"
    rot_map "$this_rot"
  else
    if $way_last; then
      rot_map "$(cat /tmp/gwr/device_rotation | grep 'orientation changed:' | tail -n1)"
    fi
    way_last=false
  fi
  sleep 0.5
done
) &

wait
