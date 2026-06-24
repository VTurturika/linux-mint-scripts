#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

# Dynamically locate the folder where this script is sitting
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
KEY_DIR="$SCRIPT_DIR/resources/veyon"

DEB_URL="https://github.com/veyon/veyon/releases/download/v4.10.4/veyon_4.10.4.0-debian.12_amd64.deb"
DEB_FILE="veyon_4.10.4.0-debian.12_amd64.deb"

echo "🔄 Starting Dynamic Veyon 4.10.4 Automated Installation & Configuration..."

# -------------------------------------------------------------------------
# STEP 1: Verify Pre-requisites & Key Folder Contents
# -------------------------------------------------------------------------
echo "🔍 Checking for authentication resource folder..."
if [ ! -d "$KEY_DIR" ] || [ -z "$(ls -A "$KEY_DIR"/*.pem 2>/dev/null)" ]; then
  echo "❌ Error: No public key (.pem) files discovered in: $KEY_DIR"
  echo "   Please make sure your public keys are inside the 'resources/veyon/' directory."
  exit 1
fi
echo "   ✅ Found key directory with active public keys."

# -------------------------------------------------------------------------
# STEP 2: Intelligent Download & Clean Installation
# -------------------------------------------------------------------------
echo "📥 Checking system Veyon package version status..."
CURRENT_VER=$(dpkg-query -W -f='${Version}' veyon 2>/dev/null || echo "none")

if [[ "$CURRENT_VER" != "4.10.4"* ]]; then
    echo "   ⚙️ Installing/Upgrading Veyon to version 4.10.4..."
    TEMP_DIR=$(mktemp -d)
    
    echo "   ⬇️ Fetching official release from GitHub..."
    wget -q "$DEB_URL" -O "$TEMP_DIR/$DEB_FILE"
    
    echo "   📦 Installing package and solving system dependencies..."
    apt-get update -qq
    apt-get install -y "$TEMP_DIR/$DEB_FILE"
    
    rm -rf "$TEMP_DIR"
    echo "   ✅ Veyon 4.10.4 installation successfully finished."
else
    echo "   ℹ️ System already running Veyon 4.10.4. Skipping download phase."
fi

# -------------------------------------------------------------------------
# STEP 3: Handle Global Configurations & Multi-Key Loop Imports
# -------------------------------------------------------------------------
echo "🔧 Injecting client security parameters..."

# Temporarily unmask the service so veyon-cli doesn't crash on systemd checks
systemctl unmask veyon &>/dev/null || true

# Temporarily bypass strict script termination so minor environment warnings don't stop execution
set +e

# Explicitly tell Veyon NOT to handle system autostart (aligns it cleanly with user-space)
veyon-cli config set Service/Autostart false

# Set Authentication Method to Key File Authentication (Value 1)
veyon-cli config set Authentication/Method 1

echo "🔑 Scanning and importing keys from resources/veyon..."
for KEY_PATH in "$KEY_DIR"/*.pem; do
    [ -e "$KEY_PATH" ] || continue
    
    FILE_NAME=$(basename "$KEY_PATH")
    BASE_NAME="${FILE_NAME%.pem}"
    
    CLEAN_NAME="${BASE_NAME%_public_key}"
    CLEAN_NAME="${CLEAN_NAME%_public}"
    
    KEY_IDENTIFIER="$CLEAN_NAME/public"
    
    echo "   ➡️ Processing file: $FILE_NAME -> [$KEY_IDENTIFIER]"
    
    veyon-cli authkeys delete "$KEY_IDENTIFIER" &>/dev/null || true
    veyon-cli authkeys import "$KEY_IDENTIFIER" "$KEY_PATH"
done

# Re-engage strict error enforcement for the rest of the script
set -e
echo "   ✅ Configuration changes and key imports processed."

# -------------------------------------------------------------------------
# STEP 4: Force Defang the Root Service Daemon
# -------------------------------------------------------------------------
SVC="veyon"
echo "🛑 Ensuring root systemd background service is decoupled..."

if systemctl is-enabled "$SVC" &>/dev/null || systemctl is-active "$SVC" &>/dev/null; then
    systemctl stop "$SVC" 2>/dev/null || true
    systemctl disable "$SVC" 2>/dev/null || true
fi

# Permanently mask the root system service to keep port 11100 clear
systemctl mask "$SVC" &>/dev/null || true
echo "   🔒 System service masked completely to safeguard port 11100."

# -------------------------------------------------------------------------
# STEP 5: Align Internal Folder Permissions
# -------------------------------------------------------------------------
echo "🔓 Modifying internal file permissions for user-space access..."
if [ -d "/etc/veyon/keys" ]; then
    find /etc/veyon/keys -type d -exec chmod 755 {} +
    find /etc/veyon/keys -type f -exec chmod 644 {} +
    echo "   ✅ Key structures updated successfully."
fi

# -------------------------------------------------------------------------
# STEP 6: Maintain Desktop Workspace Autostart
# -------------------------------------------------------------------------
AUTOSTART_FILE="/etc/xdg/autostart/veyon-user-server.desktop"
echo "📂 Processing session autostart configuration..."

if [ -f "$AUTOSTART_FILE" ]; then
    echo "   ℹ️ Desktop environment hook already built."
else
    echo "   ➕ Constructing user session service launcher..."
    cat << 'EOF' > "$AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Name=Veyon User Session Server
Comment=Launches Veyon inside the active user graphical session
Exec=veyon-server
Terminal=false
Hidden=false
NoDisplay=false
X-GNOME-Autostart-Delay=3
EOF
fi

chown root:root "$AUTOSTART_FILE"
chmod 644 "$AUTOSTART_FILE"

# -------------------------------------------------------------------------
# STEP 7: Dynamic Wake-on-LAN (WoL) Activation
# -------------------------------------------------------------------------
echo "🌐 Configuring Wake-on-LAN (WoL) parameters..."
# Dynamically extract names of all ethernet/wired network profiles via NetworkManager
WIRED_CONNS=$(nmcli -t -f TYPE,NAME connection show | grep "802-3-ethernet" | cut -d: -f2 || true)

if [ -n "$WIRED_CONNS" ]; then
    echo "$WIRED_CONNS" | while read -r CONN_NAME; do
        if [ -n "$CONN_NAME" ]; then
            echo "   ⚡ Injecting Magic Packet rule to connection: [$CONN_NAME]..."
            nmcli connection modify "$CONN_NAME" 802-3-ethernet.wake-on-lan magic
            nmcli connection up "$CONN_NAME" &>/dev/null || true
        fi
    done
    echo "   ✅ NetworkManager profiles modified for WoL orchestration."
else
    echo "   ⚠️ Warning: No wired network connections detected via nmcli. WoL step skipped."
fi

echo "🎉 Deployment pipeline successfully complete! Ready for user login execution."