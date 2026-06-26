EAPI=8

inherit meson

DESCRIPTION="Lightweight, high-performance Wayland compositor built on dwl"
HOMEPAGE="https://github.com/mangowm/mango"
SRC_URI="https://github.com/mangowm/mango/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="CC0-1.0 GPL-3+ MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="X"

DEPEND="
    >=gui-libs/wlroots-0.19:=[libinput,session,X?]
    >=gui-libs/scenefx-0.4.1
    dev-libs/cJSON
    dev-libs/libinput:=
    dev-libs/libpcre2
    dev-libs/wayland
    x11-libs/libdrm
    x11-libs/libxkbcommon
    x11-libs/pixman
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

S="${WORKDIR}/mango-${PV}"

src_configure() {
    local emesonargs=(
        $(meson_feature X xwayland)
    )
    meson_src_configure
}

pkg_postinst() {
    elog "mangowm is a dynamic tiling Wayland compositor."
    elog "Configuration is done by editing config.h and recompiling."
}
