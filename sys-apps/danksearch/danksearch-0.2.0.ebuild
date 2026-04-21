EAPI=8

inherit go-module

DESCRIPTION="Fast, configurable filesystem search with fuzzy matching"
HOMEPAGE="https://github.com/AvengeMedia/danksearch"
SRC_URI="https://github.com/AvengeMedia/danksearch/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="network-sandbox"

BDEPEND=">=dev-lang/go-1.21"

src_unpack() {
    default
    go-module_src_unpack
}

src_compile() {
    export GOPROXY="https://proxy.golang.org,direct"
    ego build -ldflags="-s -w" -o ./dsearch cmd/dsearch/*.go || die "ego build failed"
}

src_install() {
    dobin dsearch
    dodoc README.md
    if [[ -f "${FILESDIR}/danksearch.init" ]]; then
        exeinto /etc/user/init.d
        newexe "${FILESDIR}"/danksearch.init danksearch
    fi
}
