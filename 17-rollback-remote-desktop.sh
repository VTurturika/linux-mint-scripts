#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

TEACHER_USER="teacher"
STUDENT_USER="student"

echo "🔄 Initializing XRDP Remote Desktop Rollback..."

# 1. Stop and disable XRDP services safely
echo "🛑 Stopping and disabling active XRDP services..."
systemctl stop xrdp 2>/dev/null || true
systemctl disable xrdp 2>/dev/null || true

# 2. Purge the package and completely remove its configurations
echo "🗑️ Purging XRDP package and cleaning up system dependencies..."
apt purge -y xrdp
apt autoremove -y

# 3. Clean up the .xsession graphical environment hooks
clean_xsession() {
    local TARGET_USER=$1
    local USER_HOME="/home/$TARGET_USER"
    local XSESSION_FILE="$USER_HOME/.xsession"

    if [ -f "$XSESSION_FILE" ]; then
        # Check if it was our custom desktop hook, then remove it
        if grep -q "cinnamon-session" "$XSESSION_FILE"; then
            rm -f "$XSESSION_FILE"
            echo "   🧹 Removed RDP desktop hook (.xsession) for [$TARGET_USER]."
        else
            echo "   ℹ️ Custom .xsession found for [$TARGET_USER] but it contains other configurations. Skipping file removal."
        fi
    fi
}

echo "👤 Cleaning up user profile configurations..."
id "$STUDENT_USER" &>/dev/null && clean_xsession "$STUDENT_USER" || true
id "$TEACHER_USER" &>/dev/null && clean_xsession "$TEACHER_USER" || true

echo "🎉 Rollback complete! XRDP has been completely removed and the system is back to its original state."