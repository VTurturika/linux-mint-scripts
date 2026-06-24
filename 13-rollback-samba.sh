#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

TEACHER_USER="teacher"
STUDENT_USER="student"
SMB_CONF="/etc/samba/smb.conf"

echo "🗑️ Starting targeted Samba classroom removal..."

echo "🛑 Terminating background processes..."
systemctl stop smbd &>/dev/null || true
systemctl disable smbd &>/dev/null || true

echo "📦 Removing network packages..."
apt-get purge -y samba samba-common-bin wsdd
apt-get autoremove -y

if [ -f "${SMB_CONF}.bak" ]; then
    mv "${SMB_CONF}.bak" "$SMB_CONF"
    echo "   ⏪ Original smb.conf state restored."
else
    rm -f "$SMB_CONF"
fi

echo "🔒 Re-locking home folder traversal parameters..."
id "$TEACHER_USER" &>/dev/null && chmod o-x "/home/$TEACHER_USER" || true
id "$STUDENT_USER" &>/dev/null && chmod o-x "/home/$STUDENT_USER" || true

echo "🎉 System rolled back successfully!"