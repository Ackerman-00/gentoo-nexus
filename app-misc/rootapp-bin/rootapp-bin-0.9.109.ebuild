EAPI=8

inherit desktop

DESCRIPTION="Discord alternative for gaming communities"
HOMEPAGE="https://rootapp.com/"
SRC_URI="https://installer.rootapp.com/installer/Linux/X64/Root.AppImage -> ${P}.AppImage"

LICENSE="custom"
SLOT="0"
KEYWORDS="~amd64"
IUSE="suid"

RESTRICT="bindist mirror strip"

QA_PREBUILT="opt/rootapp/*"

RDEPEND="
    dev-libs/icu
    dev-libs/nss
    media-libs/alsa-lib
    sys-apps/dbus
    x11-libs/gtk+:3
"

S="${WORKDIR}"

src_unpack() {
    mkdir -p "${S}" || die
    cp "${DISTDIR}/${P}.AppImage" "${S}" || die
    cd "${S}" || die
    chmod +x "${P}.AppImage" || die
    ./"${P}.AppImage" --appimage-extract || die "Failed to extract AppImage"
}

src_install() {
    local target_dir="/opt/rootapp"
    dodir "${target_dir}"
    cp -a squashfs-root/* "${ED}${target_dir}/" || die "Failed to copy application files"
    # Create symlink in /usr/bin for easy launch
    dosym "../../opt/rootapp/AppRun" /usr/bin/rootapp
    # Install icons
    local icon_found=0
    if [[ -f "squashfs-root/Root.png" ]]; then
        doicon "squashfs-root/Root.png"
        icon_found=1
    elif [[ -f "squashfs-root/.DirIcon" ]]; then
        newicon "squashfs-root/.DirIcon" Root.png
        icon_found=1
    fi
    # Create desktop entry only if icon was found
    if [[ ${icon_found} -eq 1 ]]; then
        make_desktop_entry "rootapp" "RootApp" "Root" "Network;Chat;"
    fi
}

pkg_postinst() {
    if use suid; then
        chmod u+s "${EROOT}/opt/rootapp/chrome-sandbox" 2>/dev/null || \
            ewarn "Could not set SUID bit on chrome-sandbox. Some Electron features may not work."
    fi
}
