EAPI=8

inherit go-module git-r3

DESCRIPTION="Stateless, cursor-based system and process monitoring tool"
HOMEPAGE="https://github.com/AvengeMedia/dgop"
EGIT_REPO_URI="https://github.com/AvengeMedia/dgop.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

RESTRICT="network-sandbox"

BDEPEND=">=dev-lang/go-1.21"

src_compile() {
    export GOPROXY="https://proxy.golang.org,direct"
    go build -o dgop ./cmd/dgop || die
}

src_install() {
    dobin dgop
    
    insinto /etc/dgop
    newins config.sample.toml config.toml
    
    einstalldocs
}
