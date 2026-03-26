EAPI=8

inherit desktop

DESCRIPTION="Discord alternative for gaming communities"
HOMEPAGE="https://github.com/Ackerman-00"
SRC_URI="https://installer.rootapp.com/installer/Linux/X64/Root.AppImage -> ${P}.AppImage"

LICENSE="custom"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="bindist mirror test"

RDEPEND="
    x11-libs/gtk+:3
    dev-libs/nss
    media-libs/alsa-lib
    sys-apps/dbus
"

# Set S to the extracted squashfs directory
S="${WORKDIR}/squashfs-root"

src_unpack() {
    cp "${DISTDIR}/${P}.AppImage" "${WORKDIR}/" || die
    cd "${WORKDIR}" || die
    
    # Use the built-in extractor instead of raw unsquashfs
    chmod +x "${P}.AppImage" || die
    ./"${P}.AppImage" --appimage-extract || die "Failed to extract AppImage"
}

src_install() {
    insinto /opt/rootapp
    doins -r *
    
    fperms +x /opt/rootapp/AppRun
    dosym ../../opt/rootapp/AppRun /usr/bin/rootapp
    
    doicon -s 256 Root.png
    make_desktop_entry "rootapp" "RootApp" "Root" "Network;Chat;"
}
