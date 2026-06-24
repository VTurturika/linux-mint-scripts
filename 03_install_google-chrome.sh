#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🚀 Starting Google Chrome installation check..."

# 1. Check if Google Chrome is already installed
if dpkg -l | grep -q "^ii  google-chrome-stable"; then
    echo "ℹ️ Google Chrome is already installed on this system."
    echo "✅ The official Google repository is active. Future updates will happen automatically via standard system upgrades."
    echo "🎉 No changes needed."
    exit 0
fi

# 2. Set up variables (Using system temporary directory)
DEST_FOLDER="/tmp"
DEST_FILE="google-chrome-stable_current_amd64.deb"

# Ensure the target directory exists just in case
mkdir -p "$DEST_FOLDER"

echo "⏳ Downloading the latest Google Chrome package from Google servers..."
wget -q --show-progress https://dl.google.com/linux/direct/$DEST_FILE -O "$DEST_FOLDER/$DEST_FILE"

echo "📦 Installing Google Chrome and auto-resolving dependencies..."
# 'apt install' is safer than 'dpkg -i' because it automatically pulls missing libraries
apt install -y "$DEST_FOLDER/$DEST_FILE"

echo "🧹 Cleaning up installation files..."
rm -f "$DEST_FOLDER/$DEST_FILE"

echo "🎉 All done! Google Chrome has been successfully installed and configured."