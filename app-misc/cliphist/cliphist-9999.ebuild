# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit git-r3

DESCRIPTION="Wayland clipboard manager with multimedia support"
HOMEPAGE="https://github.com/sentriz/cliphist"
EGIT_REPO_URI="https://github.com/sentriz/cliphist.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
    gui-apps/wl-clipboard
    app-misc/jq
"
DEPEND="${RDEPEND}"
BDEPEND=">=dev-lang/go-1.21"

src_compile() {
	ego build ./...
}

src_install() {
	dobin cliphist
	dodoc README.md
}
