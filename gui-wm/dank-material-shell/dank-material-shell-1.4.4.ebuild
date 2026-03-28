EAPI=8
inherit desktop xdg

DESCRIPTION="A complete desktop shell for niri and other Wayland compositors."
HOMEPAGE="https://github.com/AvengeMedia/DankMaterialShell"
SRC_URI="https://github.com/AvengeMedia/DankMaterialShell/archive/v${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="GPL-3.0-or-later"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="network-sandbox"

DEPEND="
    gui-apps/quickshell
    media-sound/cava
    app-misc/cliphist
    gui-apps/wl-clipboard
    x11-misc/matugen
    gui-wm/niri
    dev-qt/qtmultimedia:6
    app-misc/dgop
    sys-apps/danksearch
    x11-base/xwayland-satellite
"
RDEPEND="${DEPEND}"
BDEPEND=">=dev-lang/go-1.21"

S="${WORKDIR}/DankMaterialShell-${PV}/core"

src_compile() {
    export GOMODCACHE="${WORKDIR}/go-mod"
    export GOPROXY="https://proxy.golang.org,direct"
    export GOFLAGS="-buildvcs=false"
    # -p 2 limits parallel compilations to avoid OOM on CI runners
    go build -p 2 -ldflags="-s -w" -o ./dms ./cmd/dms || die
    mkdir -pv completions || die
    ./dms completion bash > completions/dms || die
    ./dms completion fish > completions/dms.fish || die
    ./dms completion zsh > completions/_dms || die
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
