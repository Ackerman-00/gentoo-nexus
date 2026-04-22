# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{12..14} )

inherit optfeature python-single-r1 xdg

DESCRIPTION="A sleek and minimal desktop shell thoughtfully crafted for Wayland"
HOMEPAGE="https://noctalia.dev/ https://github.com/noctalia-dev/noctalia-shell"
SRC_URI="https://github.com/noctalia-dev/noctalia-shell/releases/download/v${PV}/noctalia-v${PV}.tar.gz"
KEYWORDS="~amd64"
S="${WORKDIR}/noctalia-release"

LICENSE="MIT"
SLOT="0"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="${PYTHON_DEPS}"

RDEPEND="
    ${PYTHON_DEPS}
    gui-apps/noctalia-qs
    app-misc/brightnessctl
    dev-vcs/git
    media-gfx/imagemagick
"

src_install() {
    insinto /etc/xdg/quickshell/noctalia-shell
    insopts -m0755
    doins -r .
    python_optimize "${ED}/etc/xdg/quickshell/${PN}/Scripts/python/src"
    python_fix_shebang "${ED}/etc/xdg/quickshell/${PN}/Scripts/python/src"
}

pkg_postinst() {
    xdg_pkg_postinst
    optfeature "clipboard history support" app-misc/cliphist
}
