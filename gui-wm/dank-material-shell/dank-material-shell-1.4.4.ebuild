EAPI=8

inherit go-module git-r3 xdg

DESCRIPTION="A Material You inspired shell for Wayland"
HOMEPAGE="https://github.com/AvengeMedia/DankMaterialShell"
EGIT_REPO_URI="https://github.com/AvengeMedia/DankMaterialShell.git"

LICENSE="GPL-3.0-or-later"
SLOT="0"
KEYWORDS=""

RESTRICT="network-sandbox"

DEPEND="
    gui-apps/quickshell
    app-misc/dgop
    x11-misc/matugen
    dev-qt/qtdeclarative:6
    dev-qt/qtwayland:6
    sys-libs/pam
    sys-apps/accountsservice
"
RDEPEND="${DEPEND}"
BDEPEND=">=dev-lang/go-1.21"

src_compile() {
    export GOPROXY="https://proxy.golang.org,direct"
    
    pushd core >/dev/null || die "Failed to enter core directory"
    
    ego build -o dms ./cmd/dms
    
    popd >/dev/null || die
}

src_install() {
    dobin core/dms
    
    insinto /usr/share/quickshell/dms
    doins -r quickshell/*
}
