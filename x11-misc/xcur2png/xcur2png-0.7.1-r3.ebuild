# Copyright 2020-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic

DESCRIPTION="Convert X cursors to PNG images"
HOMEPAGE="https://github.com/eworm-de/xcur2png"
# Upstream tags releases without the Gentoo revision suffix (tag is 0.7.1,
# not 0.7.1-rN), and the tarball is named after the plain version.
MY_PV="${PV%-r*}"
SRC_URI="https://github.com/eworm-de/xcur2png/releases/download/${MY_PV}/${PN}-${MY_PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	media-libs/libpng:=
	x11-libs/libXcursor
"
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

src_prepare() {
	default
	eautoreconf # bug 937784
}

src_configure() {
	append-cflags "-std=gnu89" # bug 916457
	default
}
