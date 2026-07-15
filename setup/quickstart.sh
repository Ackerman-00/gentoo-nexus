#!/bin/bash
set -eo pipefail
exec > >(tee -i /var/log/gentoo-nexus-install.log) 2>&1

# CONFIG
readonly LOCKFILE="/var/lib/gentoo-nexus-installed"
readonly LOGFILE="/var/log/gentoo-nexus-install.log"
readonly NEXUS_REPO_URL="https://github.com/Ackerman-00/gentoo-nexus.git"
readonly NEXUS_BINHOST="https://github.com/Ackerman-00/gentoo-nexus/releases/download/rolling/"
CORES=$(nproc)

B="\e[1;34m"; G="\e[1;32m"; Y="\e[1;33m"; R="\e[1;31m"; C="\e[0m"

# ERROR HANDLING
INSTALL_COMPLETE="false"
trap 'log_msg "\n${R}[!] FATAL on line $LINENO (exit $?)${C}"; exit $?' ERR
trap '[[ -f "$LOCKFILE" && "$INSTALL_COMPLETE" != "true" ]] && rm -f "$LOCKFILE"' EXIT

[ "$EUID" -ne 0 ] && echo -e "${R}[!] Run as root${C}" && exit 1

# HELPERS
log_msg() {
    echo -e "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $(echo -e "$1" | sed -r 's/\x1B\[[0-9;]*[mK]//g')" >> "$LOGFILE"
}

get_choice() {
    local prompt="$1" valid_regex="$2" var_name="$3" choice
    while true; do
        read -rp "$(echo -e "${Y}${prompt}${C}") " choice
        [[ "$choice" =~ $valid_regex ]] && eval "$var_name=\"$choice\"" && break
        echo -e "${R}[!] Invalid${C}"
    done
}

repo_add_safe() {
    local name="$1" type="$2" url="$3"
    if [[ -d "/var/db/repos/${name}" ]] || eselect repository list 2>/dev/null | grep -q "\b${name}\b"; then
        log_msg "${Y}[~] '${name}' exists, skipping${C}"
    else
        eselect repository add "${name}" "${type}" "${url}" || true
    fi
}

repo_enable_safe() {
    local name="$1"
    if [[ -d "/var/db/repos/${name}" ]] || eselect repository list 2>/dev/null | grep -q "\b${name}\b"; then
        log_msg "${Y}[~] '${name}' enabled, skipping${C}"
    else
        eselect repository enable "${name}" || true
    fi
}

# DETECT ENVIRONMENT
IN_CHROOT=false
if mountpoint -q /mnt/gentoo/proc 2>/dev/null || [ -f /mnt/gentoo/etc/profile ] || [ -f /etc/gentoo-release ]; then
    IN_CHROOT=true
fi

# PARTITIONING (LiveCD only)
if [ "$IN_CHROOT" = false ]; then
    echo -e "${B}========================================${C}"
    echo -e "${G}   GENTOO NEXUS QUICKSTART (LiveCD)     ${C}"
    echo -e "${B}========================================${C}"
    echo ""
    echo "1) Partition with cfdisk"
    echo "2) Skip (partitions ready)"
    read -rp "Choice [1-2]: " part_choice

    if [ "$part_choice" = "1" ]; then
        echo ""
        echo -e "${Y}Available disks:${C}"
        lsblk -d -o NAME,SIZE,TYPE,MODEL | grep -v loop
        read -rp "Disk device (e.g., nvme0n1, sda): " disk_device

        echo -e "${Y}Create: 1) EFI ~1G  2) Swap ~16G  3) Root x86-64 (rest)${C}"
        read -rp "Press Enter for cfdisk..."
        cfdisk "/dev/$disk_device"

        EFI_PART=""; SWAP_PART=""; ROOT_PART=""
        while IFS=' ' read -r name type parttype; do
            [ "$type" != "part" ] && continue
            parttype=$(echo "$parttype" | tr '[:upper:]' '[:lower:]')
            case "$parttype" in
                c12a7328*) EFI_PART="/dev/$name" ;;
                0657fd6d*) SWAP_PART="/dev/$name" ;;
                4f68bce3*|0fc63daf*) ROOT_PART="/dev/$name" ;;
            esac
        done < <(lsblk -ln -o NAME,TYPE,PARTTYPE "/dev/$disk_device" 2>/dev/null)

        if [ -z "$EFI_PART$SWAP_PART$ROOT_PART" ]; then
            while IFS=' ' read -r name type fstype; do
                [ "$type" != "part" ] && continue
                case "$fstype" in vfat) EFI_PART="/dev/$name" ;; swap) SWAP_PART="/dev/$name" ;; xfs|ext4) ROOT_PART="/dev/$name" ;; esac
            done < <(lsblk -ln -o NAME,TYPE,FSTYPE "/dev/$disk_device" 2>/dev/null)
        fi

        [ -z "$EFI_PART" ] && read -rp "EFI partition: " e && EFI_PART="/dev/$e"
        [ -z "$SWAP_PART" ] && read -rp "Swap partition: " s && SWAP_PART="/dev/$s"
        [ -z "$ROOT_PART" ] && read -rp "Root partition: " r && ROOT_PART="/dev/$r"

        echo "EFI: $EFI_PART  Swap: $SWAP_PART  Root: $ROOT_PART"
        read -rp "Format? [y/n]: " confirm
        [ "${confirm,,}" != "y" ] && exit 1

        mkfs.fat -F 32 "$EFI_PART"
        mkswap "$SWAP_PART"; swapon "$SWAP_PART"
        mkfs.xfs -f "$ROOT_PART"
        mount "$ROOT_PART" /mnt/gentoo
        mkdir -p /mnt/gentoo/boot/efi && mount "$EFI_PART" /mnt/gentoo/boot/efi
    fi

    if [ ! -f /mnt/gentoo/stage3-*.tar.xz ] && [ ! -d /mnt/gentoo/etc ]; then
        echo -e "${B}>>> Downloading stage3...${C}"
        STAGE3_PAGE=$(curl -sL https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc/ 2>/dev/null | grep -oP 'stage3-amd64-desktop-openrc-[^"]+\.tar\.xz' | head -1 || true)
        if [ -n "$STAGE3_PAGE" ]; then
            curl -L "https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc/${STAGE3_PAGE}" -o "/mnt/gentoo/${STAGE3_PAGE}"
        else
            echo -e "${R}[!] Place stage3 in /mnt/gentoo/ manually${C}"; exit 1
        fi
    fi
    if [ ! -d /mnt/gentoo/etc ]; then
        echo -e "${B}>>> Extracting stage3...${C}"
        tar xpvf /mnt/gentoo/stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
    fi

    cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
    for d in proc sys dev run; do mount --rbind "/$d" "/mnt/gentoo/$d" && mount --make-rslave "/mnt/gentoo/$d" 2>/dev/null || true; done

    cp "$(readlink -f "$0")" /mnt/gentoo/root/quickstart.sh
    echo -e "${G}>>> Chrooting...${C}"
    chroot /mnt/gentoo /bin/bash /root/quickstart.sh
    exit $?
fi

# INSIDE CHROOT
clear 2>/dev/null || printf "\033c"
echo -e "${B}========================================${C}"
echo -e "${G}   GENTOO NEXUS QUICKSTART${C}"
echo -e "${B}========================================${C}"
echo "Binhost: $NEXUS_BINHOST"
echo ""

if [[ -f "$LOCKFILE" ]]; then
    echo -e "${R}[!] Lockfile exists. Remove: rm ${LOCKFILE}${C}"
    exit 1
fi
mkdir -p "$(dirname "$LOCKFILE")"
echo "Install started: $(date)" > "$LOCKFILE"

:

# 1. HARDWARE & SOFTWARE
echo -e "${B}>>> HARDWARE TARGET${C}"
echo "1) Desktop  (Ryzen 5 5600G  - Zen 3 | AMD GPU)"
echo "2) Desktop  (Ryzen 7 7700   - Zen 4 | RTX 5060)"
echo "3) Laptop   (Ryzen 3 7320U  - Zen 2 | AMD GPU | WiFi)"
echo "4) Laptop   (HP EliteBook   - Skylake | Intel Iris | WiFi)"
get_choice "Target [1-4]:" "^[1-4]$" hw_choice

echo -e "${Y}Username must be lowercase${C}"
get_choice "Username:" "^[a-z_][a-z0-9_-]{1,31}$" username

get_choice "GURU overlay? [y/n]:" "^[yYnN]$" guru_choice
get_choice "Steam (32-bit multilib)? [y/n]:" "^[yYnN]$" steam_choice
get_choice "Heroic & ProtonPlus? [y/n]:" "^[yYnN]$" games_choice
get_choice "Vesktop? [y/n]:" "^[yYnN]$" vesktop_choice
get_choice "RootApp? [y/n]:" "^[yYnN]$" rootapp_choice
get_choice "Matugen (Material You colors)? [y/n]:" "^[yYnN]$" matugen_choice

# COMPOSITOR
echo -e "${B}>>> COMPOSITOR${C}"
echo "1) niri"
echo "2) mangowm"
echo "3) Hyprland"
echo "4) GNOME"
echo "5) KDE Plasma"
get_choice "Compositor [1-5]:" "^[1-5]$" de_choice

shell_choice="3"
if [[ "$de_choice" =~ ^[1-3]$ ]]; then
    echo -e "${B}>>> DESKTOP SHELL${C}"
    echo "1) noctalia-shell"
    echo "2) dank-material-shell"
    echo "3) None"
    get_choice "Shell [1-3]:" "^[1-3]$" shell_choice
fi

echo -e "${B}>>> DISPLAY MANAGER${C}"
echo "1) ly"
echo "2) sddm"
echo "3) greetd + tuigreet"
echo "4) None (TTY autologin)"
get_choice "DM [1-4]:" "^[1-4]$" dm_choice

[[ "${vesktop_choice,,}" == "y" ]] && guru_choice="y"

# HARDWARE CONFIG
case $hw_choice in
    1) ZRAM_SIZE="6144M"; CPU_ARCH="znver3"; NEED_WIFI="no"; G_CMD="";
       LINUX_FW="amd-ucode amdgpu rtl_nic"; UCODE="" ;;
    2) ZRAM_SIZE="8192M"; CPU_ARCH="znver4"; NEED_WIFI="no"; G_CMD="nouveau.modeset=1";
       LINUX_FW="amd-ucode nvidia rtl_nic"; UCODE="" ;;
    3) ZRAM_SIZE="4096M"; CPU_ARCH="znver2"; NEED_WIFI="yes"; G_CMD="";
       LINUX_FW="amd-ucode amdgpu ath10k ath11k iwlwifi mt76 rtw88 rtw89"; UCODE="" ;;
    4) ZRAM_SIZE="8192M"; CPU_ARCH="skylake"; NEED_WIFI="yes"; G_CMD="i915.enable_psr=0";
       LINUX_FW="intel-ucode i915 iwlwifi"; UCODE="sys-firmware/intel-microcode" ;;
esac

# 2. NETWORK & REPOS
echo -e "${B}>>> NETWORK & REPOS${C}"
if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
    echo -e "${R}[!] No network${C}"; exit 1
fi

mkdir -p /etc/portage/repos.conf /var/db/repos/gentoo /etc/portage/binrepos.conf
emerge-webrsync -q

eselect profile set default/linux/amd64/23.0/desktop/elogind 2>/dev/null || \
eselect profile set default/linux/amd64/23.0/desktop 2>/dev/null || \
eselect profile list 2>/dev/null | grep -m1 "desktop" | grep -m1 "elogind\|openrc" | awk '{print $1}' | tr -d '[]' | xargs -r eselect profile set || \
eselect profile set 1
eselect news read all >/dev/null 2>&1 || true

if [[ "${steam_choice,,}" == "y" ]] && eselect profile show 2>/dev/null | grep -q "no-multilib"; then
    echo -e "${R}[!] Steam needs multilib profile${C}"; exit 1
fi

cat > /etc/portage/binrepos.conf/gentoo-nexus.conf << EOF
[gentoo-nexus]
priority = 100
sync-uri = ${NEXUS_BINHOST}
verify-signature = false
location = /var/cache/binhost/gentoo-nexus
EOF

cat > /etc/portage/binrepos.conf/gentoo.conf << EOF
[gentoo]
priority = 1
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/
verify-signature = true
EOF

command -v getuto >/dev/null 2>&1 && getuto || true

# 3. MAKE.CONF
cat > /etc/portage/make.conf << EOF
COMMON_FLAGS="-O2 -march=${CPU_ARCH} -mtune=${CPU_ARCH} -pipe"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
RUSTFLAGS="-C opt-level=2"
MAKEOPTS="-j${CORES} -l${CORES}"
# ffmpeg codecs are set per-package in package.use (media-video/ffmpeg x264 x265 ...),
# NOT as a global USE flag — this matches the official Gentoo binhost layout.
USE="wayland X vulkan pipewire dbus elogind udev opengl dri gbm vaapi vdpau bluetooth screencast gstreamer minizip -daemon -systemd -aqua -cups"
VIDEO_CARDS="amdgpu radeon radeonsi intel iris nouveau virgl"
# MUST match the x86-64-v3 binhost exactly (CPU_FLAGS_X86 is a USE flag checked by
# --binpkg-respect-use=y); otherwise nexus update rejects the prebuilt binaries.
CPU_FLAGS_X86="avx avx2 f16c fma3 mmx mmxext popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
LINUX_FIRMWARE="${LINUX_FW}"
FEATURES="getbinpkg binpkg-ignore-signature"
ACCEPT_LICENSE="*"
PKGDIR="/var/cache/binpkgs"
DISTDIR="/var/cache/distfiles"
LC_MESSAGES=C.UTF-8
PORTAGE_BINPKG_TAR_OPTS="--warning=no-unknown-keyword"
EOF

echo -e "${B}>>> Updating Portage to latest version${C}"
emerge --oneshot --getbinpkg --usepkg sys-apps/portage 2>&1 | tail -5

# 4. PORTAGE CONFIG
mkdir -p /etc/portage/{profile,package.use,package.mask,package.accept_keywords,package.unmask,package.license,package.env,env}

cat > /etc/portage/package.mask/systemd << 'MASK'
sys-apps/systemd
sys-apps/gentoo-systemd-integration
MASK

cat > /etc/portage/package.unmask/overrides << 'UNMASK'
media-libs/dav1d
media-libs/libdvdnav
media-libs/libdvdread
UNMASK

# GCC 15 ICE WORKAROUND
echo -e "${B}>>> GCC 15 ICE workarounds${C}"
cat > /etc/portage/env/gcc-ice-safe << ICE
CFLAGS="-O1 -pipe -fno-tree-loop-vectorize -fno-tree-slp-vectorize"
CXXFLAGS="-O1 -pipe -fno-tree-loop-vectorize -fno-tree-slp-vectorize"
MAKEOPTS="-j${CORES}"
ICE

cat > /etc/portage/package.env/gcc-ice-packages << 'ICE'
dev-util/spirv-tools gcc-ice-safe
dev-util/vulkan-validation-layers gcc-ice-safe
media-libs/mesa gcc-ice-safe
media-libs/rusticl-opencl gcc-ice-safe
dev-util/glslang gcc-ice-safe
ICE

# USE FLAGS
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

cat > /etc/portage/package.accept_keywords/nexus << 'EOF'
*/*::gentoo-nexus **
x11-base/xwayland-satellite **
gui-wm/niri **
gui-wm/mangowm **
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
net-im/vesktop **
games-util/steam-launcher **
games-util/heroic-bin **
games-util/protonplus **
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

if [[ "${steam_choice,,}" == "y" ]]; then
    cat > /etc/portage/package.accept_keywords/steam << 'EOF'
*/*::steam-overlay **
games-util/game-device-udev-rules **
EOF
fi

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

# 5. OVERLAYS
echo -e "${B}>>> OVERLAYS${C}"
emerge --noreplace --quiet --getbinpkg app-eselect/eselect-repository dev-vcs/git

repo_add_safe "gentoo-nexus" "git" "${NEXUS_REPO_URL}"
[[ "${guru_choice,,}" == "y" ]]  && repo_enable_safe "guru"
[[ "${steam_choice,,}" == "y" ]] && repo_enable_safe "steam-overlay"

emaint sync -a 2>/dev/null || true
eselect news read all >/dev/null 2>&1 || true

for pkg in /var/db/repos/gentoo-nexus/*/*/*.ebuild; do
    [ -e "$pkg" ] || continue
    cat_pkg=$(echo "$pkg" | awk -F'/' '{print $(NF-2)"/"$(NF-1)}')
    echo "$cat_pkg::guru" >> /etc/portage/package.mask/guru_shield 2>/dev/null || true
done

# 6. PACKAGES
echo -e "${B}>>> INSTALLING PACKAGES${C}"
INSTALL_LIST=(
    sys-kernel/gentoo-kernel sys-kernel/linux-firmware sys-kernel/dracut
    sys-boot/grub sys-boot/efibootmgr
    app-admin/doas sys-auth/elogind sys-auth/seatd
    media-video/pipewire media-video/wireplumber
    net-misc/networkmanager sys-power/upower app-misc/jq
    sys-block/zram-init media-libs/mesa media-libs/vulkan-loader dev-util/spirv-tools
)

[[ -n "${UCODE}" ]] && INSTALL_LIST+=( "${UCODE}" )

case $de_choice in
    1) INSTALL_LIST+=( gui-wm/niri sys-apps/xdg-desktop-portal-gnome x11-base/xwayland-satellite ) ;;
    2) INSTALL_LIST+=( gui-wm/mangowm gui-libs/xdg-desktop-portal-wlr x11-base/xwayland-satellite ) ;;
    3) INSTALL_LIST+=( gui-wm/hyprland gui-libs/xdg-desktop-portal-hyprland ) ;;
    4) INSTALL_LIST+=( gnome-base/gnome-light ) ;;
    5) INSTALL_LIST+=( kde-plasma/plasma-meta ) ;;
esac

case $shell_choice in
    1) INSTALL_LIST+=( gui-wm/noctalia-shell gui-apps/noctalia-qs ) ;;
    2) INSTALL_LIST+=( gui-wm/dank-material-shell gui-apps/quickshell app-misc/dgop sys-apps/danksearch ) ;;
esac

case $dm_choice in
    1) INSTALL_LIST+=( x11-misc/ly ) ;;
    2) INSTALL_LIST+=( x11-misc/sddm ) ;;
    3) INSTALL_LIST+=( gui-libs/greetd gui-apps/tuigreet ) ;;
esac

[[ "${matugen_choice,,}" == "y" ]]  && INSTALL_LIST+=( x11-misc/matugen )
[[ "${steam_choice,,}" == "y" ]]    && INSTALL_LIST+=( games-util/steam-launcher )
[[ "${games_choice,,}" == "y" ]]    && INSTALL_LIST+=( games-util/protonplus games-util/heroic-bin )
[[ "${vesktop_choice,,}" == "y" ]]  && INSTALL_LIST+=( net-im/vesktop )
[[ "${rootapp_choice,,}" == "y" ]]  && INSTALL_LIST+=( app-misc/rootapp-bin )
[[ "${NEED_WIFI}" == "yes" ]]       && INSTALL_LIST+=( net-wireless/iwd net-wireless/wpa_supplicant )

INSTALL_LIST+=(
    gui-apps/wl-clipboard app-misc/cliphist media-sound/cava
    x11-terms/alacritty x11-terms/kitty app-editors/nano sys-apps/ripgrep
)

BIN_OPTS="--getbinpkg --usepkg --keep-going --autounmask=y --autounmask-write --autounmask-keep-masks=n"
EXCLUDES="--usepkg-exclude sys-auth/polkit --usepkg-exclude dev-libs/libei --usepkg-exclude media-video/wireplumber --usepkg-exclude media-libs/libpulse --usepkg-exclude sys-apps/accountsservice --usepkg-exclude sys-auth/elogind"

emerge ${BIN_OPTS} --oneshot --quiet sys-apps/systemd-utils virtual/libudev || true

set +e
emerge ${BIN_OPTS} $EXCLUDES "${INSTALL_LIST[@]}"
AUTOUNMASK_EXIT=$?
set -e

if [[ $AUTOUNMASK_EXIT -ne 0 ]] && [[ $AUTOUNMASK_EXIT -ne 1 ]]; then
    emerge ${BIN_OPTS} $EXCLUDES --skipfirst "${INSTALL_LIST[@]}" || true
fi

etc-update --automode -5 2>/dev/null || true
emerge ${BIN_OPTS} $EXCLUDES --update --newuse "${INSTALL_LIST[@]}" || true

# 7. USER & SERVICES
echo -e "${B}>>> USER & SERVICES${C}"
if ! id "${username}" &>/dev/null; then
    useradd -m -G wheel,audio,video,portage,input,seat,plugdev -s /bin/bash "${username}" || {
        useradd -m -G wheel,audio,video,portage,input -s /bin/bash "${username}" || true
    }
fi

echo "permit persist :wheel" > /etc/doas.conf
chmod 0400 /etc/doas.conf

rc-update add elogind boot  2>/dev/null || true
rc-update add seatd default 2>/dev/null || true
rc-update add dbus default  2>/dev/null || true

[[ "${NEED_WIFI}" == "yes" ]] && rc-update add iwd default 2>/dev/null || true
rc-update add NetworkManager default 2>/dev/null || true

# 8. POST-INSTALL
echo -e "${B}>>> POST-INSTALL${C}"
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

mkdir -p "/home/${username}/.config/systemd/user"
cat > "/home/${username}/.config/systemd/user/pipewire.service" << 'SVCE'
[Unit]
Description=PipeWire
[Service]
ExecStart=/usr/bin/pipewire
Restart=on-failure
[Install]
WantedBy=default.target
SVCE
chown -R "${username}:${username}" "/home/${username}/.config" || true

case $dm_choice in
    1) rc-update add ly default  2>/dev/null || true ;;
    2) rc-update add sddm default 2>/dev/null || true ;;
    3) rc-update add greetd default 2>/dev/null || true ;;
    4) sed -i "s/^#*agetty_options_tty1=.*/agetty_options_tty1=\"--autologin ${username}\"/" /etc/conf.d/agetty.tty1 2>/dev/null || true ;;
esac

# BOOTLOADER
if mountpoint -q /boot/efi 2>/dev/null && grep -q '/boot/efi.*vfat' /proc/mounts; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo || true
    grub-mkconfig -o /boot/grub/grub.cfg || true
fi

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen 2>/dev/null || true

if [[ "${NEED_WIFI}" == "yes" ]]; then
    cat > /etc/NetworkManager/NetworkManager.conf << 'NMC'
[main]
plugins=keyfile
[device]
wifi.backend=iwd
NMC
fi

# COMPLETION
INSTALL_COMPLETE="true"
{
    echo "INSTALL_COMPLETE=true"
    echo "username=${username}"
    echo "compositor=${de_choice}"
    echo "completed=$(date)"
} > "$LOCKFILE"

echo -e "${G}========================================${C}"
echo -e "${G}   Quickstart complete!${C}"
echo -e "${G}========================================${C}"
echo "User: $username"
echo ""
echo "Next: passwd $username && passwd"
echo "Then: exit, umount -R /mnt/gentoo, reboot"
