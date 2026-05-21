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
SRC_URI="
    amd64? ( https://github.com/Vencord/Vesktop/releases/download/v${PV}/${MY_PN}-${PV}.tar.gz )
    arm64? ( https://github.com/Vencord/Vesktop/releases/download/v${PV}/${MY_PN}-${PV}-arm64.tar.gz )
    https://raw.githubusercontent.com/Vencord/Vesktop/v${PV}/build/icon.png -> ${MY_PN}.png
"
S="${WORKDIR}/${MY_PN}-${PV}"

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

# Installed specifically to MY_PN to prevent path breakage from the "-bin" suffix
DESTDIR="/opt/${MY_PN}"

QA_PREBUILT="*"

CONFIG_CHECK="~USER_NS"

src_unpack() {
    # Only unpack the architecture tarballs, completely ignoring the fetched PNG
    if use amd64; then
        unpack ${MY_PN}-${PV}.tar.gz
    elif use arm64; then
        unpack ${MY_PN}-${PV}-arm64.tar.gz
        # Normalize the arm64 directory name so the global S variable never breaks
        mv "${WORKDIR}/${MY_PN}-${PV}-arm64" "${WORKDIR}/${MY_PN}-${PV}" || die
    fi
}

src_configure() {
    default
    chromium_suid_sandbox_check_kernel_config
}

src_install() {
    local destdir="${DESTDIR}"

    # 1. Self-contained Desktop file (No local files required)
    make_desktop_entry "/usr/bin/vesktop-bin %U" "Vesktop" "${MY_PN}" "Network;InstantMessaging;Chat" "MimeType=x-scheme-handler/discord;"

    # 2. Install the icon we fetched dynamically via SRC_URI
    doicon -s 256 "${DISTDIR}/${MY_PN}.png"

    # 3. Use dodir and cp to preserve upstream executable bits
    dodir "${destdir}"
    cp -pPR * "${ED}${destdir}/" || die "failed to copy vesktop files"

    # 4. Chrome-sandbox permissions for the Electron sandbox
    fowners root "${destdir}/chrome-sandbox"
    fperms 4711 "${destdir}/chrome-sandbox"

    # 5. Create the execution symlink targeting the wrapper
    dosym "${destdir}/vesktop" "/usr/bin/vesktop-bin"
}

pkg_postinst() {
    xdg_pkg_postinst
    optfeature "Desktop notifications support" x11-libs/libnotify
    optfeature "Text-to-Speech (TTS) support" app-accessibility/speech-dispatcher
}
