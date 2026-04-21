# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( {18..22} )
RUST_MIN_VER="1.95.0"  # Updated to latest stable as of April 2026

inherit cargo git-r3 llvm-r2 optfeature shell-completion xdg

DESCRIPTION="Scrollable-tiling Wayland compositor"
HOMEPAGE="https://github.com/niri-wm/niri"
EGIT_REPO_URI="https://github.com/niri-wm/niri.git"

LICENSE="GPL-3+"
# Dependent crate licenses
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

# Git dependencies via GIT_CRATES – commit hashes match upstream Cargo.lock
declare -A GIT_CRATES=(
	[smithay]="https://github.com/Smithay/smithay.git;27af99ef492ab4d7dc5cd2e625374d2beb2772f7"
	[smithay-drm-extras]="https://github.com/Smithay/smithay.git;27af99ef492ab4d7dc5cd2e625374d2beb2772f7"
)

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

<<<<<<< HEAD
EGIT_COMMIT="e472b5b0f13d"
=======
>>>>>>> 048ea36 (updated)
pkg_setup() {
	llvm-r2_pkg_setup
	rust_pkg_setup
}

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_prepare() {
	# GIT_CRATES handles Git dependencies – no sed hacks needed
	# niri-session doesn't work on OpenRC
	if ! use systemd; then
		local cmd="niri --session"
		use dbus && cmd="dbus-run-session $cmd"
		sed -i "s/niri-session/$cmd/" resources/niri.desktop || die
	fi
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

	"$(cargo_target_dir)"/niri completions bash > niri  || die
	"$(cargo_target_dir)"/niri completions fish > niri.fish || die
	"$(cargo_target_dir)"/niri completions zsh > _niri || die
}

src_install() {
	cargo_src_install

	dobin resources/niri-session
	if use systemd; then
		systemd_douserunit resources/niri{.service,-shutdown.target}
	fi

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
