EAPI=8

LLVM_COMPAT=( {18..22} )

inherit cargo git-r3 llvm-r2

DESCRIPTION="Xwayland outside your Wayland compositor"
HOMEPAGE="https://github.com/Supreeeme/xwayland-satellite"
EGIT_REPO_URI="https://github.com/Supreeeme/xwayland-satellite.git"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS=""
IUSE="systemd"

PROPERTIES="live"
RESTRICT="network-sandbox"

DEPEND="
    x11-libs/libxcb:=
    x11-libs/xcb-util-cursor
"
RDEPEND="${DEPEND}
    >=x11-base/xwayland-23.1
"
BDEPEND="
    $(llvm_gen_dep 'llvm-core/clang:${LLVM_SLOT}=')
    virtual/pkgconfig
"

QA_FLAGS_IGNORED="usr/bin/xwayland-satellite"

pkg_setup() {
    llvm-r2_pkg_setup
    rust_pkg_setup
}

src_unpack() {
    git-r3_src_unpack
    cargo_live_src_unpack
}

src_configure() {
    local myfeatures=(
        $(usev systemd)
    )
    cargo_src_configure
}

src_install() {
    cargo_src_install
    newman xwayland-satellite.man xwayland-satellite.1
}

pkg_postinst() {
    elog "xwayland-satellite provides rootless Xwayland integration for any"
    elog "Wayland compositor implementing xdg_wm_base."
}
