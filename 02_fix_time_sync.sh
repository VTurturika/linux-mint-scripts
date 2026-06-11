#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🚀 Starting hardware clock synchronization fix..."

# Check if Local RTC is already enabled
# timedatectl show outputs "LocalRTC=yes" or "LocalRTC=no"
CURRENT_STATUS=$(timedatectl show --property=LocalRTC)

if [ "$CURRENT_STATUS" = "LocalRTC=yes" ]; then
    echo "ℹ️ System clock is already configured to use Local Time (RTC)."
    echo "✅ No changes needed. Windows and LMDE 6 time zones are synchronized."
else
    echo "⏳ Adjusting hardware clock to interpret Local Time..."
    # Tell Linux to read the hardware clock as local time, matching Windows behavior
    timedatectl set-local-rtc 1 --adjust-system-clock
    echo "✅ Hardware clock successfully updated."
fi

echo "📊 Current System Time Status:"
echo "----------------------------------------"
timedatectl status
echo "----------------------------------------"

echo "🎉 All done! Time synchronization fix complete."

