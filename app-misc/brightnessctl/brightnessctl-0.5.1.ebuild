# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit toolchain-funcs udev

DESCRIPTION="A program to read and control device brightness"
HOMEPAGE="https://github.com/Hummer12007/brightnessctl"
SRC_URI="https://github.com/Hummer12007/brightnessctl/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="udev"
REQUIRED_USE="udev"

DEPEND="udev? ( virtual/udev )"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/${PN}-0.5.1-Makefile.patch
)

src_compile() {
	tc-export CC
	emake
}

src_install() {
	local myconf
	if use udev; then
		myconf="INSTALL_UDEV_RULES=1"
	else
		myconf="INSTALL_UDEV_RULES=0"
	fi
	emake ${myconf} DESTDIR="${D}" install
	dodoc README.md
}

pkg_postinst() {
	use udev && udev_reload
}

pkg_postrm() {
	use udev && udev_reload
}
