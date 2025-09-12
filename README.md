# gnome-waydroid-rotator

## installation:

1) Use GNOME. I've only tested this on Wayland, but if you're on X11 then waydroid won't work natively so...

2) Disable automatic rotations. (wait how??)

3) Install ```inotify-tools``` with your package manager.

4) Install the ```Window Monitor Pro``` extension. [Source code here](https://github.com/dev-muhammad-adel/window-calls-extended).

5) Move ```gnome-waydroid-rotator_root.sh``` and ```gnome-waydroid-rotator_user.sh``` to /usr/local/bin. Make it executable.

6) Move ```gnome-waydroid-rotator_root.service``` to /etc/systemd/system/. Enable and start it with systemctl via ```systemctl enable --now gnom-waydroid-rotator_root```.

**This script was only tested on Wayland GNOME**

## setup:

1) Open ```gnome-waydroid-rotator_user.sh``` and read through the comments and variables in the beginning. Set them to your own device's parameters.

2) Run ```gnome-waydroid-rotator_user.sh``` as user, not root.

## background:

yippee!