#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

# -------------------------------------------------------------------------
# DYNAMIC ENVIRONMENT & USER CONFIGURATION
# -------------------------------------------------------------------------
# Automatically fetch and uppercase the machine's local hostname
HOST_PREFIX=$(hostname | tr '[:lower:]' '[:upper:]')

TEACHER_USER="teacher"
STUDENT_USER="student"

# Output share names incorporating the requested structure
SHARE_TEACHER="${HOST_PREFIX}-Вчитель-Загальне"
SHARE_STUDENT="${HOST_PREFIX}-Учень-Загальне"
SHARE_WINDOWS="${HOST_PREFIX}-Спільне"

PATH_TEACHER="/home/$TEACHER_USER/Загальне"
PATH_STUDENT="/home/$STUDENT_USER/Загальне"
PATH_WINDOWS="/mnt/d-drive/Спільне"

echo "🔄 Starting Dynamic Hostname-Based Samba Deployment..."
echo "🖥️  Detected Host Prefix: $HOST_PREFIX"

# -------------------------------------------------------------------------
# STEP 1: Verify & Create Folder Architectures
# -------------------------------------------------------------------------
echo "📂 Provisioning local folder structures and permissions..."

# Process Teacher Account
if ! id "$TEACHER_USER" &>/dev/null; then
    echo "   👤 Creating local '$TEACHER_USER' account..."
    useradd -m -s /bin/bash "$TEACHER_USER" || true
fi
mkdir -p "$PATH_TEACHER"
chown -R "$TEACHER_USER":"$TEACHER_USER" "$PATH_TEACHER"
chmod 775 "$PATH_TEACHER"
chmod o+x "/home/$TEACHER_USER" # Break the home traversal lock

# Process Student Account
if ! id "$STUDENT_USER" &>/dev/null; then
    echo "   👤 Creating local '$STUDENT_USER' account..."
    useradd -m -s /bin/bash "$STUDENT_USER" || true
fi
mkdir -p "$PATH_STUDENT"
chown -R "$STUDENT_USER":"$STUDENT_USER" "$PATH_STUDENT"
chmod 775 "$PATH_STUDENT"
chmod o+x "/home/$STUDENT_USER" # Break the home traversal lock

echo "   ✅ Linux local home paths optimized."

# -------------------------------------------------------------------------
# STEP 2: Clean Install Samba Package Environment
# -------------------------------------------------------------------------
echo "📥 Installing Samba tools..."
apt-get update -qq
apt-get install -y samba samba-common-bin wsdd

# -------------------------------------------------------------------------
# STEP 3: Structural smb.conf Architecture Compilation
# -------------------------------------------------------------------------
SMB_CONF="/etc/samba/smb.conf"

if [ ! -f "${SMB_CONF}.bak" ]; then
    cp "$SMB_CONF" "${SMB_CONF}.bak"
fi

# Apply general open public mapping parameter
if ! grep -q "map to guest" "$SMB_CONF"; then
    sed -i '/\[global\]/a \   map to guest = bad user' "$SMB_CONF"
fi

# Clear out potential duplicates from previous tests dynamically
sed -i "/\[$SHARE_TEACHER\]/,/^$/d" "$SMB_CONF"
sed -i "/\[$SHARE_STUDENT\]/,/^$/d" "$SMB_CONF"
sed -i "/\[$SHARE_WINDOWS\]/,/^$/d" "$SMB_CONF"

echo "🔧 Injecting network sharing parameters into configuration..."

# Append Teacher Share Block
cat << EOF >> "$SMB_CONF"

[$SHARE_TEACHER]
   comment = Teacher Public Space
   path = $PATH_TEACHER
   browseable = yes
   read only = no
   guest ok = yes
   public = yes
   force user = $TEACHER_USER
   create mask = 0664
   directory mask = 0775

[$SHARE_STUDENT]
   comment = Student Workspace Storage
   path = $PATH_STUDENT
   browseable = yes
   read only = no
   guest ok = yes
   public = yes
   force user = $STUDENT_USER
   create mask = 0664
   directory mask = 0775
EOF

# Append Windows Partition Share Block if mounted
if [ -d "$PATH_WINDOWS" ]; then
    echo "   📦 Windows partition folder discovered at $PATH_WINDOWS. Mapping share..."
    cat << EOF >> "$SMB_CONF"

[$SHARE_WINDOWS]
   comment = Shared Dual-Boot Windows Partition Data
   path = $PATH_WINDOWS
   browseable = yes
   read only = no
   guest ok = yes
   public = yes
   force user = $TEACHER_USER
   create mask = 0666
   directory mask = 0777
EOF
else
    echo "   ℹ️ Windows partition folder missing or not mounted at $PATH_WINDOWS. Skipping."
fi

# -------------------------------------------------------------------------
# STEP 4: Kickstart Daemons
# -------------------------------------------------------------------------
echo "🚀 Initializing network sharing daemons..."
systemctl restart smbd
systemctl enable smbd

echo "🎉 Deployment pipeline successfully finished! Shares are live on the network."