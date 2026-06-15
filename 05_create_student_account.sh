#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e 

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

USERNAME="student"
FULL_NAME="Учень"
LIGHTDM_CONF_DIR="/etc/lightdm/lightdm.conf.d"

echo "🚀 Starting student account deployment configuration..."

# 1. Idempotent User Creation Check
if id "$USERNAME" &>/dev/null; then
    echo "ℹ️ User '$USERNAME' already exists. Ensuring password remains cleared..."
    passwd -d "$USERNAME"
else
    echo "⏳ Creating passwordless user account: $USERNAME ($FULL_NAME)..."
    adduser --disabled-password --gecos "$FULL_NAME,,," "$USERNAME"
    passwd -d "$USERNAME"
    echo "✅ Account created successfully."
fi

# 2. Configure PAM to allow empty password logins locally
echo "🔐 Verifying PAM configuration for empty passwords..."
PAM_FILE="/etc/pam.d/common-auth"

if grep -q "pam_unix.so.*nullok_secure" "$PAM_FILE"; then
    echo "⏳ Modifying PAM rules (converting nullok_secure to nullok)..."
    sed -i 's/pam_unix.so nullok_secure/pam_unix.so nullok/' "$PAM_FILE"
    echo "✅ PAM restrictions lifted for local empty passwords."
elif grep -q "pam_unix.so" "$PAM_FILE" && ! grep -q "nullok" "$PAM_FILE"; then
    echo "⏳ Modifying PAM rules (injecting nullok variable)..."
    sed -i 's/pam_unix.so/pam_unix.so nullok/' "$PAM_FILE"
    echo "✅ PAM configuration updated."
else
    echo "ℹ️ PAM configuration is already cleared to accept blank passwords."
fi

# 3. Configure LightDM Autologin for Linux Mint
echo "🖥️ Configuring LightDM desktop automatic login..."
mkdir -p "$LIGHTDM_CONF_DIR"

# Write the modular configuration file (overwrites cleanly if re-run)
cat <<EOF > "$LIGHTDM_CONF_DIR/10-student-autologin.conf"
[Seat:*]
autologin-user=$USERNAME
autologin-user-timeout=0
autologin-session=cinnamon
EOF

echo "✅ LightDM mapped to boot '$USERNAME' straight into Cinnamon."
echo "🎉 All done! Next boot will automatically login to the student profile."
