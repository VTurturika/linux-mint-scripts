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

echo "📂 Starting selective GTK/Nautilus Sidebar Bookmark update..."

update_bookmarks_file() {
    local TARGET_USER=$1
    local IS_TEACHER=$2
    local USER_HOME="/home/$TARGET_USER"
    local BOOKMARKS_DIR="$USER_HOME/.config/gtk-3.0"
    local BOOKMARKS_FILE="$BOOKMARKS_DIR/bookmarks"
    local TEMP_FILE="/tmp/bookmarks_${TARGET_USER}.tmp"

    # Ensure configuration path exists
    mkdir -p "$BOOKMARKS_DIR"
    touch "$BOOKMARKS_FILE"

    # 1. Read existing file and strip out ONLY our lab-specific drive paths
    # This prevents duplicates and preserves all default/pre-existing user bookmarks
    grep -E -v '^file:///mnt/(c|d)-drive' "$BOOKMARKS_FILE" > "$TEMP_FILE" || true

    # Define the custom paths we need to append
    local CORE_BOOKMARKS=(
        "/mnt/c-drive|Локальний диск C:"
        "/mnt/d-drive|Локальний диск D:"
        "/mnt/d-drive/Спільне|Спільне"
    )

    if [ "$IS_TEACHER" = true ]; then
        CORE_BOOKMARKS+=(
            "/mnt/d-drive/Вчитель|Вчитель"
            "/mnt/d-drive/Учень|Учень"
        )
    fi

    # Append core lab bookmarks
    for item in "${CORE_BOOKMARKS[@]}"; do
        IFS="|" read -r path title <<< "$item"
        local ENCODED_URI=$(python3 -c "import urllib.parse; print('file://' + urllib.parse.quote('''$path''', safe='/'))")
        echo "$ENCODED_URI $title" >> "$TEMP_FILE"
    done

    # Append grades 5 through 11
    for grade in {5..11}; do
        local GRADE_PATH="/mnt/d-drive/${grade} клас"
        local GRADE_TITLE="${grade} клас"
        local ENCODED_URI=$(python3 -c "import urllib.parse; print('file://' + urllib.parse.quote('''$GRADE_PATH''', safe='/'))")
        echo "$ENCODED_URI $GRADE_TITLE" >> "$TEMP_FILE"
    done

    # 2. Safely swap the updated layout back into place
    mv "$TEMP_FILE" "$BOOKMARKS_FILE"

    # Set proper user ownership configurations (Surgically isolated to gtk-3.0)
    chown -R "$TARGET_USER":"$TARGET_USER" "$BOOKMARKS_DIR"
    chmod 755 "$BOOKMARKS_DIR"
    chmod 644 "$BOOKMARKS_FILE"
    
    echo "   ✅ Sidebars updated safely for user: [$TARGET_USER]"
}

# Run for Student Account
if id "$STUDENT_USER" &>/dev/null; then
    update_bookmarks_file "$STUDENT_USER" false
else
    echo "   ℹ️ Profile '$STUDENT_USER' not present. Skipping."
fi

# Run for Teacher Account
if id "$TEACHER_USER" &>/dev/null; then
    update_bookmarks_file "$TEACHER_USER" true
else
    echo "   ℹ️ Profile '$TEACHER_USER' not present. Skipping."
fi

echo "🎉 New lab bookmarks appended while preserving all existing default system locations!"