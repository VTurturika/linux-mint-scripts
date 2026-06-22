#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🚀 Starting native UI desktop shortcut copy and interface configuration..."

# 1. Define the target lab accounts
ACCOUNTS=("teacher" "student")

# 2. Define the exact classroom application shortcuts
APPS=(
    "firefox.desktop"
    "google-chrome.desktop"
    "libreoffice-writer.desktop"
    "libreoffice-calc.desktop"
    "libreoffice-impress.desktop"
    "libreoffice-base.desktop"
    "code.desktop"
    "gimp.desktop"
    "org.inkscape.Inkscape.desktop"
    "blender2.76b.desktop"
    "fr.handbrake.ghb.desktop"
    "simplescreenrecorder.desktop"
    "org.openshot.OpenShot.desktop"
)

APPLICATIONS_PATH="/usr/share/applications"

# 3. Deploy Shortcuts, Permissions, and Launch Trusts for Each User
for ACC in "${ACCOUNTS[@]}"; do
    # Verify if the user account actually exists on this machine
    if id "$ACC" &>/dev/null; then
        echo "👤 Processing desktop environment for user: [$ACC]"
        
        # Get the User ID to target their active graphical runtime session cleanly
        USER_ID=$(id -u "$ACC")
        ENV_ARGS=(XDG_RUNTIME_DIR="/run/user/$USER_ID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus")

        # Detect the localized Desktop directory (handles 'Стільниця' or fallback 'Desktop')
        if [ -d "/home/$ACC/Стільниця" ]; then
            DESTINATION="/home/$ACC/Стільниця"
        elif [ -d "/home/$ACC/Desktop" ]; then
            DESTINATION="/home/$ACC/Desktop"
        else
            # Default to Ukrainian layout if not yet initialized by the system
            DESTINATION="/home/$ACC/Стільниця"
            mkdir -p "$DESTINATION"
        fi

        # Copy shortcuts and apply UI-native trust metadata
        for app in "${APPS[@]}"; do
            if [ -f "$APPLICATIONS_PATH/$app" ]; then
                TARGET_SHORTCUT="$DESTINATION/$app"
                
                # Check if the shortcut destination already exists
                if [ -f "$TARGET_SHORTCUT" ]; then
                    echo "   ℹ️ Shortcut '$app' already exists as a physical file. Skipping."
                else
                    echo "   ➕ Copying UI-native launcher: $app -> $DESTINATION"
                    
                    # Copy the absolute file instead of using a symbolic link
                    cp "$APPLICATIONS_PATH/$app" "$TARGET_SHORTCUT"
                    
                    # Replicate exact UI behavior: Apply execution bits and owner access
                    chmod +x "$TARGET_SHORTCUT"
                    chown "$ACC:$ACC" "$TARGET_SHORTCUT"
                    
                    # Force the system to trust the file (bypasses the "Untrusted Launcher" modal)
                    sudo -u "$ACC" "${ENV_ARGS[@]}" gio set "$TARGET_SHORTCUT" "metadata::trusted" "true" 2>/dev/null || true
                fi
            else
                echo "   ⚠️ Warning: Source system file '$app' not found. Skipping."
            fi
        done

        # Re-verify absolute user ownership across the entire directory structure
        chown -R "$ACC:$ACC" "$DESTINATION"
        
        # 4. Immediate Live Layout Injection (Fixes Home & Trash visibility for active users)
        echo "   🖥️ Injecting Nemo layout preferences into active profile registry..."
        sudo -u "$ACC" "${ENV_ARGS[@]}" gsettings set org.nemo.desktop show-desktop-icons true 2>/dev/null || true
        sudo -u "$ACC" "${ENV_ARGS[@]}" gsettings set org.nemo.desktop home-icon-visible true 2>/dev/null || true
        sudo -u "$ACC" "${ENV_ARGS[@]}" gsettings set org.nemo.desktop trash-icon-visible true 2>/dev/null || true
        
        echo "✅ Shortcuts and environment configured successfully for $ACC."
    else
        echo "ℹ️ Profile [$ACC] does not exist on this specific machine. Skipping layout sync."
    fi
done

# 5. Global Policy Fallback Strategy (Ensures new accounts inherit these settings automatically)
echo "📂 Compiling master fallback environment policy schema..."

cat << 'EOF' > /usr/share/glib-2.0/schemas/99_classroom_desktop.gschema.override
[org.nemo.desktop]
show-desktop-icons=true
home-icon-visible=true
trash-icon-visible=true
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas

echo "🎉 Layout sync complete! Launchers copied cleanly and desktop system icons are fully visible."
