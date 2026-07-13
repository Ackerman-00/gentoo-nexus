# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

DESCRIPTION="GTK settings editor adapted to work on wlroots-based compositors"
HOMEPAGE="https://github.com/nwg-piotr/nwg-look"
SRC_URI="https://github.com/nwg-piotr/nwg-look/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="network-sandbox"

DEPEND="
    app-accessibility/at-spi2-core
    dev-libs/glib
    media-libs/fontconfig
    media-libs/freetype
    media-libs/harfbuzz
    x11-misc/xcur2png
    x11-libs/cairo
    x11-libs/gdk-pixbuf
    x11-libs/gtk+:3
    x11-libs/pango
"
RDEPEND="${DEPEND}"
BDEPEND="dev-lang/go"

src_compile() {
    export GOPATH="${T}/go"
    emake build
}

src_install() {
    insinto /usr/share/nwg-look
    doins stuff/main.glade
    doins -r langs

    doicon -s scalable stuff/nwg-look.svg
    domenu stuff/nwg-look.desktop

    dobin bin/nwg-look

    einstalldocs
}
