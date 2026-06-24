#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🔄 Starting Veyon Complete Uninstallation & System Rollback..."

# -------------------------------------------------------------------------
# STEP 1: Revert systemd Service State
# -------------------------------------------------------------------------
SVC="veyon"
echo "🔓 Restoring systemd service state..."
systemctl unmask "$SVC" &>/dev/null || true
systemctl stop "$SVC" &>/dev/null || true
systemctl disable "$SVC" &>/dev/null || true

# -------------------------------------------------------------------------
# STEP 2: Purge Veyon Binaries and Core Configurations
# -------------------------------------------------------------------------
echo "🗑️ Purging Veyon package..."
if dpkg -s veyon &>/dev/null; then
    apt-get purge -y veyon
    apt-get autoremove -y
    echo "   ✅ Veyon binaries and base packages removed."
else
    echo "   ℹ️ Veyon package is not installed."
fi

# -------------------------------------------------------------------------
# STEP 3: Erase Custom Authentication Keys & Config Residue
# -------------------------------------------------------------------------
echo "🧹 Cleaning up configuration directories..."
if [ -d "/etc/veyon" ]; then
    rm -rf /etc/veyon
    echo "   ✅ Removed /etc/veyon/ directory."
else
    echo "   ℹ️ No configuration directory found at /etc/veyon."
fi

# -------------------------------------------------------------------------
# STEP 4: Remove User-Space Autostart Shortcuts
# -------------------------------------------------------------------------
AUTOSTART_FILE="/etc/xdg/autostart/veyon-user-server.desktop"
echo "📂 Removing user-space desktop autostart hooks..."
if [ -f "$AUTOSTART_FILE" ]; then
    rm -f "$AUTOSTART_FILE"
    echo "   ✅ Global autostart launcher deleted."
else
    echo "   ℹ️ No autostart launcher found at $AUTOSTART_FILE."
fi

# -------------------------------------------------------------------------
# STEP 5: Revert Wake-on-LAN (WoL) Configurations
# -------------------------------------------------------------------------
echo "🌐 Reverting Wake-on-LAN (WoL) configuration to system defaults..."
WIRED_CONNS=$(nmcli -t -f TYPE,NAME connection show | grep "802-3-ethernet" | cut -d: -f2 || true)

if [ -n "$WIRED_CONNS" ]; then
    echo "$WIRED_CONNS" | while read -r CONN_NAME; do
        if [ -n "$CONN_NAME" ]; then
            echo "   🔄 Resetting WoL parameters on profile: [$CONN_NAME] to default..."
            nmcli connection modify "$CONN_NAME" 802-3-ethernet.wake-on-lan default
            nmcli connection up "$CONN_NAME" &>/dev/null || true
        fi
    done
    echo "   ✅ All NetworkManager profiles safely restored to system network defaults."
else
    echo "   ℹ️ No wired network profiles discovered to revert."
fi

echo "🎉 Rollback complete! The system has been cleanly reverted to its original state."