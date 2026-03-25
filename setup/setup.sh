#!/bin/bash
if [ "$EUID" -ne 0 ]; then exit; fi

# 1. Initialization & Official Binhost
eselect profile set default/linux/amd64/23.0/desktop
mkdir -p /etc/portage/binrepos.conf
cat << EOF > /etc/portage/binrepos.conf/gentoo.conf
[gentoo]
priority = 1
sync-uri = https://gentoo.osuosl.org/releases/amd64/binpackages/23.0/x86-64/
EOF

# 2. Hardware & User Configuration
echo "Select Hardware Target:"
echo "1) Desktop (Ryzen 5 5600G - Zen 3 | AMD GPU)"
echo "2) Desktop (Ryzen 7 7700  - Zen 4 | RTX 5060 GPU)"
echo "3) Laptop  (Ryzen 3 7320U - Zen 2 | AMD GPU)"
echo "4) Laptop  (HP EliteBook  - Intel 6th Gen | Intel HD)"
read -p "Choice [1-4]: " hw_choice
read -p "Enter primary username: " username

read -p "Enable GURU? [y/n]: " guru_choice
read -p "Enable Steam natively? [y/n]: " steam_choice
read -p "Enable Heroic & ProtonPlus? [y/n]: " games_choice
read -p "Enable Vesktop? [y/n]: " vesktop_choice
read -p "Enable RootApp? [y/n]: " rootapp_choice

echo "Select Environment:"
echo "1) niri (Stable - GURU)"
echo "2) niri-git (Live - Nexus)"
echo "3) mangowc (Live - Nexus)"
echo "4) mangowc (Stable - GURU)"
echo "5) Hyprland (Minimal)"
echo "6) GNOME (Light)"
echo "7) KDE Plasma (Minimal)"
echo "8) COSMIC"
read -p "Choice [1-8]: " de_choice

echo "Select Desktop Shell:"
echo "1) noctalia-shell (Stable)"
echo "2) noctalia-shell-git (Live)"
echo "3) dank-material-shell (Live)"
echo "4) None"
read -p "Choice [1-4]: " shell_choice
[[ "$shell_choice" =~ ^[1-3]$ || "$de_choice" =~ ^$ || "$vesktop_choice" == "y" ]] && guru_choice="y"

echo "Select Greeter:"
echo "1) ly (TUI)"
echo "2) sddm"
echo "3) gdm"
echo "4) greetd"
echo "5) None (TTY)"
read -p "Choice [1-5]: " dm_choice

# 3. Hardware Isolation & make.conf
mkdir -p /etc/default
case $hw_choice in
    1) CPU_L="5600G (Zen 3)"; ZRAM="6144"; V_CARD="amdgpu radeonsi"; ARCH="znver3"; G_CMD="" ;;
    2) CPU_L="Ryzen 7700 + RTX 5060"; ZRAM="8192"; V_CARD="nvidia"; ARCH="znver4"; G_CMD="nvidia-drm.modeset=1" ;;
    3) CPU_L="7320U (Zen 2)"; ZRAM="4096"; V_CARD="amdgpu radeonsi"; ARCH="znver2"; G_CMD="" ;;
    4) CPU_L="HP EliteBook (Skylake)"; ZRAM="8192"; V_CARD="intel"; ARCH="skylake"; G_CMD="i915.enable_psr=0" ;;
esac

cat << EOF > /etc/portage/make.conf
COMMON_FLAGS="-O3 -march=$ARCH -pipe -flto=auto"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
RUSTFLAGS="-C opt-level=3"
MAKEOPTS="-j$(nproc)"
USE="-X wayland vulkan pipewire dbus elogind udev opengl dri gbm vaapi vdpau ffmpeg zram bluetooth X screencast gstreamer gles2 -systemd -aqua -cups"
VIDEO_CARDS="$V_CARD"
FEATURES="getbinpkg binpkg-request-signature"
ACCEPT_LICENSE="*"
LC_MESSAGES=C.utf8
EOF

echo "GRUB_CMDLINE_LINUX=\"$G_CMD\"" > /etc/default/grub

# 4. Repositories
emerge --noreplace app-eselect/eselect-repository dev-vcs/git
eselect repository add gentoo-nexus git https://github.com/Ackerman-00/gentoo-nexus.git
[[ "$guru_choice" == "y" ]] && eselect repository enable guru
[[ "$steam_choice" == "y" ]] && eselect repository enable steam-overlay
[[ "$de_choice" == "8" ]] && eselect repository add cosmic-overlay git https://github.com/fsvm88/cosmic-overlay.git
emaint sync -a

# 5. Portage Keyword & USE Alignment
mkdir -p /etc/portage/package.{accept_keywords,use}

cat << EOF > /etc/portage/package.accept_keywords/system
sys-kernel/gentoo-kernel-bin ~amd64
sys-kernel/linux-firmware ~amd64
sys-kernel/installkernel ~amd64
EOF

cat << EOF > /etc/portage/package.accept_keywords/nexus
gui-apps/matugen::gentoo-nexus **
x11-base/xwayland-satellite::gentoo-nexus **
games-util/protonplus::gentoo-nexus ~amd64
EOF

cat << EOF > /etc/portage/package.use/system
sys-kernel/installkernel dracut grub
media-video/pipewire sound-server extra
sys-auth/pambase elogind
EOF

[[ "$hw_choice" == "2" ]] && echo "x11-drivers/nvidia-drivers ~amd64" >> /etc/portage/package.accept_keywords/system
[[ "$hw_choice" == "2" ]] && echo "x11-drivers/nvidia-drivers kernel-open" > /etc/portage/package.use/nvidia
[[ "$games_choice" == "y" ]] && echo "games-util/heroic-bin ~amd64" >> /etc/portage/package.accept_keywords/system
[[ "$vesktop_choice" == "y" ]] && echo "net-im/vesktop-bin::guru ~amd64" >> /etc/portage/package.accept_keywords/guru
[[ "$rootapp_choice" == "y" ]] && echo "net-im/rootapp-bin::gentoo-nexus ~amd64" >> /etc/portage/package.accept_keywords/nexus
[[ "$de_choice" =~ ^$ ]] && echo "gui-wm/niri ~amd64" >> /etc/portage/package.accept_keywords/niri
[[ "$de_choice" == "2" ]] && echo "gui-wm/niri::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus

if [ "$steam_choice" == "y" ]; then
    echo "games-util/steam-launcher ~amd64" >> /etc/portage/package.accept_keywords/system
    cat << EOF > /etc/portage/package.use/steam
*/* abi_x86_32
media-libs/mesa X
x11-base/xwayland X
media-libs/libglvnd X
EOF
fi

# 6. Service & Network Setup
if id "$username" &>/dev/null; then
    usermod -aG wheel,audio,video,usb,cdrom,portage,seat,input "$username"
else
    useradd -m -G wheel,audio,video,usb,cdrom,portage,seat,input -s /bin/bash "$username"
fi
echo "permit persist :wheel" > /etc/doas.conf && chmod 0400 /etc/doas.conf

emerge --noreplace sys-block/zram-init net-wireless/iwd
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
rc-update add dbus default
rc-update add NetworkManager default

if [[ "$hw_choice" =~ ^$ ]]; then
    rc-update add iwd default
    mkdir -p /etc/NetworkManager/conf.d
    echo -e "[device]\nwifi.backend=iwd" > /etc/NetworkManager/conf.d/wifi_backend.conf
fi

# 7. Package Assembly
INSTALL_LIST="dev-lang/rust-bin sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware sys-kernel/dracut sys-boot/grub net-misc/networkmanager media-video/pipewire media-video/wireplumber gui-apps/foot sys-auth/elogind mate-extra/mate-polkit x11-base/xwayland-satellite gui-apps/swaync app-admin/doas"

case $de_choice in
    1|2) INSTALL_LIST="$INSTALL_LIST gui-wm/niri sys-apps/xdg-desktop-portal-gnome" ;;
    3|4) INSTALL_LIST="$INSTALL_LIST gui-wm/mangowc sys-apps/xdg-desktop-portal-wlr" ;;
    5) INSTALL_LIST="$INSTALL_LIST gui-wm/hyprland sys-apps/xdg-desktop-portal-hyprland" ;;
    8) INSTALL_LIST="$INSTALL_LIST cosmic-base/cosmic-session" ;;
esac

[[ "$hw_choice" == "2" ]] && INSTALL_LIST="$INSTALL_LIST x11-drivers/nvidia-drivers"
[[ "$hw_choice" == "4" ]] && INSTALL_LIST="$INSTALL_LIST sys-firmware/intel-microcode media-libs/intel-media-driver"
[[ "$games_choice" == "y" ]] && INSTALL_LIST="$INSTALL_LIST games-util/heroic-bin games-util/protonplus"
[[ "$vesktop_choice" == "y" ]] && INSTALL_LIST="$INSTALL_LIST net-im/vesktop-bin"
[[ "$steam_choice" == "y" ]] && INSTALL_LIST="$INSTALL_LIST games-util/steam-launcher"

# 8. Execution
echo "Deploying $CPU_L environment..."
emerge --autounmask=y --autounmask-write --getbinpkg --binpkg-respect-use=n -av $INSTALL_LIST

# 9. Post-Install Automations
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

# 10. Finalizing
echo ""
echo "Deployment Complete. Run:"
echo "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo"
echo "grub-mkconfig -o /boot/grub/grub.cfg"
echo "reboot"
