#!/bin/bash
# This is the part of the script meant to be run from the USER, NOT ROOT
# You'll need this extension installed: https://github.com/dev-muhammad-adel/window-calls-extended
# You'll also need inotify tools installed. Refer to other instructions if you don't know how to install
# You'll also need to be using GNOME.

######################################################################
## DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ##
######################################################################

## load in configs
USER_CONFIG="$1"
if [ ! -z "$USER_CONFIG" ]; then
  echo "User config file passed. Using config file at $USER_CONFIG"
  . "$USER_CONFIG"
else
  . /etc/gnome-waydroid-rotator.conf
fi

## keep track of the children processes
trap 'kill 0' SIGINT SIGTERM EXIT


## prevent root
if [ "$(id -u)" == "0" ]; then
   echo "This script can not be run as root!" 1>&2
   exit 1
fi

## define a function that returns True when we can grep, False otherwise
grep_check () {
  if [ ! -z "$(echo "$1" | grep "$2")" ]; then
    return 0 #this is false, or $2 not in $1
  else
    return 1 #this is true, or $2 is in $1
  fi
}

## define a function that checks whether waydroid is currently in focus
waydroid_check () {
  focus_win="$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/WindowMonitorPro --method org.gnome.Shell.Extensions.WindowMonitorPro.FocusTitle)"
  if grep_check "$focus_win" "'Waydroid'"; then
    return 0 #waydroid focused
  else
    return 1 #waydroid not focused
  fi
}

## function to communicate with our root script counterpart
waydroid_rotate () {
  #we have to run two functions at once, one of which handles root waydroid stuff, the other userland gnome stuff
  echo "$1" > /tmp/gwr/tell_root 2>&1 &
}

## function to handle rotation (one-shot)
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
  #then we determine rotation logic
  if [ "$gdrot" != "false" ]; then
    if waydroid_check; then
      gdctl set -LpM "$gdmon" -s $gdscale -t "normal" #force normal orientation if waydroid focused
      waydroid_rotate $wayrot
    else
      gdctl set -LpM "$gdmon" -s $gdscale -t $gdrot #idk how to deal with multi-monitor setups :(
    fi
  fi
}

## and a function that puts everything together
## and maps the DEVICE rotation to WAYDROID rotation
rot_map () {
  if [ -f "/tmp/gwr/lock" ]; then #if lock file exists
    if [[ $debug_mode == 1 ]]; then
      echo "- Rotation is locked."
    fi
    if [ -f "/tmp/gwr/manual" ]; then #if there is a manual rotation file
      given_orient="$(cat /tmp/gwr/manual)"
      if [[ $debug_mode == 1 ]]; then
        echo "- Manual rotation received: $given_orient"
      fi
      actual_rot "$given_orient"
    fi
  else
    rm /tmp/gwr/manual 2> /dev/null #just make sure its gone
    actual_rot "$(cat /tmp/gwr/device_rotation | grep 'orientation changed:' | tail -n1)" #being called by inotify
  fi
}

##### Script Start #####

## start running rotation logging
mkdir -p /tmp/gwr/ 2> /dev/null
rm -rf /tmp/gwr/* 2> /dev/null #fresh start
touch /tmp/gwr/tell_root 2> /dev/null #set it up for now

## pre-run checks
echo "Starting prerun checks..."
check_ms=1
until [ $check_ms = 0 ]; do
  monitor-sensor --accel | stdbuf -oL grep orientation > /tmp/gwr/device_rotation 2>&1 &
  check_ms=$?
  sleep 1
done
echo "Monitoring rotation status via monitor-sensor."
sleep 1 #let files populate

## disable default rotation stuff
auto_rot=$(gsettings get org.gnome.settings-daemon.peripherals.touchscreen orientation-lock)
if [ "$auto_rot" = "false" ]; then
    gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock true
    echo "- GNOME Auto-Rotate locked. To re-enable, run:"
    echo "  gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock false"
fi

## Polling is expensive. Let us use inotify.
echo "Main loop started in background."
(
  inotifywait --monitor --format "%e %w%f" --event modify,create /tmp/gwr/ --include '(device_rotation|manual)' | while read changed; do
    rot_map #if we see changes, run the rotation meta thing
  done
) &
echo "inotify is ready. gdbus monitoring is starting."
(
way_last=false #have a way to toggle between the rotation types
gdbus monitor --session --dest org.gnome.Shell | while read -r line; do #read from Window Monitor Pro
  if grep_check "$line" "WindowFocusChanged"; then
    if grep_check "$line" "'Waydroid'"; then
      if [[ $debug_mode == 1 ]]; then
        echo " - Waydroid focused"
      fi
      way_last=true
      this_rot="$(cat /tmp/gwr/device_rotation | grep 'orientation changed:' | tail -n1)"
      rot_map "$this_rot"
      rot_map "$this_rot" #second time triggers waydroid rotation
    else
      if $way_last; then
        if [[ $debug_mode == 1 ]]; then
          echo " - Waydroid not focused"
        fi
        rot_map "$(cat /tmp/gwr/device_rotation | grep 'orientation changed:' | tail -n1)"
      fi
      way_last=false
    fi
  fi
done
) &

wait