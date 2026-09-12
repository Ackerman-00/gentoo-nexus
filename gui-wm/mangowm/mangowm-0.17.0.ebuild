# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="Lightweight, high-performance Wayland compositor built on dwl"
HOMEPAGE="https://github.com/mangowm/mango https://mangowm.github.io"
SRC_URI="https://github.com/mangowm/mango/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/mango-${PV}"

LICENSE="CC0-1.0 GPL-3+ MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	>=gui-libs/wlroots-0.20:0.20=[libinput,session,X?]
	<gui-libs/wlroots-0.21:=[X?]
	>=gui-libs/scenefx-0.5:=[X?]
	dev-libs/cJSON
	dev-libs/glib:2
	dev-libs/libinput:=
	dev-libs/libpcre2
	dev-libs/wayland
	x11-libs/cairo
	x11-libs/libdrm
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-libs/pixman
	sys-kernel/linux-headers
	X? (
		x11-libs/libxcb:=
		x11-libs/xcb-util-wm
		x11-base/xwayland
	)
"
RDEPEND="${DEPEND}"
BDEPEND="
	>=dev-libs/wayland-protocols-1.32
	>=dev-util/wayland-scanner-1.23
	>=dev-build/meson-0.60.0
	virtual/pkgconfig
"

DOCS=( README.md .github/CONTRIBUTING.md )
IUSE="X asan"

src_configure() {
	local emesonargs=(
		$(meson_feature X xwayland)
		$(meson_use asan)
	)
	meson_src_configure
}

pkg_postinst() {
	elog "mangowm is a dynamic tiling Wayland compositor."
	elog "Configuration is done by editing config.h and recompiling."
}
