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
BDEPEND="sys-fs/squashfs-tools"

S="${WORKDIR}"

src_unpack() {
    cp "${DISTDIR}/${P}.AppImage" . || die
    # Rips the AppImage open safely without executing it
    unsquashfs -d squashfs-root "${P}.AppImage" || die
}

src_install() {
    insinto /opt/rootapp
    doins -r squashfs-root/*
    
    fperms +x /opt/rootapp/AppRun
    dosym -r /opt/rootapp/AppRun /usr/bin/rootapp
    
    doicon -s 256 squashfs-root/Root.png
    make_desktop_entry "rootapp" "RootApp" "Root" "Network;Chat;"
}
