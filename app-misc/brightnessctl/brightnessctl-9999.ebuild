# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit git-r3

DESCRIPTION="Program to read and control device brightness"
HOMEPAGE="https://github.com/Hummer12007/brightnessctl"
EGIT_REPO_URI="https://github.com/Hummer12007/brightnessctl.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="sys-apps/systemd-utils[udev]"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

# brightnessctl uses a custom configure script, NOT autotools.
# We must NOT call econf; instead we call ./configure directly.
src_configure() {
	local myconf=(
		--prefix="${EPREFIX}"/usr
		--enable-udev
		--disable-logind
	)
	# Use bash's built-in ./configure, not econf
	bash ./configure "${myconf[@]}" || die "configure failed"
}

src_compile() {
	emake
}

src_install() {
	emake install DESTDIR="${D}" PREFIX="${EPREFIX}"/usr
	dodoc README.md
}
