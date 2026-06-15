#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🚀 Starting Blender 2.76b legacy installation check..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define operational paths
TARGET_DIR="/opt/blender-2.76b"
DESKTOP_ENTRY="/usr/share/applications/blender2.76b.desktop"
RESOURCE_FILE="$SCRIPT_DIR/resources/blender2.76b.desktop"

# 1. Idempotency Check: Skip completely if already done
if [ -x "$TARGET_DIR/blender" ] && [ -f "$DESKTOP_ENTRY" ]; then
    echo "ℹ️ Blender 2.76b is already installed and configured in system menus."
    echo "✅ No changes needed. Skipping download and installation steps."
    exit 0
fi

# 2. Check for the desktop resource file before doing heavy downloads
if [ ! -f "$RESOURCE_FILE" ]; then
    echo "❌ Error: Could not find '$RESOURCE_FILE'."
    echo "   Please make sure the 'resources' folder exists next to this script and contains 'blender2.76b.desktop'."
    exit 1
fi

# 3. Setup download variables
DEST_FOLDER="/home/teacher/Завантаження"
DEST_NAME="blender-2.76b-linux-glibc211-x86_64"
DEST_FILE="$DEST_NAME.tar.bz2"

# Ensure download destination directory exists
mkdir -p "$DEST_FOLDER"

# 4. Download and extract binaries if missing
if [ ! -x "$TARGET_DIR/blender" ]; then
    echo "⏳ Downloading Blender 2.76b tarball..."
    wget -q --show-progress "https://download.blender.org/release/Blender2.76/$DEST_FILE" -O "$DEST_FOLDER/$DEST_FILE"

    echo "📦 Extracting package directly to /opt/..."
    tar -xjf "$DEST_FOLDER/$DEST_FILE" -C /opt/

    echo "🔄 Adjusting directory names..."
    rm -rf "$TARGET_DIR" # Clean target if a partial corrupt directory exists
    mv "/opt/$DEST_NAME" "$TARGET_DIR"

    echo "🧹 Cleaning up downloaded archive file..."
    rm -f "$DEST_FOLDER/$DEST_FILE"
else
    echo "ℹ️ Blender core binaries already exist in /opt/. Updating shortcut layouts..."
fi

# 5. Copy desktop shortcut from resource folder
echo "🖥️ Deploying custom desktop shortcut menu entries..."
cp "$RESOURCE_FILE" "$DESKTOP_ENTRY"

# Force standard secure system permissions for layout elements
chown root:root "$DESKTOP_ENTRY"
chmod 644 "$DESKTOP_ENTRY"

# 6. Inject vector graphic layout to native icon registries
if [ -f "$TARGET_DIR/release/freedesktop/icons/scalable/apps/blender.svg" ]; then
    echo "🎨 Registering Blender system vector icon layout..."
    mkdir -p /usr/share/icons/hicolor/scalable/apps/
    cp "$TARGET_DIR/release/freedesktop/icons/scalable/apps/blender.svg" /usr/share/icons/hicolor/scalable/apps/blender.svg
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
fi

echo "🎉 All done! Blender 2.76b has been successfully integrated into LMDE 6 menus."
