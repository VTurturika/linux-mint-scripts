#!/bin/bash

# 1. Completely mask the background system service (Bluetooth hardware)
echo "Masking Bluetooth system daemon..."
sudo systemctl stop bluetooth
sudo systemctl disable bluetooth
sudo systemctl mask bluetooth

# 2. Block the Bluetooth tray applet from launching
if [ -f /etc/xdg/autostart/blueman.desktop ]; then
    echo -e "Hidden=true\nX-GNOME-Autostart-enabled=false" | sudo tee -a /etc/xdg/autostart/blueman.desktop
fi

# 3. Block Update Manager (Менеджер оновлень)
if [ -f /etc/xdg/autostart/mintupdate.desktop ]; then
    echo -e "Hidden=true\nX-GNOME-Autostart-enabled=false" | sudo tee -a /etc/xdg/autostart/mintupdate.desktop
fi

# 4. Block System Reports (Звіти про систему)
if [ -f /etc/xdg/autostart/mintreport.desktop ]; then
    echo -e "Hidden=true\nX-GNOME-Autostart-enabled=false" | sudo tee -a /etc/xdg/autostart/mintreport.desktop
fi

echo "Done! They are completely disabled globally for all users."