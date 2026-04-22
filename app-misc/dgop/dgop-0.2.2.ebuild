EAPI=8

inherit go-module

DESCRIPTION="Stateless, cursor-based system and process monitoring tool"
HOMEPAGE="https://github.com/AvengeMedia/dgop"

# Use the actual upstream tarball
SRC_URI="https://github.com/AvengeMedia/dgop/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# This global declaration is all you need to disable the sandbox
RESTRICT="network-sandbox"
BDEPEND=">=dev-lang/go-1.21"

src_unpack() {
    default
    go-module_src_unpack
}

src_compile() {
    export GOPROXY="https://proxy.golang.org,direct"
    ego build -ldflags="-s -w" -o dgop ./cmd/dgop || die "ego build failed"
}

src_install() {
    dobin dgop
    insinto /etc/dgop
    if [[ -f config.sample.toml ]]; then
        newins config.sample.toml config.toml
    fi
    einstalldocs
}
