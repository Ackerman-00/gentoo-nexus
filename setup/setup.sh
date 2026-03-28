#!/bin/bash
if [ "$EUID" -ne 0 ]; then 
    echo -e "\e[1;31mERROR: Must run as root inside the Gentoo chroot!\e[0m"
    exit 1 
fi

B="\e[1;34m"
G="\e[1;32m"
Y="\e[1;33m"
C="\e[0m"

echo -e "${B}======================================================${C}"
echo -e "${G}      GENTOO NEXUS: AUTOMATED BINHOST INSTALLER       ${C}"
echo -e "${B}======================================================${C}"

echo -e "\n${Y} HARDWARE TARGET${C}"
echo "1) Desktop (Ryzen 5 5600G - Zen 3 | AMD GPU)"
echo "2) Desktop (Ryzen 7 7700  - Zen 4 | RTX 5060)"
echo "3) Laptop  (Ryzen 3 7320U - Zen 2 | AMD GPU)"
echo "4) Laptop  (HP EliteBook  - Skylake | Intel HD)"
read -p "Choice [1-4]: " hw_choice

echo -e "\n${Y} SOFTWARE SELECTION${C}"
read -p "Enter primary username: " username
read -p "Enable Steam natively? [y/n]: " steam_choice
read -p "Enable Heroic & ProtonPlus? [y/n]: " games_choice
read -p "Enable Vesktop? [y/n]: " vesktop_choice
read -p "Enable RootApp? [y/n]: " rootapp_choice

echo -e "\n${Y} ENVIRONMENT SELECTION${C}"
echo "1) niri (Nexus)"
echo "2) mangowc (Nexus)"
echo "3) Hyprland"
echo "4) GNOME"
echo "5) KDE Plasma"
echo "6) COSMIC"
read -p "Choice [1-6]: " de_choice

echo -e "\n${Y} DESKTOP SHELL${C}"
echo "1) noctalia-shell (Nexus)"
echo "2) dank-material-shell (Nexus)"
echo "3) None"
read -p "Choice [1-3]: " shell_choice

echo -e "\n${Y} DISPLAY MANAGER${C}"
echo "1) ly (TUI)"
echo "2) sddm"
echo "3) gdm"
echo "4) greetd"
echo "5) None"
read -p "Choice [1-5]: " dm_choice

echo -e "\n${B}>>> INITIALIZING BINHOSTS & PROFILE...${C}"
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
sync-uri = https://gentoo-nexus.sourceforge.io/
verify-signature = false
EOF

echo -e "\n${B}>>> CONFIGURING MAKE.CONF & HARDWARE...${C}"
case $hw_choice in
    1) ZRAM_SIZE="6144M"; V_CARD="amdgpu radeonsi"; ARCH="znver3"; G_CMD="" ;;
    2) ZRAM_SIZE="8192M"; V_CARD="nvidia"; ARCH="znver4"; G_CMD="nvidia-drm.modeset=1" ;;
    3) ZRAM_SIZE="4096M"; V_CARD="amdgpu radeonsi"; ARCH="znver2"; G_CMD="" ;;
    4) ZRAM_SIZE="8192M"; V_CARD="intel i965 iris"; ARCH="skylake"; G_CMD="i915.enable_psr=0" ;;
esac

cat << EOF > /etc/portage/make.conf
COMMON_FLAGS="-O3 -march=$ARCH -pipe -flto=auto"
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

mkdir -p /etc/default
if [ -n "$G_CMD" ]; then
    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub 2>/dev/null; then
        sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$G_CMD /" /etc/default/grub
    else
        echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$G_CMD\"" >> /etc/default/grub
    fi
fi

echo -e "\n${B}>>> BOOTSTRAPPING & SYNCING REPOSITORIES...${C}"
emerge-webrsync -q
emerge --noreplace --quiet --getbinpkg app-eselect/eselect-repository dev-vcs/git
eselect repository add gentoo-nexus git https://github.com/Ackerman-00/gentoo-nexus.git
[[ "$steam_choice" == "y" ]] && eselect repository enable steam-overlay
[[ "$de_choice" == "8" ]] && eselect repository add cosmic-overlay git https://github.com/fsvm88/cosmic-overlay.git
emaint sync -a

echo -e "\n${B}>>> WIRING PORTAGE RULES & MULTILIB...${C}"
mkdir -p /etc/portage/package.{use,mask,accept_keywords}

cat << EOF > /etc/portage/package.use/system
sys-kernel/installkernel dracut grub
media-video/pipewire sound-server extra
sys-auth/pambase elogind
EOF

[[ "$hw_choice" == "2" ]] && echo "x11-drivers/nvidia-drivers kernel-open" > /etc/portage/package.use/nvidia

cat << EOF > /etc/portage/package.accept_keywords/nexus
gui-apps/matugen::gentoo-nexus **
x11-base/xwayland-satellite::gentoo-nexus **
EOF

[[ "$de_choice" == "1" ]] && echo "gui-wm/niri::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus
[[ "$de_choice" == "2" ]] && echo "gui-wm/mangowc::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus
[[ "$shell_choice" == "1" ]] && echo "gui-wm/noctalia-shell::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus
[[ "$shell_choice" == "2" ]] && echo "gui-wm/dank-material-shell::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus

if [ "$steam_choice" == "y" ]; then
    cat << EOF > /etc/portage/package.use/steam
sys-libs/glibc abi_x86_32
media-libs/mesa abi_x86_32
media-libs/libglvnd abi_x86_32
virtual/opengl abi_x86_32
x11-libs/libX11 abi_x86_32
x11-libs/libXext abi_x86_32
x11-libs/libxcb abi_x86_32
x11-libs/libXau abi_x86_32
x11-libs/libXdmcp abi_x86_32
dev-libs/expat abi_x86_32
sys-libs/zlib abi_x86_32
x11-libs/libdrm abi_x86_32
x11-libs/libxshmfence abi_x86_32
EOF
    [[ "$hw_choice" == "2" ]] && echo "x11-drivers/nvidia-drivers abi_x86_32" >> /etc/portage/package.use/steam
fi

echo -e "\n${B}>>> SETTING UP USERS & SERVICES...${C}"
if id "$username" &>/dev/null; then
    usermod -aG wheel,audio,video,usb,cdrom,portage,seat,input "$username"
else
    useradd -m -G wheel,audio,video,usb,cdrom,portage,seat,input -s /bin/bash "$username"
fi
echo "permit persist :wheel" > /etc/doas.conf && chmod 0400 /etc/doas.conf

emerge --noreplace --quiet --getbinpkg sys-block/zram-init net-wireless/iwd sys-auth/seatd
cat << EOF > /etc/conf.d/zram-init
load_on_start=yes
unload_on_stop=yes
num_devices=1
type0=swap
size0=$ZRAM_SIZE
algo0=zstd
EOF

rc-update add zram-init boot
rc-update add elogind boot
rc-update add seatd default
rc-update add dbus default
rc-update add NetworkManager default

if [[ "$hw_choice" =~ ^$ ]]; then
    rc-update add iwd default
    mkdir -p /etc/NetworkManager/conf.d
    echo -e "[device]\nwifi.backend=iwd" > /etc/NetworkManager/conf.d/wifi_backend.conf
fi

echo -e "\n${B}>>> ASSEMBLING INSTALLATION TARGETS...${C}"
INSTALL_LIST="sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware sys-kernel/dracut sys-boot/grub sys-boot/efibootmgr app-admin/doas sys-auth/elogind media-video/pipewire media-video/wireplumber gui-apps/foot mate-extra/mate-polkit x11-base/xwayland-satellite gui-apps/swaync net-misc/networkmanager sys-fs/dosfstools sys-fs/fuse media-fonts/noto media-fonts/noto-emoji"

case $de_choice in
    1) INSTALL_LIST="$INSTALL_LIST gui-wm/niri::gentoo-nexus sys-apps/xdg-desktop-portal-gnome" ;;
    2) INSTALL_LIST="$INSTALL_LIST gui-wm/mangowc::gentoo-nexus sys-apps/xdg-desktop-portal-wlr" ;;
    3) INSTALL_LIST="$INSTALL_LIST gui-wm/hyprland sys-apps/xdg-desktop-portal-hyprland" ;;
    4) INSTALL_LIST="$INSTALL_LIST gnome-base/gnome-light" ;;
    5) INSTALL_LIST="$INSTALL_LIST kde-plasma/plasma-meta" ;;
    6) INSTALL_LIST="$INSTALL_LIST cosmic-base/cosmic-session" ;;
esac

case $dm_choice in
    1) INSTALL_LIST="$INSTALL_LIST x11-misc/ly"; DM_SVC="ly" ;;
    2) INSTALL_LIST="$INSTALL_LIST x11-misc/sddm"; DM_SVC="sddm"; echo 'DISPLAYMANAGER="sddm"' > /etc/conf.d/xdm ;;
    3) INSTALL_LIST="$INSTALL_LIST gnome-base/gdm"; DM_SVC="gdm"; echo 'DISPLAYMANAGER="gdm"' > /etc/conf.d/xdm ;;
    4) INSTALL_LIST="$INSTALL_LIST gui-libs/greetd"; DM_SVC="greetd" ;;
esac

[[ "$shell_choice" == "1" ]] && INSTALL_LIST="$INSTALL_LIST gui-wm/noctalia-shell::gentoo-nexus"
[[ "$shell_choice" == "2" ]] && INSTALL_LIST="$INSTALL_LIST gui-wm/dank-material-shell::gentoo-nexus"
[[ "$hw_choice" == "2" ]] && INSTALL_LIST="$INSTALL_LIST x11-drivers/nvidia-drivers"
[[ "$hw_choice" == "4" ]] && INSTALL_LIST="$INSTALL_LIST sys-firmware/intel-microcode media-libs/intel-media-driver"
[[ "$games_choice" == "y" ]] && INSTALL_LIST="$INSTALL_LIST games-util/heroic-bin games-util/protonplus-bin::gentoo-nexus"
[[ "$vesktop_choice" == "y" ]] && INSTALL_LIST="$INSTALL_LIST net-im/vesktop-bin::gentoo-nexus"
[[ "$steam_choice" == "y" ]] && INSTALL_LIST="$INSTALL_LIST games-util/steam-launcher"
[[ "$rootapp_choice" == "y" ]] && INSTALL_LIST="$INSTALL_LIST app-misc/rootapp-bin::gentoo-nexus"

echo -e "\n${B}>>> EXECUTING BINARY DEPLOYMENT...${C}"
BIN_OPTS="--getbinpkg --usepkg --binpkg-respect-use=y --keep-going"

emerge --autounmask=y --autounmask-write $BIN_OPTS $INSTALL_LIST || true
etc-update --automode -5
emerge $BIN_OPTS --update $INSTALL_LIST

echo -e "\n${B}>>> POST-INSTALL CONFIGURATION...${C}"
if [[ "$dm_choice" =~ ^[1-4]$ ]]; then
    rc-update add "$DM_SVC" default
fi

if [[ "$de_choice" =~ ^$ ]]; then
    mkdir -p /usr/share/wayland-sessions/
    sed -i 's/Exec=niri-session/Exec=dbus-run-session niri --session/' /usr/share/wayland-sessions/niri.desktop 2>/dev/null
    
    NIRI_CONF="/home/$username/.config/niri/config.kdl"
    mkdir -p $(dirname "$NIRI_CONF")
    cat << EOF > "$NIRI_CONF"
spawn-at-startup "xwayland-satellite"
spawn-at-startup "/usr/libexec/polkit-mate-authentication-agent-1"
environment { DISPLAY ":0"; }
EOF
    chown -R "$username":"$username" "/home/$username/.config"
fi

echo -e "\n${G}[✓] GENTOO NEXUS DEPLOYMENT COMPLETE!${C}"
echo -e "${Y}Final steps to execute manually:${C}"
echo "1. passwd root"
echo "2. passwd $username"
echo "3. grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo"
echo "4. grub-mkconfig -o /boot/grub/grub.cfg"
echo "5. exit && reboot"
