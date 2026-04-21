EAPI=8

LLVM_COMPAT=( {18..22} )
RUST_MIN_VER="1.82.0"

inherit cargo git-r3 llvm-r2 optfeature shell-completion xdg

DESCRIPTION="Scrollable-tiling Wayland compositor"
HOMEPAGE="https://github.com/niri-wm/niri"
EGIT_REPO_URI="https://github.com/niri-wm/niri.git"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
IUSE="+dbus screencast systemd"
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

EGIT_COMMIT="3a3a97ec2ad7"
pkg_setup() {
    llvm-r2_pkg_setup
    rust_pkg_setup
}

src_unpack() {
    git-r3_src_unpack
    cargo_live_src_unpack
}

src_prepare() {
    # Remove git dependencies from Cargo.toml for offline build
    sed -i 's/git = "[^ ]*"/version = "*"/g' Cargo.toml || die
    # Ensure niri --session is properly wrapped when dbus is enabled
    local cmd="niri --session"
    if use dbus && ! use systemd; then
        cmd="dbus-run-session ${cmd}"
    fi
    sed -i "s/niri-session/${cmd}/" resources/niri.desktop || die
    default
}

src_configure() {
    local myfeatures=(
        $(usev dbus)
        $(usev screencast xdp-gnome-screencast)
        $(usev systemd)
    )
    cargo_src_configure --no-default-features
}

src_compile() {
    cargo_src_compile
    # Generate shell completions
    "$(cargo_target_dir)"/niri completions bash > niri 2>/dev/null || die
    "$(cargo_target_dir)"/niri completions fish > niri.fish 2>/dev/null || die
    "$(cargo_target_dir)"/niri completions zsh > _niri 2>/dev/null || die
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
    mkdir -p "${XDG_RUNTIME_DIR}" || die
    chmod 0700 "${XDG_RUNTIME_DIR}" || die
    local -x RAYON_NUM_THREADS=2
    local skip=( --skip=::egl )
    cargo_src_test -- --test-threads=2 "${skip[@]}"
}

pkg_postinst() {
    xdg_pkg_postinst
    optfeature "Xwayland support" "x11-base/xwayland-satellite"
    optfeature "Terminal" "gui-apps/foot"
    if use dbus && ! use systemd; then
        elog "You have enabled dbus without systemd. Niri will be launched with dbus-run-session."
    fi
}
