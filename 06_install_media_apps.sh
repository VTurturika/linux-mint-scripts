#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🚀 Starting classroom multimedia software deployment check..."

# 1. Define the target multimedia applications
APPS=(
    "openshot-qt"
    "gimp"
    "inkscape"
    "simplescreenrecorder"
    "vlc"
    "handbrake"
    "mediainfo"
    "mediainfo-gui"
)

# 2. Check for missing applications
MISSING_APPS=()
for app in "${APPS[@]}"; do
    if ! dpkg -l | grep -q "^ii  $app "; then
        MISSING_APPS+=("$app")
    fi
done

# 3. Check if repository Blender is still present
REPO_BLENDER_PRESENT=false
if dpkg -l | grep -q "^ii  blender "; then
    REPO_BLENDER_PRESENT=true
fi

# 4. Idempotency Evaluation: Skip if everything matches the desired state
if [ ${#MISSING_APPS[@]} -eq 0 ] && [ "$REPO_BLENDER_PRESENT" = false ]; then
    echo "All multimedia applications are already installed."
    echo "Stock repository Blender is already uninstalled."
    echo "✅ System state is perfect. No changes needed."
    exit 0
fi

# 5. Remove repository Blender if it exists
if [ "$REPO_BLENDER_PRESENT" = true ]; then
    echo "🧹 Removing stock repository Blender to prevent conflicts with legacy 2.76b..."
    apt remove -y blender
    echo "✅ Stock Blender removed."
fi

# 6. Install missing applications
if [ ${#MISSING_APPS[@]} -gt 0 ]; then
    echo "⏳ Missing packages detected: ${MISSING_APPS[*]}"
    echo "🔄 Refreshing package lists..."
    apt update

    echo "📦 Installing missing multimedia applications..."
    apt install -y "${MISSING_APPS[@]}"
    echo "✅ All packages installed successfully."
fi

# 7. Clean up orphaned dependencies
echo "🧹 Performing automated system cleanup of unused packages..."
apt autoremove -y

echo "🎉 All done! The multimedia suite is completely configured and ready for students."
