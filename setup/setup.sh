#!/bin/bash
if [ "$EUID" -ne 0 ]; then echo "Run as root"; exit; fi

# 1. Hardware Detection
echo "Select Hardware Target:"
echo "1) Desktop (Ryzen 5 5600G - Zen 3)"
echo "2) Laptop  (Ryzen 3 7320U - Zen 2)"
read -p "Choice [1-2]: " hw_choice

if [ "$hw_choice" == "1" ]; then
    ARCH="znver3"; THREADS=$(nproc); ZRAM_SIZE="6144"; CPU_LABEL="5600G (Zen 3)"
else
    ARCH="znver2"; THREADS=$(nproc); ZRAM_SIZE="4096"; CPU_LABEL="7320U (Zen 2)"
fi

read -p "Enter your primary username: " username

# 2. Repo & Feature Toggles
read -p "Enable GURU? (For Vesktop/MangoWC/Quickshell) [y/n]: " guru_choice
read -p "Enable Steam? (Adds massive 32-bit ABI stack) [y/n]: " steam_choice
read -p "Enable Heroic & ProtonPlus? [y/n]: " games_choice
read -p "Enable Vesktop? [y/n]: " vesktop_choice
read -p "Enable RootApp? (Nexus Repo) [y/n]: " rootapp_choice

# 3. Environment & Greeter Selection
echo "Select Primary Environment (Minimal Bloat-Free):"
echo "1) niri (Stable - GURU)"
echo "2) niri-git (Live - Nexus Repo)"
echo "3) mangowc (Live - Nexus Repo)"
echo "4) mangowc (Stable/Live - GURU Repo)"
echo "5) Hyprland (Minimal)"
echo "6) GNOME (Light)"
echo "7) KDE Plasma (Desktop - Minimal)"
echo "8) COSMIC (Adds cosmic-overlay)"
read -p "Choice [1-8]: " de_choice

echo "Select Desktop Shell (For Wayland WMs):"
echo "1) noctalia-shell (Stable - GURU)"
echo "2) noctalia-shell-git (Live 9999 - GURU)"
echo "3) dank-material-shell (Live 9999 - Nexus Repo)"
echo "4) None / Minimal"
read -p "Choice [1-4]: " shell_choice

if [[ "$shell_choice" == "1" || "$shell_choice" == "2" || "$shell_choice" == "3" || "$de_choice" == "1" || "$de_choice" == "4" || "$vesktop_choice" == "y" ]]; then 
    guru_choice="y"
fi

echo "Select Greeter (Display Manager):"
echo "1) ly (Lightest - TUI)"
echo "2) sddm (Plasma standard)"
echo "3) lightdm (Classic)"
echo "4) gdm (GNOME standard)"
echo "5) greetd (COSMIC standard)"
echo "6) None (Boot to TTY)"
read -p "Choice [1-6]: " dm_choice

# 4. Configure make.conf
cat << EOF > /etc/portage/make.conf
COMMON_FLAGS="-O3 -march=$ARCH -pipe -flto=auto -fno-semantic-interposition"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
FCFLAGS="\${COMMON_FLAGS}"
FFLAGS="\${COMMON_FLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=$ARCH"
MAKEOPTS="-j$THREADS"
USE="wayland vulkan pipewire dbus elogind udev opengl dri gbm vaapi vdpau ffmpeg encode decode zram bluetooth -systemd -nvidia -aqua -cups"
VIDEO_CARDS="amdgpu radeonsi"
INPUT_DEVICES="libinput"
ACCEPT_LICENSE="*"
LC_MESSAGES=C.utf8
EOF

# 5. Repositories Setup
emerge --noreplace app-eselect/eselect-repository dev-vcs/git
eselect repository add gentoo-nexus git https://github.com/Ackerman-00/gentoo-nexus.git
if [ "$guru_choice" == "y" ]; then eselect repository enable guru; fi
if [ "$steam_choice" == "y" ]; then eselect repository enable steam-overlay; fi
if [ "$de_choice" == "8" ]; then eselect repository add cosmic-overlay git https://github.com/fsvm88/cosmic-overlay.git; fi
emaint sync -a

# 6. Keywords & Unmasking
mkdir -p /etc/portage/package.accept_keywords

cat << EOF > /etc/portage/package.accept_keywords/system
sys-kernel/gentoo-kernel-bin ~amd64
sys-kernel/linux-firmware ~amd64
sys-kernel/installkernel ~amd64
EOF

cat << EOF > /etc/portage/package.accept_keywords/nexus
gui-apps/matugen::gentoo-nexus **
x11-base/xwayland-satellite::gentoo-nexus **
games-util/protonplus::gentoo-nexus ~amd64
app-misc/dgop::gentoo-nexus **
EOF

if [ "$games_choice" == "y" ]; then
    echo "games-util/heroic-bin ~amd64" >> /etc/portage/package.accept_keywords/system
fi

if [ "$vesktop_choice" == "y" ]; then
    echo "net-im/vesktop-bin::guru ~amd64" >> /etc/portage/package.accept_keywords/guru
fi

if [ "$steam_choice" == "y" ]; then
    echo "games-util/steam-launcher ~amd64" >> /etc/portage/package.accept_keywords/system
fi

if [ "$rootapp_choice" == "y" ]; then
    echo "net-im/rootapp-bin::gentoo-nexus ~amd64" >> /etc/portage/package.accept_keywords/nexus
fi

if [ "$de_choice" == "2" ]; then
    echo "gui-wm/niri::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus
elif [ "$de_choice" == "3" ]; then
    echo "gui-wm/mangowc::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus
    echo "gui-libs/scenefx::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus
elif [ "$de_choice" == "4" ]; then
    echo "gui-wm/mangowc::guru ~amd64" >> /etc/portage/package.accept_keywords/guru
elif [ "$de_choice" == "8" ]; then
    echo "*/*::cosmic-overlay **" > /etc/portage/package.accept_keywords/cosmic
fi

if [ "$shell_choice" == "1" ]; then
    cat << EOF > /etc/portage/package.accept_keywords/guru
gui-wm/noctalia-shell::guru ~amd64
gui-libs/noctalia-qs::guru ~amd64
gui-libs/quickshell::guru ~amd64
EOF
elif [ "$shell_choice" == "2" ]; then
    cat << EOF > /etc/portage/package.accept_keywords/guru
gui-wm/noctalia-shell::guru **
gui-libs/noctalia-qs::guru **
gui-libs/quickshell::guru **
EOF
elif [ "$shell_choice" == "3" ]; then
    echo "gui-wm/dank-material-shell::gentoo-nexus **" >> /etc/portage/package.accept_keywords/nexus
    echo "gui-libs/quickshell::guru **" >> /etc/portage/package.accept_keywords/guru
fi

# 7. USE Flags
mkdir -p /etc/portage/package.use
cat << EOF > /etc/portage/package.use/system
sys-kernel/installkernel dracut grub
media-video/pipewire sound-server pipewire-alsa pulseaudio
EOF

if [ "$hw_choice" == "2" ]; then
    echo "net-misc/networkmanager iwd" >> /etc/portage/package.use/system
fi

if [ "$de_choice" == "5" ]; then
    echo "gui-libs/quickshell hyprland" > /etc/portage/package.use/quickshell
fi

if [ "$steam_choice" == "y" ]; then
    cat << EOF > /etc/portage/package.use/steam
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
sys-apps/util-linux abi_x86_32
sys-libs/gdbm abi_x86_32
sys-libs/gpm abi_x86_32
sys-libs/libcap abi_x86_32
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
x11-misc/colord abi_x86_32
EOF
fi

# 8. User, Security & Service Activation
if id "$username" &>/dev/null; then
    usermod -aG wheel,audio,video,usb,cdrom,portage,seat,input "$username"
else
    useradd -m -G wheel,audio,video,usb,cdrom,portage,seat,input "$username"
fi

echo "permit persist :wheel" > /etc/doas.conf
chmod 0400 /etc/doas.conf
chown root:root /etc/doas.conf

emerge --noreplace sys-block/zram-init sys-auth/seatd
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
rc-update add seatd boot
rc-update add dbus default
rc-update add NetworkManager default

# 9. Assembly & Final Command
INSTALL_LIST="dev-lang/rust-bin sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware sys-kernel/dracut sys-boot/grub net-misc/networkmanager media-video/pipewire media-video/wireplumber gui-apps/foot media-fonts/noto media-fonts/noto-emoji sys-auth/elogind sys-auth/polkit gnome-extra/polkit-gnome app-admin/doas sys-apps/xdg-desktop-portal sys-apps/xdg-desktop-portal-gtk app-misc/dgop gui-apps/matugen"

if [ "$hw_choice" == "2" ]; then 
    INSTALL_LIST="$INSTALL_LIST net-wireless/iwd sys-power/power-profiles-daemon net-wireless/bluez net-wireless/blueman"
    rc-update add power-profiles-daemon default
    rc-update add bluetooth default
fi

if [ "$vesktop_choice" == "y" ]; then INSTALL_LIST="$INSTALL_LIST net-im/vesktop-bin"; fi
if [ "$steam_choice" == "y" ]; then INSTALL_LIST="$INSTALL_LIST games-util/steam-launcher"; fi
if [ "$games_choice" == "y" ]; then INSTALL_LIST="$INSTALL_LIST games-util/heroic-bin games-util/protonplus"; fi
if [ "$rootapp_choice" == "y" ]; then INSTALL_LIST="$INSTALL_LIST net-im/rootapp-bin"; fi

case $de_choice in
    1|2) INSTALL_LIST="$INSTALL_LIST gui-wm/niri x11-base/xwayland-satellite sys-apps/xdg-desktop-portal-gnome" ;;
    3|4) INSTALL_LIST="$INSTALL_LIST gui-wm/mangowc x11-base/xwayland-satellite sys-apps/xdg-desktop-portal-wlr" ;;
    5) INSTALL_LIST="$INSTALL_LIST gui-wm/hyprland sys-apps/xdg-desktop-portal-hyprland" ;;
    6) INSTALL_LIST="$INSTALL_LIST gnome-base/gnome-light" ;;
    7) INSTALL_LIST="$INSTALL_LIST kde-plasma/plasma-desktop" ;;
    8) INSTALL_LIST="$INSTALL_LIST cosmic-base/cosmic-session" ;;
esac

case $shell_choice in
    1|2) INSTALL_LIST="$INSTALL_LIST gui-wm/noctalia-shell gui-libs/noctalia-qs" ;;
    3) INSTALL_LIST="$INSTALL_LIST gui-wm/dank-material-shell" ;;
esac

case $dm_choice in
    1) INSTALL_LIST="$INSTALL_LIST gui-apps/ly"; rc-update add ly default ;;
    2) INSTALL_LIST="$INSTALL_LIST x11-misc/sddm gui-libs/display-manager-init"; rc-update add display-manager default; echo 'DISPLAYMANAGER="sddm"' > /etc/conf.d/display-manager ;;
    3) INSTALL_LIST="$INSTALL_LIST x11-misc/lightdm gui-libs/display-manager-init"; rc-update add display-manager default; echo 'DISPLAYMANAGER="lightdm"' > /etc/conf.d/display-manager ;;
    4) INSTALL_LIST="$INSTALL_LIST gnome-base/gdm gui-libs/display-manager-init"; rc-update add display-manager default; echo 'DISPLAYMANAGER="gdm"' > /etc/conf.d/display-manager ;;
    5) INSTALL_LIST="$INSTALL_LIST gui-libs/greetd"; rc-update add greetd default; if [ "$de_choice" == "8" ]; then sed -i 's/command = "agreety --cmd \/bin\/sh"/command = "cosmic-greeter"/' /etc/greetd/config.toml; fi ;;
esac

echo "Setup complete for $CPU_LABEL."
echo "Run: emerge --autounmask=y --autounmask-write -av $INSTALL_LIST"
echo "If Portage asks to update configuration files, run: dispatch-conf"
echo ""
echo "Don't forget to configure GRUB after compiling:"
echo "  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo"
echo "  grub-mkconfig -o /boot/grub/grub.cfg"
