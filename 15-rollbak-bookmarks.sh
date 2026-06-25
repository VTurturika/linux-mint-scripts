#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

TEACHER_USER="teacher"
STUDENT_USER="student"

clean_user_bookmarks() {
    local TARGET_USER=$1
    local USER_HOME="/home/$TARGET_USER"
    local BOOKMARKS_FILE="$USER_HOME/.config/gtk-3.0/bookmarks"
    local TEMP_FILE="/tmp/bookmarks_cleanup_${TARGET_USER}.tmp"

    if [ -f "$BOOKMARKS_FILE" ]; then
        # Filter out lines starting with file:///mnt/c-drive or file:///mnt/d-drive
        # and keep everything else completely intact
        grep -E -v '^file:///mnt/(c|d)-drive' "$BOOKMARKS_FILE" > "$TEMP_FILE" || true
        
        mv "$TEMP_FILE" "$BOOKMARKS_FILE"
        chown "$TARGET_USER":"$TARGET_USER" "$BOOKMARKS_FILE"
        chmod 644 "$BOOKMARKS_FILE"
        echo "   🗑️ Stripped lab entries from sidebar configuration for [$TARGET_USER]."
    else
        echo "   ℹ️ No custom bookmarks file found for [$TARGET_USER]. Skipping."
    fi
}

echo "🔄 Initializing Surgical Sidebar Bookmarks Rollback..."

id "$STUDENT_USER" &>/dev/null && clean_user_bookmarks "$STUDENT_USER" || true
id "$TEACHER_USER" &>/dev/null && clean_user_bookmarks "$TEACHER_USER" || true

echo "🎉 Lab bookmarks successfully removed. Existing and default bookmarks remain unchanged!"