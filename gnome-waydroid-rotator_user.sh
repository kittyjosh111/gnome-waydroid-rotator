#!/bin/bash

# This is the part of the script meant to be run from the USER, NOT ROOT
# You'll need this extension installed: https://github.com/dev-muhammad-adel/window-calls-extended
# You'll also need inotify tools installed. Refer to other instructions if you don't know how to install
# You'll also need to be using GNOME.

## monitor-sensor options:
# set the following strings to some identifiable string that indicates your device's orientation
device_landscape_normal="normal"
device_left_portrait="left-up"
device_right_portrait="right-up"
device_landscape_flipped="bottom-up"

## waydroid shell rotation:
# test these by running 'waydroid shell wm user-rotation lock $NUMBER'
# depending on waydroid version, the above command might use set-user-rotation instead
normal="0"
left_up="3"
right_up="1"
flipped="2"

## gdctl options:
# run ```gdctl show``` to list out your monitors. Find the one that you want to control rotation for.
# gdscale is the scaling you want to use. It is technically a float i guess, things like 1, 2, 1.25, etc.
gdmon="eDP-1"
gdscale=1

## set to turn on debug messages
debug_mode=1

######################################################################
## DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ##
######################################################################

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
  focus_win="$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/WindowMonitorPro --method org.gnome.Shell.Extensions.WindowMonitorPro.FocusTitle)"
  if grep_check "$focus_win" "'Waydroid'"; then
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
  echo "$1" > /tmp/gnome-waydroid-rotator.now 2>&1 &
}

## and a function that maps the DEVICE rotation to WAYDROID rotation
rot_map () {
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
    gdrot="90"
    wayrot=$left_up
  elif grep_check "$1" "$device_landscape_flipped"; then
    if [[ $debug_mode == 1 ]]; then
      echo "- Device in LANDSCAPE FLIPPED orientation."
    fi
    gdrot="180"
    wayrot=$flipped
  elif grep_check "$1" "$device_right_portrait"; then
    if [[ $debug_mode == 1 ]]; then
      echo "- Device in RIGHT PORTRAIT orientation."
    fi
    gdrot="270"
    wayrot=$right_up
  else
    if [[ $debug_mode == 1 ]]; then
      echo "- Edge case reached in rot_map."
    fi
    gdrot="false"
  fi
  #then we determine waydroid logic
  if [ "$gdrot" != "false" ]; then
    if waydroid_check; then
      gdctl set -LpM "$gdmon" -s $gdscale -t "normal" #force normal orientation if waydroid focused
      waydroid_rotate $wayrot
    else
      gdctl set -LpM "$gdmon" -s $gdscale -t $gdrot
    fi
  fi
}

## start running rotation logging
rm /tmp/gnome-waydroid-rotator_rotation.tmp || true #clear the rotation stuff

## pre-run checks
echo "Starting prerun checks..."
#monitor-sensor --accel > /tmp/gnome-waydroid-rotator_rotation.tmp 2>&1 &
monitor-sensor --accel | grep --line-buffered "orientation" > /tmp/gnome-waydroid-rotator_rotation.tmp 2>&1 &
echo "- Monitoring rotation status via monitor-sensor..."
sleep 2 #let files populate

## and now, we check the initial rotation. We only start the script if we are in "NORMAL"
# the first ever out from monitor-sensor uses oreintation:
if ! grep_check "$(cat /tmp/gnome-waydroid-rotator_rotation.tmp | grep 'orientation:' | tail -n1)" "$device_landscape_normal"; then
  echo "Prerun checklist failed. We are not in NORMAL orientation."
  while : # use polling here to wait for the exit from tablet mode. Oh well. inotify somehow won't break the loop correctly
	do
	sleep 2
	if grep_check "$(cat /tmp/gnome-waydroid-rotator_rotation.tmp | grep 'orientation' | tail -n1)" "$device_landscape_normal"; then
		echo "- Entered NORMAL orientation. We are now safe to start the script."
		break 2
	fi
	done
fi

## ready
rot_map "$device_landscape_normal" #cuz we are supposed to be in normal now
echo "Prerun checklist complete. We are ready to rotate."

## Polling is expensive. Let us use inotify.
echo "Main loop started in background..."
(
  inotifywait --monitor --format "%e %w%f" --event modify,create /tmp/gnome-waydroid-rotator_rotation.tmp | while read changed; do
    rot_map "$(cat /tmp/gnome-waydroid-rotator_rotation.tmp | grep 'orientation changed:' | tail -n1)"
  done
) 2>&1 &

echo "Watching gdbus for focused window changes..."

## gdbus tells us what comes into focused
(
gdbus monitor --session --dest org.gnome.Shell | while read -r line; do
  if grep_check "$line" "WindowFocusChanged"; then
    #echo "- Focus changed."
    if grep_check "$line" "'Waydroid'"; then
      if [[ $debug_mode == 1 ]]; then
        echo "  - gdbus reports Waydroid focused."
      fi
      this_rot="$(cat /tmp/gnome-waydroid-rotator_rotation.tmp | grep 'orientation changed:' | tail -n1)"
      rot_map "$this_rot"
      rot_map "$this_rot" #second time triggers waydroid rotation
    fi
  fi
done
) 2>&1 &

wait