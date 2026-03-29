EAPI=8

EGIT_COMMIT="8f48f56fe199"
LLVM_COMPAT=( {18..22} )
RUST_MIN_VER="1.82.0"

inherit cargo llvm-r2 optfeature shell-completion git-r3

DESCRIPTION="Scrollable-tiling Wayland compositor"
HOMEPAGE="https://github.com/niri-wm/niri"
EGIT_REPO_URI="https://github.com/niri-wm/niri.git"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
IUSE="+dbus +screencast"
REQUIRED_USE="screencast? ( dbus )"

PROPERTIES="live"
RESTRICT="network-sandbox"

DEPEND="
    dev-libs/glib:2
    dev-libs/libinput:=
    dev-libs/wayland
    media-libs/libdisplay-info:=
    media-libs/mesa
    sys-auth/seatd:=
    virtual/libudev:=
    x11-libs/cairo
    x11-libs/libxkbcommon
    x11-libs/pango
    x11-libs/pixman
    screencast? ( media-video/pipewire:= )
"
RDEPEND="
    ${DEPEND}
    screencast? ( sys-apps/xdg-desktop-portal-gnome )
"
BDEPEND="
    virtual/pkgconfig
    $(llvm_gen_dep 'llvm-core/clang:${LLVM_SLOT}')
"

QA_FLAGS_IGNORED="usr/bin/niri"

pkg_setup() {
    llvm-r2_pkg_setup
    rust_pkg_setup
}

src_unpack() {
    export EGIT_OVERRIDE_COMMIT_NIRI_WM_NIRI="${EGIT_COMMIT}"
    
    git-r3_src_unpack
    cargo_live_src_unpack
}

src_prepare() {
    sed -i 's/git = "[^ ]*"/version = "*"/' Cargo.toml || die
    
    local cmd="niri --session"
    use dbus && cmd="dbus-run-session ${cmd}"
    sed -i "s/niri-session/${cmd}/" resources/niri.desktop || die
    
    default
}

src_configure() {
    local myfeatures=(
        $(usev dbus)
        $(usev screencast xdp-gnome-screencast)
    )
    cargo_src_configure --no-default-features
}

src_compile() {
    cargo_src_compile
    "$(cargo_target_dir)"/niri completions bash > niri  || die
    "$(cargo_target_dir)"/niri completions fish > niri.fish || die
    "$(cargo_target_dir)"/niri completions zsh > _niri || die
}

src_install() {
    cargo_src_install
    insinto /usr/share/wayland-sessions
    doins resources/niri.desktop
    insinto /usr/share/xdg-desktop-portal
    doins resources/niri-portals.conf
    dobashcomp niri
    dofishcomp niri.fish
    dozshcomp _niri
}

src_test() {
    local -x XDG_RUNTIME_DIR="${T}/xdg"
    mkdir "${XDG_RUNTIME_DIR}" || die
    chmod 0700 "${XDG_RUNTIME_DIR}" || die
    local -x RAYON_NUM_THREADS=2
    local skip=( --skip=::egl )
    cargo_src_test -- --test-threads=2 "${skip[@]}"
}

pkg_postinst() {
    optfeature "Xwayland support" "x11-base/xwayland-satellite"
    optfeature "Terminal" "gui-apps/foot"
}
