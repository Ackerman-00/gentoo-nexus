EAPI=8

inherit go-module git-r3

DESCRIPTION="A Material You inspired shell for Wayland"
HOMEPAGE="https://github.com/AvengeMedia/DankMaterialShell"
EGIT_REPO_URI="https://github.com/AvengeMedia/DankMaterialShell.git"

LICENSE="GPL-3.0-or-later"
SLOT="0"
KEYWORDS=""

# Cheat code: Allows Go to download modules during the compile phase
RESTRICT="network-sandbox"

DEPEND="
    gui-libs/quickshell
    app-misc/dgop
    gui-apps/matugen
    dev-qt/qtdeclarative:6
    dev-qt/qtwayland:6
    sys-libs/pam
    sys-apps/accountsservice
"
RDEPEND="${DEPEND}"
BDEPEND=">=dev-lang/go-1.21"

src_compile() {
    cd core || die
    # Forces standard Go module fetching instead of strict Gentoo ego restrictions
    export GOPROXY="https://proxy.golang.org,direct"
    go build -o dms ./cmd/dms || die
}

src_install() {
    dobin core/dms
    
    insinto /usr/share/quickshell/dms
    doins -r quickshell/*
}
