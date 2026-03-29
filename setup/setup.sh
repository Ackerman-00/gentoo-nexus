#!/bin/bash
set -eo pipefail
exec > >(tee -i /var/log/gentoo-nexus-install.log) 2>&1

#==============================================================================
# CONFIGURATION & CONSTANTS
#==============================================================================
readonly SCRIPT_VERSION="2026.6.0-NEXUS-ULTIMATE"
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

export PKGDIR=$(portageq envvar PKGDIR 2>/dev/null || echo "/var/cache/binpkgs")

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

repo_add_safe() {
    local name="$1" type="$2" url="$3"
    if [[ -d "/var/db/repos/${name}" ]] || eselect repository list 2>/dev/null | grep -q "\b${name}\b"; then
        log_msg "${Y}[~] Repository '${name}' already exists, skipping add.${C}"
    else
        eselect repository add "${name}" "${type}" "${url}" || true
    fi
}

repo_enable_safe() {
    local name="$1"
    if [[ -d "/var/db/repos/${name}" ]] || eselect repository list 2>/dev/null | grep -q "\b${name}\b"; then
        log_msg "${Y}[~] Repository '${name}' already enabled, skipping.${C}"
    else
        eselect repository enable "${name}" || true
    fi
}

#==============================================================================
# HEADER
#==============================================================================
clear 2>/dev/null || printf "\033c"
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

if [[ "${steam_choice,,}" == "y" ]]; then
    if eselect profile show 2>/dev/null | grep -q "no-multilib"; then
        log_msg "${R}[!] FATAL: Steam requires a multilib profile, but no-multilib is currently selected.${C}"
        exit 1
    fi
fi

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
    1) ZRAM_SIZE="6144M"; V_CARD="amdgpu radeonsi"; CPU_ARCH="znver3"; NEED_WIFI="no"; G_CMD="" ;;
    2) ZRAM_SIZE="8192M"; V_CARD="nvidia";           CPU_ARCH="znver4"; NEED_WIFI="no"; G_CMD="nvidia-drm.modeset=1" ;;
    3) ZRAM_SIZE="4096M"; V_CARD="amdgpu radeonsi"; CPU_ARCH="znver3"; NEED_WIFI="yes"; G_CMD="" ;;
    4) ZRAM_SIZE="8192M"; V_CARD="intel iris";       CPU_ARCH="skylake"; NEED_WIFI="yes"; G_CMD="i915.enable_psr=0" ;;
esac

STEAM_USE=""
[[ "${steam_choice,,}" == "y" ]] && STEAM_USE=" abi_x86_32"

cat > /etc/portage/make.conf << EOF
COMMON_FLAGS="-O2 -march=${CPU_ARCH} -mtune=${CPU_ARCH} -pipe"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
RUSTFLAGS="-C opt-level=2"
MAKEOPTS="-j$(nproc) -l$(nproc)"
USE="wayland X vulkan pipewire dbus elogind udev opengl dri gbm vaapi vdpau ffmpeg bluetooth screencast gstreamer minizip${STEAM_USE} -daemon -systemd -aqua -cups"
VIDEO_CARDS="${V_CARD}"
ACCEPT_KEYWORDS="~amd64"
FEATURES="getbinpkg -userfetch -userpriv -usersandbox"
ACCEPT_LICENSE="*"
PKGDIR="/var/cache/binpkgs"
DISTDIR="/var/cache/distfiles"
LC_MESSAGES=C.utf8
EOF

mkdir -p /etc/portage/profile
mkdir -p /etc/portage/package.{use,mask,accept_keywords,unmask,license}
mkdir -p /etc/portage/repos.conf

# ARCHITECT FIX: The Ultimate Systemd Kill-Switch (package.provided)
cat > /etc/portage/profile/package.provided << 'PROV'
sys-apps/systemd-260.1
sys-apps/systemd-utils-260.1
sys-apps/gentoo-systemd-integration-9-r2
sys-apps/systemd-initctl-4
PROV

cat > /etc/portage/package.mask/systemd << 'MASK'
sys-apps/systemd
sys-apps/gentoo-systemd-integration
sys-apps/systemd-utils
sys-apps/systemd-initctl
MASK

cat > /etc/portage/package.unmask/overrides << 'UNMASK'
media-libs/dav1d
gui-libs/gtk4-layer-shell
UNMASK

cat > /etc/portage/package.use/global_overrides << 'USE'
media-video/pipewire extra sound-server
media-video/wireplumber extra
sys-apps/dbus -systemd
sys-auth/polkit -systemd
net-misc/networkmanager -systemd
net-dialup/ppp -systemd
sys-block/zram-init -systemd
sys-apps/util-linux -systemd
media-libs/libpulse -systemd
sys-fs/eudev -systemd
virtual/udev -systemd
virtual/libudev -systemd
sys-libs/ncurses -gpm
gui-libs/gtk4-layer-shell introspection vala
USE

cat > /etc/portage/package.use/video_overrides << 'USE'
x11-libs/libdrm video_cards_nouveau video_cards_radeon
USE

# ARCHITECT FIX: Bypass dav1d base profile mask with **
cat > /etc/portage/package.accept_keywords/nexus << 'EOF'
*/*::gentoo-nexus **
x11-base/xwayland-satellite::gentoo-nexus **
gui-wm/niri::gentoo-nexus **
gui-wm/mangowc::gentoo-nexus **
gui-wm/dank-material-shell::gentoo-nexus **
x11-misc/matugen::gentoo-nexus **
media-libs/dav1d **
gui-libs/gtk4-layer-shell ~amd64
EOF

if [ -n "$G_CMD" ]; then
    mkdir -p /etc/default
    touch /etc/default/grub
    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
        if ! grep -q "$G_CMD" /etc/default/grub; then
            sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"/\1 $G_CMD\"/" /etc/default/grub
        fi
    else
        echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$G_CMD\"" >> /etc/default/grub
    fi
fi

#==============================================================================
# REPOSITORY SYNCHRONIZATION
#==============================================================================
log_msg "\n${B}>>> [5/8] SYNCHRONIZING REPOSITORIES...${C}"

emerge-webrsync -q
emerge --noreplace --quiet --getbinpkg app-eselect/eselect-repository dev-vcs/git

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

echo "permit persist :wheel" > /etc/doas.conf
chmod 0400 /etc/doas.conf

rc-update add elogind boot  2>/dev/null || true
rc-update add seatd default 2>/dev/null || true
rc-update add dbus default  2>/dev/null || true

if [[ "${NEED_WIFI}" == "yes" ]]; then
    rc-update add iwd default 2>/dev/null || true
    rc-update add NetworkManager default 2>/dev/null || true
fi

#==============================================================================
# PACKAGE INSTALLATION
#==============================================================================
log_msg "\n${B}>>> [7/8] EXECUTING BINARY DEPLOYMENT...${C}"

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

case $de_choice in
    1) INSTALL_LIST+=( "gui-wm/niri::gentoo-nexus" "sys-apps/xdg-desktop-portal-gnome" "x11-base/xwayland-satellite::gentoo-nexus" ) ;;
    2) INSTALL_LIST+=( "gui-wm/mangowc::gentoo-nexus" "gui-libs/xdg-desktop-portal-wlr" "x11-base/xwayland-satellite::gentoo-nexus" ) ;;
    3) INSTALL_LIST+=( "gui-wm/hyprland" "gui-libs/xdg-desktop-portal-hyprland" ) ;;
    4) INSTALL_LIST+=( "gnome-base/gnome-light" ) ;;
    5) INSTALL_LIST+=( "kde-plasma/plasma-meta" ) ;;
esac

[[ "$shell_choice" == "1" ]] && INSTALL_LIST+=(
    "gui-wm/dank-material-shell::gentoo-nexus"
    "gui-apps/quickshell"
    "x11-misc/matugen::gentoo-nexus"
    "app-misc/dgop::gentoo-nexus"
    "sys-apps/danksearch::gentoo-nexus"
    "gui-apps/foot"
)

case $dm_choice in
    1) INSTALL_LIST+=( "x11-misc/ly" ) ;;
    2) INSTALL_LIST+=( "x11-misc/sddm" ) ;;
    3) INSTALL_LIST+=( "gui-libs/greetd" "gui-apps/tuigreet" ) ;;
    4) ;; 
esac

[[ "${matugen_choice,,}" == "y" ]]  && INSTALL_LIST+=( "x11-misc/matugen::gentoo-nexus" )
[[ "${steam_choice,,}" == "y" ]]    && INSTALL_LIST+=( "games-util/steam-launcher" )
[[ "${games_choice,,}" == "y" ]]    && INSTALL_LIST+=( "games-util/protonplus-bin::gentoo-nexus" "games-util/heroic-bin" )
[[ "${vesktop_choice,,}" == "y" ]]  && INSTALL_LIST+=( "net-im/vesktop-bin" )
[[ "${rootapp_choice,,}" == "y" ]]  && INSTALL_LIST+=( "app-misc/rootapp-bin::gentoo-nexus" )
[[ "${NEED_WIFI}" == "yes" ]]       && INSTALL_LIST+=( "net-wireless/iwd" "net-wireless/wpa_supplicant" )

INSTALL_LIST+=(
    "gui-apps/wl-clipboard"
    "gui-apps/swaync"
    "app-misc/cliphist"
    "media-sound/cava"
    "gui-apps/foot"
    "app-editors/nano"
    "sys-apps/ripgrep"
)

BIN_OPTS="--getbinpkg --usepkg --binpkg-respect-use=n --keep-going --autounmask=y --autounmask-write --autounmask-keep-masks=n"

emerge --oneshot --quiet sys-fs/eudev virtual/udev || true

set +e
emerge ${BIN_OPTS} "${INSTALL_LIST[@]}"
AUTOUNMASK_EXIT=$?
set -e

if [[ $AUTOUNMASK_EXIT -ne 0 ]] && [[ $AUTOUNMASK_EXIT -ne 1 ]]; then
    log_msg "${R}[!] ERROR: emerge --autounmask-write failed (Exit Code: ${AUTOUNMASK_EXIT})${C}"
    exit 1
fi

etc-update --automode -5 2>/dev/null || true
emerge ${BIN_OPTS} --update --newuse "${INSTALL_LIST[@]}"

#==============================================================================
# POST-INSTALL CONFIGURATION
#==============================================================================
log_msg "\n${B}>>> [8/8] POST-INSTALL CONFIGURATION...${C}"

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

case $dm_choice in
    1) rc-update add ly default  2>/dev/null || true ;;
    2) rc-update add sddm default 2>/dev/null || true ;;
    3) rc-update add greetd default 2>/dev/null || true ;;
    4)
        mkdir -p /etc/conf.d
        sed -i "s/^#*agetty_options_tty1=.*/agetty_options_tty1=\"--autologin ${username}\"/" /etc/conf.d/agetty.tty1 2>/dev/null || true
        ;;
esac

log_msg "\n${B}>>> BOOTLOADER DEPLOYMENT...${C}"
if mountpoint -q /boot/efi 2>/dev/null; then
    if grep -q '/boot/efi.*vfat' /proc/mounts; then
        log_msg "${B}>>> DETECTED VALID FAT32 EFI PARTITION. DEPLOYING GRUB...${C}"
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo || log_msg "${Y}[!] grub-install failed. Please run manually.${C}"
        grub-mkconfig -o /boot/grub/grub.cfg || log_msg "${Y}[!] grub-mkconfig failed. Please run manually.${C}"
    else
        log_msg "${Y}[!] /boot/efi mounted but is not FAT32 (vfat). Run grub-install manually.${C}"
    fi
else
    log_msg "${Y}[!] /boot/efi not mounted. Run grub-install and grub-mkconfig manually.${C}"
fi

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen 2>/dev/null || true

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
log_msg "  3. dracut --hostonly --kver \$(ls /lib/modules | tail -1)"
log_msg "  4. Exit chroot, unmount, reboot"
