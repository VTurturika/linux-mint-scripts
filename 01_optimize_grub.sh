#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🚀 Starting GRUB customization..."

# 1. Move Windows entry to the first place (Priority 09)
if [ -f /etc/grub.d/30_os-prober ]; then
    echo "📦 Moving Windows (os-prober) to the top priority position..."
    mv /etc/grub.d/30_os-prober /etc/grub.d/09_os-prober
    echo "✅ Windows moved to position 09."
elif [ -f /etc/grub.d/09_os-prober ]; then
    echo "ℹ️ Windows (os-prober) is already at the top position (09)."
else
    echo "⚠️ Warning: os-prober script not found in /etc/grub.d/"
fi


# 2. Change the GRUB timeout to 10 seconds
GRUB_CONFIG="/etc/default/grub"
if [ -f "$GRUB_CONFIG" ]; then
    echo "⏳ Setting GRUB boot timeout to 10 seconds..."
    # Use sed to find GRUB_TIMEOUT and replace the entire line
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' "$GRUB_CONFIG"
    echo "✅ Timeout updated in /etc/default/grub."
else
    echo "❌ Error: /etc/default/grub configuration file not found!"
    exit 1
fi

# 3. Apply changes to the active bootloader
echo "🔄 Compiling changes and updating GRUB..."

update-grub

echo "🎉 All done!"

