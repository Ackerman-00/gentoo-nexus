#!/bin/bash
set -eo pipefail
exec > >(tee -i /var/log/gentoo-nexus-install.log) 2>&1

#==============================================================================
# CONFIGURATION & CONSTANTS
#==============================================================================
readonly SCRIPT_VERSION="2026.5.2-NEXUS-MASTER"
readonly LOCKFILE="/var/lib/gentoo-nexus-installed"
readonly LOGFILE="/var/log/gentoo-nexus-install.log"
readonly NEXUS_REPO_URL="https://github.com/Ackerman-00/gentoo-nexus.git"
readonly NEXUS_BINHOST="https://gentoo-nexus.sourceforge.io/"
readonly COSMIC_OVERLAY_URL="https://github.com/fsvm88/cosmic-overlay.git"

#==============================================================================
# COLOR CODES
#==============================================================================
B="\e[1;34m"
G="\e[1;32m"
Y="\e[1;33m"
R="\e[1;31m"
C="\e[0m"

#==============================================================================
# ERROR HANDLING & IDEMPOTENCY
#==============================================================================
trap 'error_handler $? $LINENO' ERR

error_handler() {
    local exit_code=$1
    local line_number=$2
    log_msg "\n${R}[!] FATAL ERROR: Command failed with exit code ${exit_code} at line ${line_number}${C}"
    log_msg "${Y}Check ${LOGFILE} for details. System may be in an inconsistent state.${C}"
    exit $exit_code
}

cleanup_on_exit() {
    if [[ -f "$LOCKFILE" ]] && [[ "$INSTALL_COMPLETE" != "true" ]]; then
        rm -f "$LOCKFILE"
        log_msg "${Y}[!] Installation incomplete. Lockfile removed to allow re-runs.${C}"
    fi
}
trap cleanup_on_exit EXIT

if [ "$EUID" -ne 0 ]; then 
    echo -e "${R}[!] FATAL: Execution requires root privileges inside the Gentoo chroot.${C}"
    exit 1 
fi

if [[ -f "$LOCKFILE" ]]; then
    echo -e "${R}[!] FATAL: Lockfile exists. A previous installation completed or is in progress.${C}"
    echo -e "${Y}Remove ${LOCKFILE} to force a re-run.${C}"
    exit 1
fi

mkdir -p "$(dirname "$LOCKFILE")"
echo "Installation started: $(date)" > "$LOCKFILE"

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================
log_msg() {
    echo -e "$1"
    # Strip ANSI codes for clean log file writing
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $(echo -e "$1" | sed -r 's/\x1B\[[0-9;]*[mK]//g')" >> "$LOGFILE"
}

get_choice() {
    local prompt="$1" valid_regex="$2" var_name="$3"
    local choice
    while true; do
        read -p "$(echo -e "${Y}${prompt}${C}") " choice
        if [[ "$choice" =~ $valid_regex ]]; then
            eval "$var_name=\"$choice\""
            break
        else
            echo -e "${R}[!] Invalid input. Please select a valid option.${C}"
        fi
    done
}

backup_config() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d%H%M%S)"
        log_msg "${B}[BACKUP] Created backup of ${file}${C}"
    fi
}

#==============================================================================
# HEADER
#==============================================================================
clear
echo -e "${B}================================================================${C}"
echo -e "${G}    GENTOO NEXUS ARCHITECT: AUTOMATED BINARY DEPLOYMENT 2026    ${C}"
echo -e "${B}================================================================${C}"
echo -e "Version: ${SCRIPT_VERSION}"
echo -e "Targeting: Linux Kernel 6.19.10+ | Mesa 26.0.3+ | Niri 25.11+"
echo -e "Execution: Chroot Environment (Post-Stage3)"
echo -e "Binhost: ${NEXUS_BINHOST}"
echo -e "Log file: ${LOGFILE}\n"

#==============================================================================
# HARDWARE & SOFTWARE SELECTION
#==============================================================================
log_msg "${B}>>> [1/8] HARDWARE & SOFTWARE TARGETS${C}"
echo "1) Desktop (Ryzen 5 5600G - Zen 3 | AMD GPU)"
echo "2) Desktop (Ryzen 7 7700  - Zen 4 | RTX 5060)"
echo "3) Laptop  (Ryzen 3 7320U - Zen 2 | AMD GPU | WiFi)"
echo "4) Laptop  (HP EliteBook  - Skylake | Intel Iris | WiFi)"
get_choice "Hardware Target [1-4]:" "^[1-4]$" hw_choice

get_choice "Enter primary username:" "^[a-z_][a-z0-9_-]*$" username
get_choice "Enable GURU (for -bin packages)? [y/n]:" "^[yYnN]$" guru_choice
get_choice "Enable Steam natively? [y/n]:" "^[yYnN]$" steam_choice
get_choice "Enable Heroic & ProtonPlus? [y/n]:" "^[yYnN]$" games_choice
get_choice "Enable Vesktop? [y/n]:" "^[yYnN]$" vesktop_choice
get_choice "Enable RootApp? [y/n]:" "^[yYnN]$" rootapp_choice
get_choice "Enable Matugen (Material You colors)? [y/n]:" "^[yYnN]$" matugen_choice

log_msg "\n${B}>>> [2/8] ENVIRONMENT SELECTION${C}"
echo "1) niri (Nexus)"
echo "2) mangowc (Nexus)"
echo "3) Hyprland"
echo "4) GNOME"
echo "5) KDE Plasma"
echo "6) COSMIC"
get_choice "Wayland Compositor [1-6]:" "^[1-6]$" de_choice

log_msg "\n${B}>>> [3/8] DESKTOP SHELL & GREETER${C}"
echo "1) noctalia-shell (Nexus)"
echo "2) dank-material-shell (Nexus)"
echo "3) None"
get_choice "Desktop Shell [1-3]:" "^[1-3]$" shell_choice

echo "1) ly (TUI)"
echo "2) sddm"
echo "3) gdm"
echo "4) greetd"
echo "5) None (TTY boot)"
get_choice "Display Manager [1-5]:" "^[1-5]$" dm_choice

[[ "${vesktop_choice,,}" == "y" ]] && guru_choice="y"

#==============================================================================
# NETWORK VALIDATION
#==============================================================================
log_msg "\n${B}>>> [4/8] INITIALIZING BINHOSTS & PROFILE...${C}"
if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
    log_msg "${R}[!] ERROR: No WAN connectivity. Check chroot DNS resolution.${C}"
    exit 1
fi
log_msg "${G}[✓] Network connectivity verified.${C}"

eselect profile set default/linux/amd64/23.0/desktop
mkdir -p /etc/portage/binrepos.conf

cat << EOF > /etc/portage/binrepos.conf/gentoo.conf
[gentoo]
priority = 1
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64/
EOF

cat << EOF > /etc/portage/binrepos.conf/nexus.conf
[gentoo-nexus-sf]
priority = 9999
sync-uri = ${NEXUS_BINHOST}
verify-signature = false
EOF

#==============================================================================
# HARDWARE-SPECIFIC CONFIGURATION
#==============================================================================
case $hw_choice in
    1) ZRAM_SIZE="6144M"; V_CARD="amdgpu radeonsi"; ARCH="znver3"; G_CMD="" ;;
    2) ZRAM_SIZE="8192M"; V_CARD="nvidia"; ARCH="znver4"; G_CMD="nvidia-drm.modeset=1" ;;
    3) ZRAM_SIZE="4096M"; V_CARD="amdgpu radeonsi"; ARCH="znver2"; G_CMD="" ;;
    4) ZRAM_SIZE="8192M"; V_CARD="intel"; ARCH="skylake"; G_CMD="" ;;
esac

cat << EOF > /etc/portage/make.conf
COMMON_FLAGS="-O3 -march=$ARCH -mtune=$ARCH -pipe -flto=auto"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
RUSTFLAGS="-C opt-level=3"
MAKEOPTS="-j$(nproc)"
USE="wayland X vulkan pipewire dbus elogind udev opengl dri gbm vaapi vdpau ffmpeg zram bluetooth screencast gstreamer gles2 minizip -systemd -aqua -cups"
VIDEO_CARDS="$V_CARD"
ACCEPT_KEYWORDS="~amd64"
FEATURES="getbinpkg binpkg-request-signature"
ACCEPT_LICENSE="*"
LC_MESSAGES=C.utf8
EOF

#==============================================================================
# REPOSITORY SYNCHRONIZATION
#==============================================================================
log_msg "\n${B}>>> [5/8] SYNCHRONIZING REPOSITORIES...${C}"
# ARCHITECT FIX: Force PKGDIR to persist through sudo/distrobox
export PKGDIR=$(portageq envvar PKGDIR)

if command -v getuto &> /dev/null; then
    getuto || true
fi

emerge-webrsync -q
emerge --noreplace --quiet --getbinpkg app-eselect/eselect-repository dev-vcs/git

eselect repository add gentoo-nexus git "$NEXUS_REPO_URL"
[[ "${guru_choice,,}" == "y" ]] && eselect repository enable guru
[[ "${steam_choice,,}" == "y" ]] && eselect repository enable steam-overlay
[[ "$de_choice" == "6" ]] && eselect repository add cosmic-overlay git "$COSMIC_OVERLAY_URL"

emaint sync -a

#==============================================================================
# PORTAGE CONFIGURATION
#==============================================================================
log_msg "\n${B}>>> [6/8] CONFIGURING PORTAGE & UNMASKING...${C}"
mkdir -p /etc/portage/package.{use,mask,accept_keywords,unmask}

cat << EOF > /etc/portage/package.accept_keywords/nexus
x11-misc/matugen::gentoo-nexus **
x11-base/xwayland-satellite::gentoo-nexus **
EOF

# ARCHITECT FIX: Master Unmask for Live/Testing binaries
cat << EOF > /etc/portage/package.unmask/nexus
=gui-wm/niri-9999::gentoo-nexus
=gui-wm/mangowc-9999::gentoo-nexus
EOF

[[ "$de_choice" == "1" ]] && echo "gui-wm/niri::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus
[[ "$de_choice" == "2" ]] && echo "gui-wm/mangowc::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus

#==============================================================================
# USER & SERVICES
#==============================================================================
id "$username" &>/dev/null || useradd -m -G wheel,audio,video,portage,input -s /bin/bash "$username"
echo "permit :wheel" > /etc/doas.conf && chmod 0400 /etc/doas.conf

emerge --noreplace --quiet --getbinpkg sys-block/zram-init net-wireless/iwd sys-auth/seatd

rc-update add zram-init boot
rc-update add elogind boot
rc-update add seatd default
rc-update add dbus default
rc-update add NetworkManager default

# FIXED REGEX: catches 3 or 4 for laptop wifi
if [[ "$hw_choice" =~ ^$ ]]; then
    rc-update add iwd default
fi

#==============================================================================
# PACKAGE INSTALLATION
#==============================================================================
log_msg "\n${B}>>> [7/8] EXECUTING BINARY DEPLOYMENT...${C}"

INSTALL_LIST="sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware sys-kernel/dracut sys-boot/grub sys-boot/efibootmgr app-admin/doas sys-auth/elogind media-video/pipewire media-video/wireplumber gui-apps/foot mate-extra/mate-polkit x11-base/xwayland-satellite gui-apps/swaync net-misc/networkmanager sys-power/upower"

case $de_choice in
    1) INSTALL_LIST="$INSTALL_LIST gui-wm/niri::gentoo-nexus sys-apps/xdg-desktop-portal-gnome" ;;
    2) INSTALL_LIST="$INSTALL_LIST gui-wm/mangowc::gentoo-nexus sys-apps/xdg-desktop-portal-wlr" ;;
    3) INSTALL_LIST="$INSTALL_LIST gui-wm/hyprland sys-apps/xdg-desktop-portal-hyprland" ;;
    4) INSTALL_LIST="$INSTALL_LIST gnome-base/gnome-light" ;;
    5) INSTALL_LIST="$INSTALL_LIST kde-plasma/plasma-meta" ;;
    6) INSTALL_LIST="$INSTALL_LIST cosmic-base/cosmic-session" ;;
esac

# USER CHOICE: Optional Matugen
[[ "${matugen_choice,,}" == "y" ]] && INSTALL_LIST="$INSTALL_LIST x11-misc/matugen::gentoo-nexus"

[[ "$shell_choice" == "1" ]] && INSTALL_LIST="$INSTALL_LIST gui-wm/noctalia-shell::gentoo-nexus"
[[ "$shell_choice" == "2" ]] && INSTALL_LIST="$INSTALL_LIST gui-wm/dank-material-shell::gentoo-nexus"

# ARCHITECT FIX: The God-Mode Flags
BIN_OPTS="--getbinpkg --usepkg --binpkg-respect-use=n --binpkg-changed-deps=y --usepkg-exclude-live=n --keep-going"

# Pre-fetch fix
emaint binhost --fix > /dev/null 2>&1 || true

emerge --autounmask=y --autounmask-write $BIN_OPTS --newuse $INSTALL_LIST
etc-update --automode -5
emerge $BIN_OPTS --update --newuse $INSTALL_LIST

#==============================================================================
# COMPLETION
#==============================================================================
INSTALL_COMPLETE="true"
echo "$INSTALL_COMPLETE" > "$LOCKFILE"
log_msg "\n${G}[✓] GENTOO NEXUS DEPLOYMENT COMPLETE!${C}"
