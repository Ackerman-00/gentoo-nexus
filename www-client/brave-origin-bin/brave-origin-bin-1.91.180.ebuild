# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils

DESCRIPTION="Minimalist browser from the makers of Brave (binary release)"
HOMEPAGE="https://brave.com/origin/download"
SRC_URI="https://github.com/brave/brave-browser/releases/download/v${PV}/brave-origin-${PV}-linux-amd64.zip -> ${P}.zip"

S="${WORKDIR}"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="mirror strip"
QA_PREBUILT="*"

RDEPEND="
	app-accessibility/at-spi2-core:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	sys-libs/glibc
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3[X]
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/pango
	x11-misc/xdg-utils
"
DEPEND=""
BDEPEND="app-arch/unzip"

src_unpack() {
	mkdir -p "${S}/brave" || die
	unzip -q "${DISTDIR}/${A}" -d "${S}/brave" || die
}

src_install() {
	local destdir="/opt/brave-origin-bin"

	dodir "${destdir}"
	cp -pPR brave/* "${ED}${destdir}/" || die
	fperms 4755 "${destdir}/chrome-sandbox"

	dosym -r "${destdir}/brave" "/usr/bin/brave-origin"

	local size
	for size in 16 24 32 48 64 128 256; do
		newicon -s ${size} "brave/product_logo_${size}.png" brave-origin.png
	done

	domenu "${FILESDIR}/brave-origin.desktop"

	insinto "/usr/share/licenses/${PN}"
	doins "brave/LICENSE"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	elog "Brave Origin has been installed to /opt/brave-origin-bin"
	elog "The brave-origin executable is symlinked to /usr/bin/brave-origin"
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
