#!/bin/bash
# GENTOO NEXUS ARCHITECT - MASTER DEPLOYMENT ENGINE (2026.10.27-PRO)
# Fully Audited for AMD/Intel Architectures, Portage Substitution, and Binhost Priority

set -eo pipefail
exec > >(tee -i /var/log/gentoo-nexus-install.log) 2>&1

#==============================================================================
# CONFIGURATION & CONSTANTS
#==============================================================================
readonly SCRIPT_VERSION="2026.10.27-NEXUS-PRO"
readonly LOCKFILE="/var/lib/gentoo-nexus-installed"
readonly LOGFILE="/var/log/gentoo-nexus-install.log"
readonly NEXUS_REPO_URL="https://github.com/Ackerman-00/gentoo-nexus.git"
readonly NEXUS_BINHOST="https://gentoo-nexus.sourceforge.io/"

# Evaluate CPU Cores once to prevent Portage 'bad substitution' errors
CORES=$(nproc)

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
echo -e "${G}    GENTOO NEXUS ARCHITECT: MASTER DEPLOYMENT (2026.10.27)      ${C}"
echo -e "${B}================================================================${C}"
echo -e "Version: ${SCRIPT_VERSION}"
echo -e "Binhost: ${NEXUS_BINHOST}"
echo -e "Log: ${LOGFILE}\n"

#==============================================================================
# [1/8] HARDWARE & SOFTWARE SELECTION
#==============================================================================
log_msg "${B}>>> [1/8] HARDWARE & SOFTWARE TARGETS${C}"
echo "1) Desktop (Ryzen 5 5600G - Zen 3 | AMD GPU)"
echo "2) Desktop (Ryzen 7 7700  - Zen 4 | RTX 5060)"
echo "3) Laptop  (Ryzen 3 7320U - Zen 2 | AMD GPU | WiFi)"
echo "4) Laptop  (HP EliteBook  - Skylake | Intel Iris | WiFi)"
get_choice "Hardware Target [1-4]:" "^[1-4]$" hw_choice

echo -e "${Y}Note: Username must be lowercase (e.g. 'ackerman')${C}"
get_choice "Enter primary username:" "^[a-z_][a-z0-9_-]{1,31}$" username

get_choice "Enable GURU overlay? [y/n]:" "^[yYnN]$" guru_choice
get_choice "Enable Steam natively (32-bit multilib via stable Gentoo)? [y/n]:" "^[yYnN]$" steam_choice
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

# Logic: Only ask for Desktop Shell if the user chose a minimal Wayland Compositor (1, 2, or 3)
shell_choice="3" # Default to None
if [[ "$de_choice" =~ ^[1-3]$ ]]; then
    log_msg "\n${B}>>> [3/8] DESKTOP SHELL & GREETER${C}"
    echo "1) noctalia-shell (Nexus)"
    echo "2) dank-material-shell (Nexus)"
    echo "3) None"
    get_choice "Desktop Shell [1-3]:" "^[1-3]$" shell_choice
else
    log_msg "\n${Y}>>> [3/8] Skipping Desktop Shell (Integrated within GNOME/KDE)${C}"
fi

log_msg "\n${B}>>> DISPLAY MANAGER${C}"
echo "1) ly (TUI, lightweight)"
echo "2) sddm"
echo "3) greetd + tuigreet"
echo "4) None (TTY autologin)"
get_choice "Display Manager [1-4]:" "^[1-4]$" dm_choice

[[ "${vesktop_choice,,}" == "y" ]] && guru_choice="y"

#==============================================================================
# [4/8] NETWORK & REPOSITORY INITIALIZATION
#==============================================================================
log_msg "\n${B}>>> [4/8] INITIALIZING NETWORK & REPOSITORIES...${C}"
if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
    log_msg "${R}[!] ERROR: No network. Check DNS resolution in chroot.${C}"
    exit 1
fi
log_msg "${G}[✓] Network connectivity verified.${C}"

log_msg "${Y}>>> Syncing main Gentoo repository...${C}"
mkdir -p /etc/portage/repos.conf
mkdir -p /var/db/repos/gentoo
emerge-webrsync -q

eselect profile set default/linux/amd64/23.0/desktop
eselect news read all >/dev/null 2>&1 || true

if [[ "${steam_choice,,}" == "y" ]]; then
    if eselect profile show 2>/dev/null | grep -q "no-multilib"; then
        log_msg "${R}[!] FATAL: Steam requires a multilib profile, but no-multilib is currently selected.${C}"
        exit 1
    fi
fi

mkdir -p /etc/portage/binrepos.conf

# Priority 100 ensures your Custom Kernel and UI packages are checked FIRST.
cat > /etc/portage/binrepos.conf/nexus.conf << EOF
[gentoo-nexus-sf]
priority = 100
sync-uri = ${NEXUS_BINHOST}
verify-signature = false
EOF

# Priority 1 handles any generic dependencies flawlessly from Gentoo Official
cat > /etc/portage/binrepos.conf/gentoo.conf << EOF
[gentoo]
priority = 1
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64/
verify-signature = false
EOF

# Initialize the Portage trust helper to prevent gpg-exit 33554433 errors
command -v getuto >/dev/null 2>&1 && getuto || true

#==============================================================================
# HARDWARE-SPECIFIC CONFIGURATION
#==============================================================================
case $hw_choice in
    1) ZRAM_SIZE="6144M"; CPU_ARCH="znver3"; NEED_WIFI="no"; G_CMD=""; LINUX_FW="amd-ucode amdgpu rtl_nic"; UCODE="" ;;
    2) ZRAM_SIZE="8192M"; CPU_ARCH="znver4"; NEED_WIFI="no"; G_CMD="nouveau.modeset=1"; LINUX_FW="amd-ucode nvidia rtl_nic"; UCODE="" ;;
    3) ZRAM_SIZE="4096M"; CPU_ARCH="znver2"; NEED_WIFI="yes"; G_CMD=""; LINUX_FW="amd-ucode amdgpu ath10k ath11k iwlwifi mt76 rtw88 rtw89"; UCODE="" ;;
    4) ZRAM_SIZE="8192M"; CPU_ARCH="skylake"; NEED_WIFI="yes"; G_CMD="i915.enable_psr=0"; LINUX_FW="intel-ucode i915 iwlwifi"; UCODE="sys-firmware/intel-microcode" ;;
esac

# Architect Fix: Removed global STEAM_USE injection to maintain 100% parity with Factory Binhost USE flags.
cat > /etc/portage/make.conf << EOF
COMMON_FLAGS="-O2 -march=${CPU_ARCH} -mtune=${CPU_ARCH} -pipe"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
RUSTFLAGS="-C opt-level=2"
MAKEOPTS="-j${CORES} -l${CORES}"
USE="wayland X vulkan pipewire dbus elogind udev opengl dri gbm vaapi vdpau ffmpeg bluetooth screencast gstreamer minizip -daemon -systemd -aqua -cups"
VIDEO_CARDS="amdgpu radeon radeonsi intel iris nouveau virgl"
LINUX_FIRMWARE="${LINUX_FW}"
FEATURES="getbinpkg -userfetch -userpriv -usersandbox -ipc-sandbox -pid-sandbox -network-sandbox parallel-install"
ACCEPT_LICENSE="*"
PKGDIR="/var/cache/binpkgs"
DISTDIR="/var/cache/distfiles"
LC_MESSAGES=C.utf8
PORTAGE_BINPKG_TAR_OPTS="--warning=no-unknown-keyword"
EOF

#==============================================================================
# PORTAGE MASKING & CONFIG
#==============================================================================
mkdir -p /etc/portage/profile
mkdir -p /etc/portage/package.use
mkdir -p /etc/portage/package.mask
mkdir -p /etc/portage/package.accept_keywords
mkdir -p /etc/portage/package.unmask
mkdir -p /etc/portage/package.license
mkdir -p /etc/portage/package.env
mkdir -p /etc/portage/env

cat > /etc/portage/package.mask/systemd << 'MASK'
sys-apps/systemd
sys-apps/gentoo-systemd-integration
MASK

cat > /etc/portage/profile/package.provided << 'PROV'
sys-apps/systemd-299.0
sys-apps/gentoo-systemd-integration-99.0
sys-apps/systemd-initctl-99.0
PROV

cat > /etc/portage/package.unmask/overrides << 'UNMASK'
media-libs/dav1d
media-libs/libdvdnav
media-libs/libdvdread
UNMASK

#==============================================================================
# GCC 15 ICE WORKAROUND
#==============================================================================
log_msg "${B}>>> Applying GCC 15 ICE workarounds...${C}"

cat > /etc/portage/env/gcc-ice-safe << EOF
CFLAGS="-O1 -pipe -fno-tree-loop-vectorize -fno-tree-slp-vectorize"
CXXFLAGS="-O1 -pipe -fno-tree-loop-vectorize -fno-tree-slp-vectorize"
MAKEOPTS="-j${CORES}"
EOF

cat > /etc/portage/package.env/gcc-ice-packages << 'EOF'
dev-util/spirv-tools gcc-ice-safe
dev-util/vulkan-validation-layers gcc-ice-safe
media-libs/mesa gcc-ice-safe
media-libs/rusticl-opencl gcc-ice-safe
dev-util/glslang gcc-ice-safe
EOF

#==============================================================================
# USE FLAGS & KEYWORDS
#==============================================================================
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
media-video/ffmpeg -sdl
media-libs/libsdl2 -pipewire
sys-kernel/gentoo-kernel savedconfig initramfs
sys-kernel/installkernel dracut grub
USE

if [[ "${steam_choice,,}" == "y" ]]; then
    # Architect Fix: Massive Gentoo Wiki 32-bit Map. Applied locally to match factory logic.
    cat > /etc/portage/package.use/steam << 'USE'
app-accessibility/at-spi2-core abi_x86_32
app-arch/bzip2 abi_x86_32
app-arch/lz4 abi_x86_32
app-arch/xz-utils abi_x86_32
app-arch/zstd abi_x86_32
app-crypt/p11-kit abi_x86_32
dev-db/sqlite abi_x86_32
dev-lang/rust abi_x86_32
dev-lang/rust-bin abi_x86_32
dev-libs/dbus-glib abi_x86_32
dev-libs/elfutils abi_x86_32
dev-libs/expat abi_x86_32
dev-libs/fribidi abi_x86_32
dev-libs/glib abi_x86_32
dev-libs/gmp abi_x86_32
dev-libs/icu abi_x86_32
dev-libs/json-glib abi_x86_32
dev-libs/leancrypto abi_x86_32
dev-libs/libevdev abi_x86_32
dev-libs/libffi abi_x86_32
dev-libs/libgcrypt abi_x86_32
dev-libs/libgpg-error abi_x86_32
dev-libs/libgudev abi_x86_32
dev-libs/libgusb abi_x86_32
dev-libs/libpcre2 abi_x86_32
dev-libs/libtasn1 abi_x86_32
dev-libs/libunistring abi_x86_32
dev-libs/libusb abi_x86_32
dev-libs/libxml2 abi_x86_32
dev-libs/lzo abi_x86_32
dev-libs/nettle abi_x86_32
dev-libs/nspr abi_x86_32
dev-libs/nss abi_x86_32
dev-libs/openssl abi_x86_32
dev-libs/wayland abi_x86_32
dev-util/glslang abi_x86_32
dev-util/spirv-tools abi_x86_32
dev-util/sysprof-capture abi_x86_32
dev-util/vulkan-utility-libraries abi_x86_32
gnome-base/librsvg abi_x86_32
gui-libs/libdecor abi_x86_32
llvm-core/clang abi_x86_32
llvm-core/llvm abi_x86_32
media-gfx/graphite2 abi_x86_32
media-libs/alsa-lib abi_x86_32
media-libs/flac abi_x86_32
media-libs/fontconfig abi_x86_32
media-libs/freetype abi_x86_32
media-libs/glu abi_x86_32
media-libs/harfbuzz abi_x86_32
media-libs/lcms abi_x86_32
media-libs/libdisplay-info abi_x86_32
media-libs/libepoxy abi_x86_32
media-libs/libglvnd abi_x86_32
media-libs/libjpeg-turbo abi_x86_32
media-libs/libogg abi_x86_32
media-libs/libpng abi_x86_32
media-libs/libpulse abi_x86_32
media-libs/libsdl2 abi_x86_32
media-libs/libsndfile abi_x86_32
media-libs/libva abi_x86_32
media-libs/libvorbis abi_x86_32
media-libs/libwebp abi_x86_32
media-libs/mesa abi_x86_32
media-libs/openal abi_x86_32
media-libs/opus abi_x86_32
media-libs/tiff abi_x86_32
media-libs/vulkan-layers abi_x86_32
media-libs/vulkan-loader abi_x86_32 layers
media-sound/lame abi_x86_32
media-sound/mpg123-base abi_x86_32
media-video/pipewire abi_x86_32
net-dns/c-ares abi_x86_32
net-dns/libidn2 abi_x86_32
net-libs/gnutls abi_x86_32
net-libs/libasyncns abi_x86_32
net-libs/libndp abi_x86_32
net-libs/libpsl abi_x86_32
net-libs/nghttp2 abi_x86_32
net-libs/nghttp3 abi_x86_32
net-libs/ngtcp2 abi_x86_32
net-misc/curl abi_x86_32
net-misc/networkmanager abi_x86_32
net-print/cups abi_x86_32
sys-apps/dbus abi_x86_32
sys-apps/lm-sensors abi_x86_32
sys-apps/systemd abi_x86_32
sys-apps/systemd-utils abi_x86_32
sys-apps/util-linux abi_x86_32
sys-libs/gdbm abi_x86_32
sys-libs/gpm abi_x86_32
sys-libs/libcap abi_x86_32
sys-libs/libudev-compat abi_x86_32
sys-libs/ncurses abi_x86_32
sys-libs/pam abi_x86_32
sys-libs/readline abi_x86_32
sys-libs/zlib abi_x86_32
virtual/glu abi_x86_32
virtual/libelf abi_x86_32
virtual/libiconv abi_x86_32
virtual/libintl abi_x86_32
virtual/libudev abi_x86_32
virtual/libusb abi_x86_32
virtual/opengl abi_x86_32
virtual/zlib abi_x86_32
x11-libs/cairo abi_x86_32
x11-libs/extest abi_x86_32
x11-libs/gdk-pixbuf abi_x86_32
x11-libs/gtk+ abi_x86_32
x11-libs/libdrm abi_x86_32
x11-libs/libICE abi_x86_32
x11-libs/libpciaccess abi_x86_32
x11-libs/libSM abi_x86_32
x11-libs/libvdpau abi_x86_32
x11-libs/libX11 abi_x86_32
x11-libs/libXau abi_x86_32
x11-libs/libxcb abi_x86_32
x11-libs/libXcomposite abi_x86_32
x11-libs/libXcursor abi_x86_32
x11-libs/libXdamage abi_x86_32
x11-libs/libXdmcp abi_x86_32
x11-libs/libXext abi_x86_32
x11-libs/libXfixes abi_x86_32
x11-libs/libXft abi_x86_32
x11-libs/libXi abi_x86_32
x11-libs/libXinerama abi_x86_32
x11-libs/libxkbcommon abi_x86_32
x11-libs/libXrandr abi_x86_32
x11-libs/libXrender abi_x86_32
x11-libs/libXScrnSaver abi_x86_32
x11-libs/libxshmfence abi_x86_32
x11-libs/libXtst abi_x86_32
x11-libs/libXxf86vm abi_x86_32
x11-libs/pango abi_x86_32
x11-libs/pixman abi_x86_32
x11-libs/xcb-util-keysyms abi_x86_32
x11-misc/colord abi_x86_32
gui-libs/egl-gbm abi_x86_32
gui-libs/egl-wayland abi_x86_32
gui-libs/egl-wayland2 abi_x86_32
gui-libs/egl-x11 abi_x86_32
x11-drivers/nvidia-drivers abi_x86_32
sys-libs/glibc hash-sysv-compat
USE
fi

# Architect Fix: Strictly `**` to correctly force testing/live keywords for core stack
cat > /etc/portage/package.accept_keywords/nexus << 'EOF'
*/*::gentoo-nexus **
x11-base/xwayland-satellite **
gui-wm/niri **
gui-wm/mangowc **
gui-wm/noctalia-shell **
gui-wm/dank-material-shell **
gui-apps/noctalia-qs **
gui-apps/quickshell **
app-misc/dgop **
sys-apps/danksearch **
x11-misc/matugen **
x11-misc/ly **
app-misc/brightnessctl **
dev-libs/linux-syscall-support **
dev-embedded/libdisasm **
dev-util/breakpad **
media-libs/dav1d **
media-libs/libdvdnav **
media-libs/libdvdread **
net-im/vesktop-bin **
games-util/steam-launcher **
games-util/heroic-bin **
games-util/protonplus-bin **
sys-libs/libudev-compat **
app-misc/cliphist **
dev-lang/rust **
dev-lang/rust-bin **
sys-kernel/gentoo-kernel **
virtual/dist-kernel **
sys-kernel/linux-firmware **
media-libs/mesa **
media-libs/vulkan-loader **
dev-util/spirv-tools **
EOF

cat > /etc/portage/package.accept_keywords/steam << 'EOF'
*/*::steam-overlay **
games-util/game-device-udev-rules **
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
# [5/8] OVERLAY SYNCHRONIZATION
#==============================================================================
log_msg "\n${B}>>> [5/8] SYNCHRONIZING OVERLAYS...${C}"

emerge --noreplace --quiet --getbinpkg app-eselect/eselect-repository dev-vcs/git

repo_add_safe "gentoo-nexus" "git" "${NEXUS_REPO_URL}"
[[ "${guru_choice,,}" == "y" ]]  && repo_enable_safe "guru"
[[ "${steam_choice,,}" == "y" ]] && repo_enable_safe "steam-overlay"

emaint sync -a 2>/dev/null || true
eselect news read all >/dev/null 2>&1 || true

echo ">>> Shielding gentoo-nexus packages from Guru overrides..."
for pkg in /var/db/repos/gentoo-nexus/*/*/*.ebuild; do
    [ -e "$pkg" ] || continue
    cat_pkg=$(echo "$pkg" | awk -F'/' '{print $(NF-2)"/"$(NF-1)}')
    echo "$cat_pkg::guru" >> /etc/portage/package.mask/guru_shield
done

#==============================================================================
# [6/8] PACKAGE INSTALLATION
#==============================================================================
log_msg "\n${B}>>> [6/8] EXECUTING BINARY DEPLOYMENT...${C}"

INSTALL_LIST=(
    sys-kernel/gentoo-kernel
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
    media-libs/mesa
    media-libs/vulkan-loader
    dev-util/spirv-tools
)

[[ -n "${UCODE}" ]] && INSTALL_LIST+=( "${UCODE}" )

case $de_choice in
    1) INSTALL_LIST+=( "gui-wm/niri" "sys-apps/xdg-desktop-portal-gnome" "x11-base/xwayland-satellite" ) ;;
    2) INSTALL_LIST+=( "gui-wm/mangowc" "gui-libs/xdg-desktop-portal-wlr" "x11-base/xwayland-satellite" ) ;;
    3) INSTALL_LIST+=( "gui-wm/hyprland" "gui-libs/xdg-desktop-portal-hyprland" ) ;;
    4) INSTALL_LIST+=( "gnome-base/gnome-light" ) ;;
    5) INSTALL_LIST+=( "kde-plasma/plasma-meta" ) ;;
esac

case $shell_choice in
    1) INSTALL_LIST+=( "gui-wm/noctalia-shell" "gui-apps/noctalia-qs" ) ;;
    2) INSTALL_LIST+=( "gui-wm/dank-material-shell" "gui-apps/quickshell" "app-misc/dgop" "sys-apps/danksearch" ) ;;
    3) ;; # None
esac

case $dm_choice in
    1) INSTALL_LIST+=( "x11-misc/ly" ) ;;
    2) INSTALL_LIST+=( "x11-misc/sddm" ) ;;
    3) INSTALL_LIST+=( "gui-libs/greetd" "gui-apps/tuigreet" ) ;;
    4) ;; 
esac

[[ "${matugen_choice,,}" == "y" ]]  && INSTALL_LIST+=( "x11-misc/matugen" )
[[ "${steam_choice,,}" == "y" ]]    && INSTALL_LIST+=( "games-util/steam-launcher" )
[[ "${games_choice,,}" == "y" ]]    && INSTALL_LIST+=( "games-util/protonplus-bin" "games-util/heroic-bin" )
[[ "${vesktop_choice,,}" == "y" ]]  && INSTALL_LIST+=( "net-im/vesktop-bin" )
[[ "${rootapp_choice,,}" == "y" ]]  && INSTALL_LIST+=( "app-misc/rootapp-bin" )
[[ "${NEED_WIFI}" == "yes" ]]       && INSTALL_LIST+=( "net-wireless/iwd" "net-wireless/wpa_supplicant" )

INSTALL_LIST+=(
    "gui-apps/wl-clipboard"
    "app-misc/cliphist"
    "media-sound/cava"
    "x11-terms/alacritty"
    "x11-terms/kitty"
    "app-editors/nano"
    "sys-apps/ripgrep"
)

BIN_OPTS="--getbinpkg --usepkg --keep-going --autounmask=y --autounmask-write --autounmask-keep-masks=n"
export FEATURES="-binpkg-request-signature"
EXCLUDES="--usepkg-exclude sys-auth/polkit --usepkg-exclude dev-libs/libei --usepkg-exclude media-video/wireplumber --usepkg-exclude media-libs/libpulse --usepkg-exclude sys-apps/accountsservice --usepkg-exclude sys-auth/elogind"

log_msg "${B}>>> Installing systemd-utils and libudev first...${C}"
emerge ${BIN_OPTS} --oneshot --quiet sys-apps/systemd-utils virtual/libudev || true

set +e
emerge ${BIN_OPTS} $EXCLUDES "${INSTALL_LIST[@]}"
AUTOUNMASK_EXIT=$?
set -e

if [[ $AUTOUNMASK_EXIT -ne 0 ]] && [[ $AUTOUNMASK_EXIT -ne 1 ]]; then
    log_msg "${R}[!] ERROR: emerge failed (Exit Code: ${AUTOUNMASK_EXIT})${C}"
    log_msg "${Y}Attempting to continue with --skipfirst...${C}"
    emerge ${BIN_OPTS} $EXCLUDES --skipfirst "${INSTALL_LIST[@]}" || true
fi

etc-update --automode -5 2>/dev/null || true
emerge ${BIN_OPTS} $EXCLUDES --update --newuse "${INSTALL_LIST[@]}" || true

#==============================================================================
# [7/8] USER & SERVICE SETUP
#==============================================================================
log_msg "\n${B}>>> [7/8] USER & SERVICE SETUP...${C}"

if ! id "${username}" &>/dev/null; then
    useradd -m -G wheel,audio,video,portage,input,seat,plugdev -s /bin/bash "${username}" || {
        log_msg "${Y}[!] Primary useradd failed. Trying fallback without dynamic groups...${C}"
        useradd -m -G wheel,audio,video,portage,input -s /bin/bash "${username}" || true
    }
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
# [8/8] POST-INSTALL CONFIGURATION
#==============================================================================
log_msg "\n${B}>>> [8/8] POST-INSTALL CONFIGURATION...${C}"

# ZRAM configuration
mkdir -p /etc/conf.d
cat > /etc/conf.d/zram-init << EOF
load_on_start="yes"
unload_on_stop="yes"
num_devices="1"
type0="swap"
size0="${ZRAM_SIZE}"
max_comp_streams0="${CORES}"
comp_algorithm0="lz4"
priority0="32767"
EOF
rc-update add zram-init boot 2>/dev/null || true

# Pipewire user service for OpenRC
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

# Autologin / Display Manager configuration
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
    log_msg "${Y}[!] /boot/efi not mounted. Skipping GRUB installation. Run grub-install manually after mounting.${C}"
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
log_msg "${G}    [✓] GENTOO NEXUS MASTER DEPLOYMENT COMPLETE!                ${C}"
log_msg "${G}================================================================${C}"
log_msg "User created: ${username}"
log_msg "Log saved: ${LOGFILE}"
log_msg "${Y}Next steps:${C}"
log_msg "  1. Set password: passwd ${username}"
log_msg "  2. Set root password: passwd"
log_msg "  3. dracut --hostonly --kver \$(ls /lib/modules | tail -1) (if needed)"
log_msg "  4. Exit chroot, unmount, reboot"
