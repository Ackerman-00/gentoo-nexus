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
    amd64? ( https://github.com/Vencord/Vesktop/releases/download/v${PV}/${MY_PN}_${PV}_amd64.deb -> ${P}-amd64.deb )
    arm64? ( https://github.com/Vencord/Vesktop/releases/download/v${PV}/${MY_PN}_${PV}_arm64.deb -> ${P}-arm64.deb )
"

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

DESTDIR="/opt/Vesktop"

QA_PREBUILT="*"

CONFIG_CHECK="~USER_NS"

src_unpack() {
    unpack_deb ${A}
}

src_prepare() {
    default

    pushd opt/Vesktop/locales >/dev/null 2>&1 || pushd "${S}/opt/Vesktop/locales" >/dev/null 2>&1 || return 0
    chromium_remove_language_paks
    popd >/dev/null || true
    
    sed -i 's/Exec=vesktop/Exec=vesktop-bin/g' usr/share/applications/vesktop.desktop || die
}

src_configure() {
    default
    chromium_suid_sandbox_check_kernel_config
}

src_install() {
    local destdir="${DESTDIR}"

    dodir "${destdir}"
    cp -pPR opt/Vesktop/* "${ED}${destdir}/" || die

    insinto /usr/share/applications
    doins usr/share/applications/*.desktop

    dodir /usr/share/icons
    cp -pPR usr/share/icons/* "${ED}/usr/share/icons/" || die

    fowners root "${destdir}/chrome-sandbox"
    fperms 4711 "${destdir}/chrome-sandbox"

    dosym "${destdir}/vesktop" "/usr/bin/vesktop-bin"
}

pkg_postinst() {
    xdg_pkg_postinst
    optfeature "Desktop notifications support" x11-libs/libnotify
    optfeature "Text-to-Speech (TTS) support" app-accessibility/speech-dispatcher
}
