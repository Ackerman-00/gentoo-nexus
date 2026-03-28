EAPI=8

inherit desktop

DESCRIPTION="Discord alternative for gaming communities"
HOMEPAGE="https://github.com/Ackerman-00"
SRC_URI="https://installer.rootapp.com/installer/Linux/X64/Root.AppImage -> ${P}.AppImage"

LICENSE="custom"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="bindist mirror test"

QA_PREBUILT="opt/rootapp/*"

RDEPEND="
    dev-libs/icu
    dev-libs/nss
    media-libs/alsa-lib
    sys-apps/dbus
    x11-libs/gtk+:3
"

S="${WORKDIR}/squashfs-root"

src_unpack() {
    cp "${DISTDIR}/${A}" "${WORKDIR}/${P}.AppImage" || die
    cd "${WORKDIR}" || die
    chmod +x "${P}.AppImage" || die
    ./"${P}.AppImage" --appimage-extract || die "Failed to extract AppImage"
}

src_install() {
    dodir /opt/rootapp

    cp -a "${S}"/* "${ED}/opt/rootapp/" || die "Failed to copy application files"
    
    dosym ../../opt/rootapp/AppRun /usr/bin/rootapp
    
    if [[ -f "${S}/Root.png" ]]; then
        doicon "${S}/Root.png"
    elif [[ -f "${S}/.DirIcon" ]]; then
        newicon "${S}/.DirIcon" Root.png
    fi
    
    make_desktop_entry "rootapp" "RootApp" "Root" "Network;Chat;"
}
