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

echo "🚀 Starting automated XRDP Remote Desktop configuration..."

# 1. Update package lists and install XRDP server
echo "📦 Installing XRDP server components..."
apt update
apt install xrdp -y

# 2. Add xrdp to the ssl-cert group for system security certificate access
echo "🔐 Configuring certificate security mappings..."
if getent group ssl-cert >/dev/null; then
    adduser xrdp ssl-cert
    echo "   ✅ Added xrdp user to ssl-cert group."
else
    echo "   ⚠️ Warning: ssl-cert group not found. Skipping mapping."
fi

# 3. Configure session hooks for user profiles to fix the black screen bug
configure_user_session() {
    local TARGET_USER=$1
    local USER_HOME="/home/$TARGET_USER"
    local XSESSION_FILE="$USER_HOME/.xsession"

    echo "   🖥️ Provisioning Cinnamon window manager hook for [$TARGET_USER]..."
    echo "cinnamon-session" > "$XSESSION_FILE"
    
    # Crucial step: Fix ownership since script runs as root
    chown "$TARGET_USER":"$TARGET_USER" "$XSESSION_FILE"
    chmod 644 "$XSESSION_FILE"
}

echo "👤 Processing local user profile sessions..."
if id "$STUDENT_USER" &>/dev/null; then
    configure_user_session "$STUDENT_USER"
else
    echo "   ℹ️ Profile '$STUDENT_USER' not present. Skipping."
fi

if id "$TEACHER_USER" &>/dev/null; then
    configure_user_session "$TEACHER_USER"
else
    echo "   ℹ️ Profile '$TEACHER_USER' not present. Skipping."
fi

# 4. Enable and restart the system service
echo "🔄 Activating and verifying background service daemons..."
systemctl daemon-reload
systemctl enable xrdp
systemctl restart xrdp

echo "🎉 XRDP Setup complete! Workstation is ready for network deployments."