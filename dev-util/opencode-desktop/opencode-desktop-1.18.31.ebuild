# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="opencode-desktop"

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he hi
	hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv
	sw ta te th tr uk ur vi zh-CN zh-TW
"

inherit chromium-2 desktop unpacker xdg

DESCRIPTION="Desktop app for OpenCode, the open source AI coding agent"
HOMEPAGE="https://opencode.ai"
SRC_URI="
	amd64? ( https://github.com/anomalyco/opencode/releases/download/v${PV}/${MY_PN}-linux-amd64.deb -> ${P}-amd64.deb )
	arm64? ( https://github.com/anomalyco/opencode/releases/download/v${PV}/${MY_PN}-linux-arm64.deb -> ${P}-arm64.deb )
"

S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="bindist mirror strip"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	dev-libs/wayland
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	sys-libs/glibc
	virtual/libudev
	x11-libs/cairo
	x11-libs/libdrm
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3[X]
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libXScrnSaver
	x11-libs/libXtst
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

QA_PREBUILT="*"

DESTDIR="/opt/${PN}"

src_unpack() {
	unpack_deb ${A}
}

src_prepare() {
	default

	local locdir
	for locdir in "${S}"/opt/*/locales "${S}"/usr/lib/*/locales; do
		[[ -d "${locdir}" ]] || continue
		pushd "${locdir}" >/dev/null || die
		chromium_remove_language_paks
		popd >/dev/null || die
	done
}

src_install() {
	local productdir
	productdir="$(find "${S}"/opt -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | head -n1)" \
		|| die "unable to locate product directory"
	[[ -n "${productdir}" ]] || die "no product directory found in /opt"

	dodir "${DESTDIR}"
	cp -pPR "${S}/opt/${productdir}/." "${ED}${DESTDIR}/" || die

	[[ -f "${ED}${DESTDIR}/chrome-sandbox" ]] && \
		fperms 4711 "${DESTDIR}/chrome-sandbox"

	local exe
	exe="$(find "${ED}${DESTDIR}" -maxdepth 1 -type f -perm /111 \
		! -name 'chrome-sandbox' ! -name '*.so*' -printf '%f\n' | head -n1)" \
		|| die "unable to locate main executable"
	[[ -n "${exe}" ]] || die "no main executable found"
	dosym -r "${DESTDIR}/${exe}" /usr/bin/opencode-desktop

	local menu
	while read -r menu; do
		sed -e "s|^Exec=.*|Exec=opencode-desktop %U|" \
			-e "s|^Icon=.*|Icon=opencode-desktop|" \
			"${menu}" > "${T}/opencode.desktop" || die
		domenu "${T}/opencode.desktop"
	done < <(find "${S}"/usr/share/applications -name '*.desktop' 2>/dev/null)

	if [[ -d "${S}/usr/share/icons/hicolor" ]]; then
		dodir /usr/share/icons/hicolor
		cp -pPR "${S}/usr/share/icons/hicolor/." "${ED}/usr/share/icons/hicolor/" || die
	elif [[ -f "${ED}${DESTDIR}/resources/icon.png" ]]; then
		newicon -s 256 "${ED}${DESTDIR}/resources/icon.png" opencode-desktop.png
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "OpenCode Desktop has been installed to ${DESTDIR}"
	elog "The launcher is available as /usr/bin/opencode-desktop"
}
