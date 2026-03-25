EAPI=8

inherit meson

DESCRIPTION="Wayland compositor based on wlroots and scenefx"
HOMEPAGE="https://github.com/mangowm/mango"
SRC_URI="https://github.com/mangowm/mangowc/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/mango-${PV}"

LICENSE="CC0-1.0 GPL-3+ MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="X"

DEPEND="
    >=gui-libs/wlroots-0.18:=[libinput,session,X?]
    dev-libs/libinput:=
    dev-libs/wayland
    >=gui-libs/scenefx-0.4.1
    dev-libs/libpcre2
    x11-libs/libxkbcommon
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

src_configure() {
    local emesonargs=(
        $(meson_feature X xwayland)
    )
    meson_src_configure
}
