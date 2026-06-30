# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils

DESCRIPTION="Discord alternative for gaming communities and large online groups"
HOMEPAGE="https://www.rootapp.com"
SRC_URI="https://installer.rootapp.com/installer/Linux/X64/Root.AppImage -> ${P}-amd64.AppImage"

S="${WORKDIR}"

LICENSE="custom"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="bindist mirror strip test"
QA_PREBUILT="*"

RDEPEND="
	app-accessibility/at-spi2-core:2
	dev-libs/glib:2
	dev-libs/icu
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	sys-libs/glibc
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3[X]
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
	x11-base/xwayland
"

BDEPEND="sys-fs/squashfs-tools"

src_unpack() {
	chmod +x "${DISTDIR}/${A}" || die
	"${DISTDIR}/${A}" --appimage-extract > /dev/null || die
}

src_install() {
	local destdir="/opt/rootapp"

	dodir "${destdir}"
	cp -pPR squashfs-root/* "${ED}${destdir}/" || die

	dosym "${destdir}/AppRun" "/usr/bin/rootapp"

	newicon -s 256 squashfs-root/Root.png rootapp.png

	make_desktop_entry "env AVALONIA_PLATFORM=Wayland rootapp %U" \
		"Root" rootapp "Network;InstantMessaging"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
