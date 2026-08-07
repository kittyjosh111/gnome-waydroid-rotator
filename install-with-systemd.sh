#!/bin/bash
echo "Installing scripts..."
sudo cp gnome-waydroid-rotator-ctrl /usr/local/bin
sudo cp gnome-waydroid-rotator_root.sh /usr/local/bin/
sudo cp gnome-waydroid-rotator_user.sh /usr/local/bin/
echo "Installing systemd files..."
mkdir -p ~/.config/systemd/user
cp systemd/gnome-waydroid-rotator_user.service ~/.config/systemd/user/
systemctl --user daemon-reload
sudo cp systemd/gnome-waydroid-rotator_root.service /etc/systemd/system/
sudo systemctl daemon-reload
echo "Enabling and starting systemd..."
systemctl --user enable --now gnome-waydroid-rotator_user.service
sudo systemctl enable --now gnome-waydroid-rotator_root.service
echo "Done installing."
