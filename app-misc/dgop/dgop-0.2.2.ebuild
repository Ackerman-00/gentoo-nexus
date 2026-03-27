EAPI=8

inherit go-module

DESCRIPTION="Stateless, cursor-based system and process monitoring tool"
HOMEPAGE="https://github.com/AvengeMedia/dgop"

SRC_URI="https://github.com/AvengeMedia/dgop/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"

KEYWORDS="~amd64"

RESTRICT="network-sandbox"

BDEPEND=">=dev-lang/go-1.21"

src_compile() {
    export GOPROXY="https://proxy.golang.org,direct"
    ego build -o dgop ./cmd/dgop || die "ego build failed"
}

src_install() {
    dobin dgop
    
    insinto /etc/dgop
    if [ -f config.sample.toml ]; then
        newins config.sample.toml config.toml
    fi
    
    einstalldocs
}
