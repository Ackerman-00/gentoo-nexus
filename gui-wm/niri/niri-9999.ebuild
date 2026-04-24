# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8
LLVM_COMPAT=( {18..22} )
RUST_MIN_VER="1.95.0"

inherit cargo git-r3 llvm-r2 optfeature shell-completion systemd xdg

DESCRIPTION="Scrollable-tiling Wayland compositor"
HOMEPAGE="https://github.com/niri-wm/niri"
EGIT_REPO_URI="https://github.com/niri-wm/niri.git"

LICENSE="GPL-3+"
LICENSE+="
    Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD-2 BSD ISC MIT MPL-2.0
    Unicode-3.0 ZLIB
"
SLOT="0"
IUSE="+dbus screencast systemd"

REQUIRED_USE="
    screencast? ( dbus )
    systemd? ( dbus )
"

# Bypasses the Portage compile-phase network sandbox. 
RESTRICT="network-sandbox"

DEPEND="
    dev-libs/glib:2
    dev-libs/libinput:=
    dev-libs/wayland
    <media-libs/libdisplay-info-0.4.0:=
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
    screencast? ( $(llvm_gen_dep 'llvm-core/clang:${LLVM_SLOT}') )
    virtual/pkgconfig
"

QA_FLAGS_IGNORED="usr/bin/niri"

EGIT_COMMIT="9438f59e2b9d"
pkg_setup() {
    llvm-r2_pkg_setup
    rust_pkg_setup
}

src_unpack() {
    git-r3_src_unpack
    cargo_live_src_unpack
}

src_prepare() {
    default

    # Create an explicit OpenRC desktop file so the binary package remains init-agnostic.
    # The default niri.desktop uses `niri-session` (which expects systemd).
    # Providing both ensures the .gpkg.tar works perfectly for all init systems.
    cp resources/niri.desktop resources/niri-openrc.desktop || die
    
    local cmd="niri --session"
    use dbus && cmd="dbus-run-session $cmd"
    
    sed -i "s/Exec=niri-session/Exec=${cmd}/" resources/niri-openrc.desktop || die
    sed -i "s/Name=Niri/Name=Niri (OpenRC)/" resources/niri-openrc.desktop || die
}

src_configure() {
    # Dynamically inject the commit hash for the `niri --version` string
    export NIRI_BUILD_COMMIT="${EGIT_VERSION:0:7}"

    # cargo.eclass automatically parses this specific array name and applies it as Cargo features
    local myfeatures=(
        $(usev dbus)
        $(usev screencast xdp-gnome-screencast)
        $(usev systemd)
    )

    cargo_src_configure --no-default-features --frozen
}

src_compile() {
    cargo_src_compile
    "$(cargo_target_dir)"/niri completions bash > niri  || die
    "$(cargo_target_dir)"/niri completions fish > niri.fish || die
    "$(cargo_target_dir)"/niri completions zsh > _niri || die
}

src_install() {
    cargo_src_install
    dobin resources/niri-session
    
    # Installed unconditionally to guarantee binary package compatibility across environments
    systemd_douserunit resources/niri{.service,-shutdown.target}
    
    insinto /usr/share/wayland-sessions
    doins resources/niri.desktop
    doins resources/niri-openrc.desktop
    
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
    local skip=(
        --skip=::egl
    )
    cargo_src_test -- --test-threads=2 "${skip[@]}"
}

pkg_postinst() {
    optfeature "Xwayland support" "gui-apps/xwayland-satellite"
    optfeature_header "Default applications"
    optfeature "Application launcher" "gui-apps/fuzzel"
    optfeature "Status bar" "gui-apps/waybar"
    optfeature "Terminal" "x11-terms/alacritty"
}
