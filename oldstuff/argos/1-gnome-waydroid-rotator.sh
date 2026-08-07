#!/bin/bash
# Link to Argos: https://github.com/p-e-w/argos

# The font sizes for the display in Argos' menu.
argos_font=11
header_font=13

# The text displayed in the top bar
top_bar_text="⟳"

######################################################################
## DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ##
######################################################################

echo $top_bar_text
echo "---"
echo "Quick Controls:|size=$header_font"
echo "Lock Rotation|iconName=rotation-locked-symbolic size=$argos_font bash='gnome-waydroid-rotator-ctrl --lock' terminal=false"
echo "Automatic Rotation|iconName=rotation-allowed-symbolic size=$argos_font bash='gnome-waydroid-rotator-ctrl --auto' terminal=false"
echo "---"
echo "Manual Rotation:|size=$header_font"
echo "Rotate Clockwise|iconName=object-rotate-right-symbolic size=$argos_font bash='gnome-waydroid-rotator-ctrl -cw' terminal=false"
echo "Rotate Counterclockwise|iconName=object-rotate-left-symbolic size=$argos_font bash='gnome-waydroid-rotator-ctrl -ccw' terminal=false"
echo "---"
echo "Restart Service|iconName=system-run-symbolic size=$argos_font bash='systemctl --user restart gnome-waydroid-rotator_user.service' terminal=false"
