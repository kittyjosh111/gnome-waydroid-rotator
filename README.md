# gnome-waydroid-rotator

"Simple" auto-rotation script for GNOME with "support" for Waydroid rotation. If Waydroid is focused, lock GNOME rotation to the *normal* orientation and rotate the Waydroid content only. If Waydroid is not focused, rotate GNOME instead. Supports switching between these rotation schemes on window focus changes.

The base two scripts for rotation do not rely on systemd to function. Thus, it should be possible to write openRC service files for them. However, this repo only provides systemd files.

## installation:

1) Use GNOME. I've only tested this on Wayland, but if you're on X11 then waydroid won't work natively so...

2) Disable GNOME's built-in rotation. I'm not too sure how to do this, but I used the extension ```Screen Rotate``` and disabling roatation using that seemed to work. In any case, make sure not to disable iio-sensor-proxy.

3) Install ```inotify-tools``` with your package manager.

4) Install the ```Window Monitor Pro``` extension. [GNOME extensions](https://extensions.gnome.org/extension/8549/window-monitor-pro/) | [Source code](https://github.com/dev-muhammad-adel/window-calls-extended).

5) Open ```gnome-waydroid-rotator_user.sh``` and read through the comments and variables in the beginning. Ensure your screen orientation is set to normal, then set the variables to your own device's parameters.

6) Move ```gnome-waydroid-rotator_root.sh``` and ```gnome-waydroid-rotator_user.sh``` to /usr/local/bin. Make them executable.

7) If using systemd, go into the folder ```systemctl_services```.

8) Move ```gnome-waydroid-rotator_root.service``` to /etc/systemd/system/. Enable and start it with systemctl via ```sudo systemctl enable --now gnom-waydroid-rotator_root```.

9) Move ```gnome-waydroid-rotator_user.service``` to ~/.config/systemd/user/. Enable and start it with systemctl via ```systemctl --user enable --now gnome-waydroid-rotator_user```.

**This script was only tested on Wayland GNOME on Fedora Workstation**

## usage:

1) Assuming you set up the systemd services correctly, the services should have started automatically and auto-rotation active.

2) If you want to run the scripts without systemd, disable the services. Then, run ```gnome-waydroid-rotator_root.sh``` **as root**, and ```gnome-waydroid-rotator_user.sh``` **as user**.

3) To lock rotation, create a file ```/tmp/gnome-waydroid-rotator.lock```. To disable rotation lock, remove that file.

## background:

[Waydroid](https://waydro.id/) is such a nice program for linux. Years ago when I was still using Arch Linux, I remember installing many Chaotic-AUR packages in an attempt to run Anbox to use the android Kindle app on my laptop for a class. I ended up running android-x86 via QEMU, but one can imagine how troublesome that was to start up and maintain. With the advent of Wayland and Waydroid as a more integrated "android-in-a-box" solution, running android apps on linux has never been easier.

Sometimes though, I had android apps that I wanted to rotate in response to my laptop physically rotating. However, Waydroid to this day [doesn't support](https://github.com/waydroid/waydroid/issues/70) this OOTB. One solution I found earlier was to lock GNOME's rotation and issue the commands ```waydroid shell wm user-rotation lock X``` in response to outputs from ```iio-sensor-proxy```, which was able to rotate Waydroid's content, thus fixing the issue I was having.

Yet sometimes, I still need to rotate GNOME for my other apps such as Xournal++. It thus becomes infeasible to have to manially keep track of GNOME's rotation depending on what I am looking at.

With the help of ```gdctl```, ```monitor-sensor```, and the Window Monitor Pro GNOME extension (here)[https://github.com/dev-muhammad-adel/window-calls-extended], this script is able to automatically tell which window is focused and rotate the screen accordingly. If Waydroid is not focused, rotation works as you would expect, affecting the entire GNOME DE. However, once Waydroid is detected, then GNOME will automatically force the DE to enter the normal orientation (resetting Waydroid's normal dimensions) and begin rotating contents inside of the Waydroid container. Once focus is given back to a non-Waydroid window, the script rotates the GNOME DE for you and ignores Waydroid rotation until the window is focused again.

Keep in mind that the script currently only can detect the main Waydroid window (from waydroid-show-full-ui). It also has a small delay between rotating the screen physically and actually rotating the display contents.

But it works in general, and that's good enough.
