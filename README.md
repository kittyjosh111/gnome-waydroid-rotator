# gnome-waydroid-rotator

## installation:

1) Use GNOME. I've only tested this on Wayland, but if you're on X11 then waydroid won't work natively so...

2) Disable GNOME's built-in rotation. I'm not too sure how to do this, but I used the extension Screen Rotate and disabled roatation and it seemed to work.

3) Install ```inotify-tools``` with your package manager.

4) Install the ```Window Monitor Pro``` extension. [Source code here](https://github.com/dev-muhammad-adel/window-calls-extended).

5) Move ```gnome-waydroid-rotator_root.sh``` and ```gnome-waydroid-rotator_user.sh``` to /usr/local/bin. Make them executable.

6) Move ```gnome-waydroid-rotator_root.service``` to /etc/systemd/system/. Enable and start it with systemctl via ```sudo systemctl enable --now gnom-waydroid-rotator_root```.

7) Move ```gnome-waydroid-rotator_user.service``` to ~/.config/systemd/user/. Enable and start it with systemctl via ```systemctl --user enable --now gnome-waydroid-rotator_user```.

**This script was only tested on Wayland GNOME**

## setup:

1) Open ```gnome-waydroid-rotator_user.sh``` and read through the comments and variables in the beginning. Set them to your own device's parameters.

2) Run ```gnome-waydroid-rotator_user.sh``` as user, not root.

## usage:

1) To lock rotation, create a file ```/tmp/gnome-waydroid-rotator.lock```. To disable locks, remove that file.

## background:

yippee!
