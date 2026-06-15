#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🚀 Starting Windows partition auto-mount configuration..."

# 1. Define Drive UUIDs 
# (If your classroom machines are exact sector-by-sector disk clones, these UUIDs will be identical across all of them!)
C_DRIVE_UUID=""
D_DRIVE_UUID=""

# Safety Check: Ensure the user filled in the UUID variables
if [ -z "$C_DRIVE_UUID" ] || [ -z "$D_DRIVE_UUID" ]; then
    echo "❌ Error: C_DRIVE_UUID or D_DRIVE_UUID is empty inside this script."
    echo "   Please look at the list below to find your NTFS partition UUIDs and paste them into the script:"
    echo "----------------------------------------------------------------"
    lsblk -o NAME,FSTYPE,UUID,SIZE,MOUNTPOINTS,LABEL | grep -i "ntfs" || echo "⚠️ No NTFS partitions detected!"
    echo "----------------------------------------------------------------"
    exit 1
fi

# 2. Create mounting points (mkdir -p is naturally idempotent)
echo "📂 Verifying mount point directories exist..."
mkdir -p /mnt/c-drive/
mkdir -p /mnt/d-drive/

# 3. Idempotency Check for /etc/fstab
FSTAB_CHANGED=false

echo "📝 Checking filesystem table (/etc/fstab) configuration..."

# Check C Drive
if grep -q "/mnt/c-drive" /etc/fstab; then
    echo "ℹ️ Windows C Drive mount point is already configured in /etc/fstab."
else
    echo "➕ Adding Windows C Drive entry to /etc/fstab..."
    echo "UUID=$C_DRIVE_UUID    /mnt/c-drive/    ntfs-3g    defaults    0    0" >> /etc/fstab
    FSTAB_CHANGED=true
fi

# Check D Drive
if grep -q "/mnt/d-drive" /etc/fstab; then
    echo "ℹ️ Windows D Drive mount point is already configured in /etc/fstab."
else
    echo "➕ Adding Windows D Drive entry to /etc/fstab..."
    echo "UUID=$D_DRIVE_UUID    /mnt/d-drive/    ntfs-3g    defaults    0    0" >> /etc/fstab
    FSTAB_CHANGED=true
fi

# 4. Apply changes instantly if updates were made
if [ "$FSTAB_CHANGED" = true ]; then
    echo "🔄 Refreshing system mount configurations..."
    # Mounts everything listed in fstab instantly without needing a full system reboot
    mount -a
    echo "✅ New partitions mounted successfully."
else
    echo "✅ No changes needed. All partitions are already correctly mapped."
fi

echo "🎉 All done! Windows partitions are completely integrated into the filesystem."