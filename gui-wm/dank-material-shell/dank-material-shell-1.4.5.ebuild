# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop go-module shell-completion xdg

DESCRIPTION="A complete desktop shell for niri and other Wayland compositors"
HOMEPAGE="https://github.com/AvengeMedia/DankMaterialShell"
SRC_URI="https://github.com/AvengeMedia/DankMaterialShell/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3.0-or-later"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="network-sandbox"

DEPEND="
    app-misc/cliphist
    app-misc/dgop
    gui-apps/quickshell
    gui-apps/wl-clipboard
    media-sound/cava
    sys-apps/danksearch
    x11-misc/matugen
    dev-qt/qtmultimedia:6
"
RDEPEND="${DEPEND}"
BDEPEND=">=dev-lang/go-1.21"

S="${WORKDIR}/DankMaterialShell-${PV}/core"

src_unpack() {
    default
    go-module_src_unpack
}

src_compile() {
    export GOMODCACHE="${WORKDIR}/go-mod"
    export GOPROXY="https://proxy.golang.org,direct"
    export GOFLAGS="-buildvcs=false"
    ego build -p 2 -ldflags="-s -w" -o ./dms ./cmd/dms || die "go build failed"

    mkdir -p completions || die
    chmod 755 ./dms
    chmod o+rx "${WORKDIR}" "${S}" completions
    
    ./dms completion bash > completions/dms 2>/dev/null || die "bash completion failed"
    ./dms completion fish > completions/dms.fish 2>/dev/null || die "fish completion failed"
    ./dms completion zsh  > completions/_dms 2>/dev/null || die "zsh completion failed"
}

src_install() {
    dobin dms
    dodoc ../README.md
    dobashcomp completions/dms
    dofishcomp completions/dms.fish
    dozshcomp completions/_dms
    newicon -s scalable ../assets/danklogo.svg danklogo.svg
    domenu ../assets/dms-open.desktop
    insinto /usr/share/quickshell/dms
    doins -r ../quickshell/*
}

pkg_postinst() {
    xdg_pkg_postinst
    elog "DankMaterialShell requires a running Wayland compositor."
}
