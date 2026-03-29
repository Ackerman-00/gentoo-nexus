#!/bin/bash
set -eo pipefail
exec > >(tee -i /var/log/gentoo-nexus-install.log) 2>&1

#==============================================================================
# CONFIGURATION & CONSTANTS
#==============================================================================
readonly SCRIPT_VERSION="2026.5.3-NEXUS-MASTER"
readonly LOCKFILE="/var/lib/gentoo-nexus-installed"
readonly LOGFILE="/var/log/gentoo-nexus-install.log"
readonly NEXUS_REPO_URL="https://github.com/Ackerman-00/gentoo-nexus.git"
readonly NEXUS_BINHOST="https://gentoo-nexus.sourceforge.io/"

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
INSTALL_COMPLETE="false"

trap 'error_handler $? $LINENO' ERR

error_handler() {
    local exit_code=$1
    local line_number=$2
    log_msg "\n${R}[!] FATAL ERROR: Command failed with exit code ${exit_code} at line ${line_number}${C}"
    log_msg "${Y}Check ${LOGFILE} for details.${C}"
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
    echo -e "${R}[!] FATAL: Must be run as root inside Gentoo chroot.${C}"
    exit 1
fi

if [[ -f "$LOCKFILE" ]]; then
    echo -e "${R}[!] FATAL: Lockfile exists at ${LOCKFILE}.${C}"
    echo -e "${Y}Remove it to force a re-run: rm ${LOCKFILE}${C}"
    exit 1
fi

mkdir -p "$(dirname "$LOCKFILE")"
echo "Installation started: $(date)" > "$LOCKFILE"

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================
log_msg() {
    echo -e "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $(echo -e "$1" | sed -r 's/\x1B\[[0-9;]*[mK]//g')" >> "$LOGFILE"
}

get_choice() {
    local prompt="$1" valid_regex="$2" var_name="$3"
    local choice
    while true; do
        read -rp "$(echo -e "${Y}${prompt}${C}") " choice
        if [[ "$choice" =~ $valid_regex ]]; then
            eval "$var_name=\"$choice\""
            break
        else
            echo -e "${R}[!] Invalid input. Please select a valid option.${C}"
        fi
    done
}

# FIX: Add or skip repo gracefully — eselect exits 250 if already enabled
repo_add_safe() {
    local name="$1" type="$2" url="$3"
    if eselect repository list | grep -q "^\s*\[.*\] ${name}\b"; then
        log_msg "${Y}[~] Repository '${name}' already enabled, skipping add.${C}"
    else
        eselect repository add "${name}" "${type}" "${url}" || true
    fi
}

# FIX: Enable built-in repo safely
repo_enable_safe() {
    local name="$1"
    if eselect repository list | grep -q "^\s*\[.*\] ${name}\b"; then
        log_msg "${Y}[~] Repository '${name}' already enabled, skipping.${C}"
    else
        eselect repository enable "${name}" || true
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
echo -e "Binhost: ${NEXUS_BINHOST}"
echo -e "Log: ${LOGFILE}\n"

#==============================================================================
# HARDWARE & SOFTWARE SELECTION
#==============================================================================
log_msg "${B}>>> [1/8] HARDWARE & SOFTWARE TARGETS${C}"
echo "1) Desktop (Ryzen 5 5600G - Zen 3 | AMD GPU)"
echo "2) Desktop (Ryzen 7 7700  - Zen 4 | RTX 5060)"
echo "3) Laptop  (Ryzen 3 7320U - Zen 3 | AMD GPU | WiFi)"
echo "4) Laptop  (HP EliteBook  - Skylake | Intel Iris | WiFi)"
get_choice "Hardware Target [1-4]:" "^[1-4]$" hw_choice

# FIX: Username regex — lowercase only (explain this to user)
echo -e "${Y}Note: Username must be lowercase (e.g. 'ackerman' not 'Quietcraft')${C}"
get_choice "Enter primary username (lowercase):" "^[a-z_][a-z0-9_-]{1,31}$" username

get_choice "Enable GURU overlay? [y/n]:" "^[yYnN]$" guru_choice
get_choice "Enable Steam natively? [y/n]:" "^[yYnN]$" steam_choice
get_choice "Enable Heroic & ProtonPlus? [y/n]:" "^[yYnN]$" games_choice
get_choice "Enable Vesktop? [y/n]:" "^[yYnN]$" vesktop_choice
get_choice "Enable RootApp? [y/n]:" "^[yYnN]$" rootapp_choice
get_choice "Enable Matugen (Material You colors)? [y/n]:" "^[yYnN]$" matugen_choice

log_msg "\n${B}>>> [2/8] COMPOSITOR SELECTION${C}"
echo "1) niri (Nexus)"
echo "2) mangowc / MangoWC (Nexus)"
echo "3) Hyprland"
echo "4) GNOME"
echo "5) KDE Plasma"
get_choice "Wayland Compositor [1-5]:" "^[1-5]$" de_choice

log_msg "\n${B}>>> [3/8] DESKTOP SHELL & GREETER${C}"
echo "1) dank-material-shell (Nexus)"
echo "2) None"
get_choice "Desktop Shell [1-2]:" "^[1-2]$" shell_choice

echo "1) ly (TUI, lightweight)"
echo "2) sddm"
echo "3) greetd + tuigreet"
echo "4) None (TTY autologin)"
get_choice "Display Manager [1-4]:" "^[1-4]$" dm_choice

# Vesktop requires guru
[[ "${vesktop_choice,,}" == "y" ]] && guru_choice="y"

#==============================================================================
# NETWORK VALIDATION
#==============================================================================
log_msg "\n${B}>>> [4/8] INITIALIZING BINHOSTS & PROFILE...${C}"
if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
    log_msg "${R}[!] ERROR: No network. Check DNS resolution in chroot.${C}"
    exit 1
fi
log_msg "${G}[✓] Network connectivity verified.${C}"

eselect profile set default/linux/amd64/23.0/desktop
eselect news read all >/dev/null 2>&1 || true

mkdir -p /etc/portage/binrepos.conf

cat > /etc/portage/binrepos.conf/gentoo.conf << EOF
[gentoo]
priority = 10000
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64/
verify-signature = false
EOF

cat > /etc/portage/binrepos.conf/nexus.conf << EOF
[gentoo-nexus-sf]
priority = 9999
sync-uri = ${NEXUS_BINHOST}
verify-signature = false
EOF

#==============================================================================
# HARDWARE-SPECIFIC CONFIGURATION
#==============================================================================
case $hw_choice in
    1) ZRAM_SIZE="6144M"; V_CARD="amdgpu radeonsi"; CPU_ARCH="znver3"; NEED_WIFI="no" ;;
    2) ZRAM_SIZE="8192M"; V_CARD="nvidia";           CPU_ARCH="znver4"; NEED_WIFI="no" ;;
    3) ZRAM_SIZE="4096M"; V_CARD="amdgpu radeonsi"; CPU_ARCH="znver3"; NEED_WIFI="yes" ;;
    4) ZRAM_SIZE="8192M"; V_CARD="intel iris";       CPU_ARCH="skylake"; NEED_WIFI="yes" ;;
esac

# Steam needs multilib/32-bit USE flags
STEAM_USE=""
[[ "${steam_choice,,}" == "y" ]] && STEAM_USE=" abi_x86_32"

cat > /etc/portage/make.conf << EOF
COMMON_FLAGS="-O2 -march=${CPU_ARCH} -mtune=${CPU_ARCH} -pipe"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
RUSTFLAGS="-C opt-level=2"
MAKEOPTS="-j$(nproc) -l$(nproc)"
USE="wayland X vulkan pipewire dbus elogind udev opengl dri gbm vaapi vdpau ffmpeg bluetooth screencast gstreamer minizip${STEAM_USE} -systemd -aqua -cups"
VIDEO_CARDS="${V_CARD}"
ACCEPT_KEYWORDS="~amd64"
FEATURES="getbinpkg -userfetch -userpriv -usersandbox"
ACCEPT_LICENSE="*"
PKGDIR="/var/cache/binpkgs"
DISTDIR="/var/cache/distfiles"
LC_MESSAGES=C.utf8
EOF

mkdir -p /etc/portage/package.{use,mask,accept_keywords,unmask,license}
mkdir -p /etc/portage/repos.conf

# Mask systemd
cat > /etc/portage/package.mask/systemd << 'MASK'
sys-apps/systemd
sys-apps/gentoo-systemd-integration
MASK

# Accept keywords for Nexus live packages
cat > /etc/portage/package.accept_keywords/nexus << 'EOF'
*/*::gentoo-nexus **
x11-base/xwayland-satellite::gentoo-nexus **
gui-wm/niri::gentoo-nexus **
gui-wm/mangowc::gentoo-nexus **
gui-wm/dank-material-shell::gentoo-nexus **
x11-misc/matugen::gentoo-nexus **
EOF

#==============================================================================
# REPOSITORY SYNCHRONIZATION
#==============================================================================
log_msg "\n${B}>>> [5/8] SYNCHRONIZING REPOSITORIES...${C}"

emerge-webrsync -q
emerge --noreplace --quiet --getbinpkg \
    app-eselect/eselect-repository \
    dev-vcs/git

# FIX: Use safe add function — no more exit 250 on re-runs
repo_add_safe "gentoo-nexus" "git" "${NEXUS_REPO_URL}"
[[ "${guru_choice,,}" == "y" ]]  && repo_enable_safe "guru"
[[ "${steam_choice,,}" == "y" ]] && repo_enable_safe "steam-overlay"

emaint sync -a 2>/dev/null || true
eselect news read all >/dev/null 2>&1 || true

#==============================================================================
# USER ACCOUNT SETUP
#==============================================================================
log_msg "\n${B}>>> [6/8] USER & SERVICE SETUP...${C}"

if ! id "${username}" &>/dev/null; then
    useradd -m -G wheel,audio,video,portage,input,seat,plugdev -s /bin/bash "${username}"
    log_msg "${G}[✓] User '${username}' created.${C}"
else
    log_msg "${Y}[~] User '${username}' already exists.${C}"
fi

# Set up doas (sudo alternative)
echo "permit persist :wheel" > /etc/doas.conf
chmod 0400 /etc/doas.conf

# OpenRC services
rc-update add elogind boot  2>/dev/null || true
rc-update add seatd default 2>/dev/null || true
rc-update add dbus default  2>/dev/null || true

# FIX: Correct WiFi service activation
if [[ "${NEED_WIFI}" == "yes" ]]; then
    rc-update add iwd default 2>/dev/null || true
    rc-update add NetworkManager default 2>/dev/null || true
fi

#==============================================================================
# PACKAGE INSTALLATION
#==============================================================================
log_msg "\n${B}>>> [7/8] EXECUTING BINARY DEPLOYMENT...${C}"

# Core system packages — all pulled from binhost
INSTALL_LIST=(
    sys-kernel/gentoo-kernel-bin
    sys-kernel/linux-firmware
    sys-kernel/dracut
    sys-boot/grub
    sys-boot/efibootmgr
    app-admin/doas
    sys-auth/elogind
    sys-auth/seatd
    media-video/pipewire
    media-video/wireplumber
    net-misc/networkmanager
    sys-power/upower
    app-misc/jq
    sys-block/zram-init
)

# Compositor packages
case $de_choice in
    1) INSTALL_LIST+=( "gui-wm/niri::gentoo-nexus" "sys-apps/xdg-desktop-portal-gnome" "x11-base/xwayland-satellite::gentoo-nexus" ) ;;
    2) INSTALL_LIST+=( "gui-wm/mangowc::gentoo-nexus" "gui-libs/xdg-desktop-portal-wlr" "x11-base/xwayland-satellite::gentoo-nexus" ) ;;
    3) INSTALL_LIST+=( "gui-wm/hyprland" "gui-libs/xdg-desktop-portal-hyprland" ) ;;
    4) INSTALL_LIST+=( "gnome-base/gnome-light" ) ;;
    5) INSTALL_LIST+=( "kde-plasma/plasma-meta" ) ;;
esac

# Desktop shell
[[ "$shell_choice" == "1" ]] && INSTALL_LIST+=(
    "gui-wm/dank-material-shell::gentoo-nexus"
    "gui-apps/quickshell"
    "x11-misc/matugen::gentoo-nexus"
    "app-misc/dgop::gentoo-nexus"
    "sys-apps/danksearch::gentoo-nexus"
    "gui-apps/foot"
)

# Display manager
case $dm_choice in
    1) INSTALL_LIST+=( "x11-misc/ly" ) ;;
    2) INSTALL_LIST+=( "x11-misc/sddm" ) ;;
    3) INSTALL_LIST+=( "gui-libs/greetd" "gui-apps/tuigreet" ) ;;
    4) ;; # TTY autoloign — handled below
esac

# Optional packages
[[ "${matugen_choice,,}" == "y" ]]  && INSTALL_LIST+=( "x11-misc/matugen::gentoo-nexus" )
[[ "${steam_choice,,}" == "y" ]]    && INSTALL_LIST+=( "games-util/steam-launcher" )
[[ "${games_choice,,}" == "y" ]]    && INSTALL_LIST+=( "games-util/protonplus-bin::gentoo-nexus" "games-util/heroic-games-launcher-bin" )
[[ "${vesktop_choice,,}" == "y" ]]  && INSTALL_LIST+=( "net-im/vesktop-bin" )
[[ "${rootapp_choice,,}" == "y" ]]  && INSTALL_LIST+=( "app-misc/rootapp-bin::gentoo-nexus" )
[[ "${NEED_WIFI}" == "yes" ]]       && INSTALL_LIST+=( "net-wireless/iwd" "net-wireless/wpa_supplicant" )

# Common apps
INSTALL_LIST+=(
    "gui-apps/wl-clipboard"
    "gui-apps/swaync"
    "app-misc/cliphist"
    "media-sound/cava"
    "gui-apps/foot"
    "app-editors/nano"
    "sys-apps/ripgrep"
)

# FIX: Correct binary-only emerge flags
# --binpkg-respect-use=n  → accept binaries even if USE doesn't match exactly
# --getbinpkg             → prefer binaries from binhost
# --usepkg                → use local binary cache too
# removed invalid --usepkg-exclude-live=n flag
BIN_OPTS="--getbinpkg --usepkg --binpkg-respect-use=n --keep-going --autounmask=y --autounmask-write"

# First pass: write autounmask changes
emerge ${BIN_OPTS} "${INSTALL_LIST[@]}" 2>&1 || true
etc-update --automode -5 2>/dev/null || true
# Second pass: actually install
emerge ${BIN_OPTS} --update --newuse "${INSTALL_LIST[@]}"

#==============================================================================
# POST-INSTALL CONFIGURATION
#==============================================================================
log_msg "\n${B}>>> [8/8] POST-INSTALL CONFIGURATION...${C}"

# ZRAM setup
mkdir -p /etc/conf.d
cat > /etc/conf.d/zram-init << EOF
load_on_start="yes"
unload_on_stop="yes"
num_devices="1"
type0="swap"
size0="${ZRAM_SIZE}"
max_comp_streams0="$(nproc)"
comp_algorithm0="lz4"
priority0="32767"
EOF
rc-update add zram-init boot 2>/dev/null || true

# PipeWire session setup for user
mkdir -p "/home/${username}/.config/systemd/user"
cat > "/home/${username}/.config/systemd/user/pipewire.service" << 'EOF'
[Unit]
Description=PipeWire Multimedia Service
[Service]
ExecStart=/usr/bin/pipewire
Restart=on-failure
[Install]
WantedBy=default.target
EOF
chown -R "${username}:${username}" "/home/${username}/.config" || true

# Display manager activation
case $dm_choice in
    1) rc-update add ly default  2>/dev/null || true ;;
    2) rc-update add sddm default 2>/dev/null || true ;;
    3) rc-update add greetd default 2>/dev/null || true ;;
    4)
        # TTY autologin for user on tty1
        mkdir -p /etc/conf.d
        sed -i "s/^#*agetty_options_tty1=.*/agetty_options_tty1=\"--autologin ${username}\"/" \
            /etc/conf.d/agetty.tty1 2>/dev/null || true
        ;;
esac

# GRUB installation hint (needs user to know their disk)
log_msg "${Y}"
log_msg "[!] IMPORTANT: GRUB is installed but not configured."
log_msg "    You MUST run these commands before rebooting:"
log_msg "    1. grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo"
log_msg "    2. grub-mkconfig -o /boot/grub/grub.cfg"
log_msg "    3. dracut --hostonly --kver \$(ls /lib/modules | tail -1)"
log_msg "${C}"

# Set locale & timezone
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen 2>/dev/null || true

# NetworkManager as default network management
if [[ "${NEED_WIFI}" == "yes" ]]; then
    mkdir -p /etc/NetworkManager
    cat > /etc/NetworkManager/NetworkManager.conf << 'EOF'
[main]
plugins=keyfile
[device]
wifi.backend=iwd
EOF
fi

#==============================================================================
# COMPLETION
#==============================================================================
INSTALL_COMPLETE="true"
echo "INSTALL_COMPLETE=true" > "$LOCKFILE"
echo "username=${username}" >> "$LOCKFILE"
echo "compositor=${de_choice}" >> "$LOCKFILE"
echo "completed=$(date)" >> "$LOCKFILE"

log_msg "\n${G}================================================================${C}"
log_msg "${G}    [✓] GENTOO NEXUS DEPLOYMENT COMPLETE!                        ${C}"
log_msg "${G}================================================================${C}"
log_msg "User created: ${username}"
log_msg "Log saved: ${LOGFILE}"
log_msg "${Y}Next steps:${C}"
log_msg "  1. Set password: passwd ${username}"
log_msg "  2. Set root password: passwd"
log_msg "  3. Configure GRUB (see instructions above)"
log_msg "  4. Exit chroot, unmount, reboot"
