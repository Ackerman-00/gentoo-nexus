EAPI=8

inherit go-module

DESCRIPTION="Stateless, cursor-based system and process monitoring tool"
HOMEPAGE="https://github.com/AvengeMedia/dgop"

# Use the actual upstream tarball
SRC_URI="https://github.com/AvengeMedia/dgop/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="network-sandbox"
BDEPEND=">=dev-lang/go-1.21"

src_unpack() {
    default
    # Required for Go modules to be properly fetched and unpacked
    go-module_src_unpack
}

src_compile() {
    export GOPROXY="https://proxy.golang.org,direct"
    # Use ego from go-module.eclass, which sets up the Go environment correctly
    ego build -ldflags="-s -w" -o dgop ./cmd/dgop || die "ego build failed"
}

src_install() {
    dobin dgop
    # The sample config is at the root of the source
    insinto /etc/dgop
    if [[ -f config.sample.toml ]]; then
        newins config.sample.toml config.toml
    fi
    einstalldocs
}
