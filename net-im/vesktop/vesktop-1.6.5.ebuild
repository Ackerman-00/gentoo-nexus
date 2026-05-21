# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="vesktop"

CHROMIUM_LANGS="
    af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he hi
    hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv
    sw ta te th tr uk ur vi zh-CN zh-TW
"

inherit chromium-2 desktop linux-info optfeature unpacker xdg

DESCRIPTION="All-in-one voice and text chat for gamers with Vencord Preinstalled"
HOMEPAGE="https://github.com/Vencord/Vesktop/"

# Adopting the Void Linux strategy: Use the .deb to natively acquire all icons and desktop files
SRC_URI="
    amd64? ( https://github.com/Vencord/Vesktop/releases/download/v${PV}/${MY_PN}_${PV}_amd64.deb -> ${P}-amd64.deb )
    arm64? ( https://github.com/Vencord/Vesktop/releases/download/v${PV}/${MY_PN}_${PV}_arm64.deb -> ${P}-arm64.deb )
"

# The unpacker eclass extracts the .deb data payload directly into the root WORKDIR
S="${WORKDIR}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="bindist mirror strip test"

DEPEND="
    app-accessibility/at-spi2-core
    dev-libs/expat
    dev-libs/glib
    dev-libs/nspr
    dev-libs/nss
    media-libs/alsa-lib
    media-libs/fontconfig
    media-libs/mesa[gbm(+)]
    net-print/cups
    sys-apps/dbus
    sys-libs/glibc
    x11-libs/cairo
    x11-libs/libdrm
    x11-libs/gdk-pixbuf:2
    x11-libs/gtk+:3
    x11-libs/libXcomposite
    x11-libs/libXdamage
    x11-libs/libXext
    x11-libs/libXfixes
    x11-libs/libXrandr
    x11-libs/libxcb
    x11-libs/libxkbcommon
    x11-libs/pango
    x11-misc/xdg-utils
"

# The .deb natively installs to /opt/Vesktop
DESTDIR="/opt/Vesktop"

QA_PREBUILT="*"

CONFIG_CHECK="~USER_NS"

src_unpack() {
    # This single command natively cracks open the .deb and data.tar payloads
    unpack_deb ${A}
}

src_prepare() {
    default
    
    # The official .deb desktop file expects the binary to be named "vesktop".
    # Since we symlink it to "vesktop-bin" to match your package name, we patch the Exec line.
    sed -i 's/Exec=vesktop/Exec=vesktop-bin/g' usr/share/applications/vesktop.desktop || die "failed to patch desktop file"
}

src_configure() {
    default
    chromium_suid_sandbox_check_kernel_config
}

src_install() {
    local destdir="${DESTDIR}"

    # 1. Install the main app payload (preserving executable bits for Node modules)
    dodir "${destdir}"
    cp -pPR opt/Vesktop/* "${ED}${destdir}/" || die "failed to copy vesktop files"

    # 2. Install Desktop entries and Icons directly from the .deb
    insinto /usr/share/applications
    doins usr/share/applications/*.desktop

    dodir /usr/share/icons
    cp -pPR usr/share/icons/* "${ED}/usr/share/icons/" || die "failed to copy icons"

    # 3. Fix the chrome-sandbox permissions for the Electron sandbox
    fowners root "${destdir}/chrome-sandbox"
    fperms 4711 "${destdir}/chrome-sandbox"

    # 4. Create the execution symlink targeting the wrapper
    dosym "${destdir}/vesktop" "/usr/bin/vesktop-bin"
}

pkg_postinst() {
    xdg_pkg_postinst
    optfeature "Desktop notifications support" x11-libs/libnotify
    optfeature "Text-to-Speech (TTS) support" app-accessibility/speech-dispatcher
}
