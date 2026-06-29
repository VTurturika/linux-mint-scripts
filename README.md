# Classroom Lab Automation Suite

Automation scripts to configure and maintain dual-boot client workstations running **LMDE 6** alongside Windows.

## Included scripts

* **01_optimize_grub.sh:** Configures boot menu defaults and timeouts.
* **02_fix_time_sync.sh:** Syncs RTC to LocalTime to stop Windows/Linux clock drift.
* **03_install_google-chrome.sh:** Installs Google Chrome from the official repository.
* **04_install_blender.sh:** Installs Blender and sets up the desktop launcher.
* **05_create_student_account.sh:** Deploys the local student profile with autologin.
* **06_install_media_apps.sh:** Installs OBS Studio and VLC for classroom recording.
* **07_install_vs_code.sh:** Installs VS Code `1.85.2` and pins it (`apt-mark hold`) to block updates.
* **08_mount_windows_drives.sh:** Configures persistent mounting of local NTFS partitions.
* **09-create-desktop-entries.sh:** Copies application shortcuts to the student desktop.
* **10 / 11 Veyon Monitoring:** Installs and configures (`10`) or purges (`11`) the classroom monitoring client.
* **12 / 13 Samba Discovery:** Toggles `winbind` and fixes `/etc/nsswitch.conf` for Nemo network browsing.
* **14 / 15 Nemo Bookmarks:** Adds (`14`) or removes (`15`) network share shortcuts in the file manager.
* **16 / 17 Remote Desktop:** Configures (`16`) or removes (`17`) XRDP with session-killing rules.

## Installation Notes

### Desktop Entries
Run script `09` **ONLY AFTER** logging in graphically as the `student` user at least once.
Cinnamon creates `~/Desktop` and user configs on first login.

### Windows Drives
Edit script `08` to specify the exact **UUID** of your NTFS partitions. Find them using:
```bash
sudo lsblk
```

### Veyon Service Setup
Before executing the Veyon installation script, you must manually copy your administrative public `.pem` keys into the `resources/veyon/` folder. The script relies on these keys to configure client-teacher authentication across the lab workstations.