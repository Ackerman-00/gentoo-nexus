EAPI=8

LLVM_COMPAT=( {18..21} )

inherit cargo llvm-r2 git-r3

DESCRIPTION="Xwayland outside your Wayland compositor"
HOMEPAGE="https://github.com/Supreeeme/xwayland-satellite"
EGIT_REPO_URI="https://github.com/Supreeeme/xwayland-satellite.git"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS=""

# Explicitly defining libxcb keeps the dependency tree clean
DEPEND="
    x11-libs/libxcb
    x11-libs/xcb-util-cursor
"

# xwayland is required at runtime to actually do the satellite work
RDEPEND="${DEPEND}
    >=x11-base/xwayland-23.1
"

# The LLVM generator ensures bindgen gets the exact Clang version it needs
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

src_install() {
    cargo_src_install
    
    newman xwayland-satellite.man xwayland-satellite.1
}
