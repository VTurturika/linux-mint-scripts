#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🚀 Starting Visual Studio Code installation check..."

# 1. Check if VS Code (package name 'code') is already installed
if dpkg -l | grep -q "^ii  code "; then
    echo "ℹ️ Visual Studio Code is already installed on this system."
    echo "✅ No changes needed."
    exit 0
fi

# 2. Set up environment variables
DEST_FOLDER="/home/teacher/Завантаження"
DEST_FILE="vs-code-1.85.2.deb"

# Ensure the target directory exists just in case
mkdir -p "$DEST_FOLDER"

echo "⏳ Downloading VS Code version 1.85.2 from official servers..."
# Added -L to follow Microsoft's CDN server redirects cleanly
wget -q --show-progress -L "https://update.code.visualstudio.com/1.85.2/linux-deb-x64/stable" -O "$DEST_FOLDER/$DEST_FILE"

echo "📦 Installing Visual Studio Code and resolving dependencies..."
# 'apt install' is safer than 'dpkg -i' because it automatically pulls missing libraries
apt install -y "$DEST_FOLDER/$DEST_FILE"

echo "🧹 Cleaning up installation files..."
rm -f "$DEST_FOLDER/$DEST_FILE"

echo "🎉 All done! Visual Studio Code 1.85.2 has been successfully installed."
