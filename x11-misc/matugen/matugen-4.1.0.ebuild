EAPI=8

DESCRIPTION="A Material You color generation tool with templates"
HOMEPAGE="https://github.com/InioX/matugen"
SRC_URI="https://github.com/InioX/matugen/releases/download/v${PV}/matugen-${PV}-x86_64.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# Tells Portage not to strip or complain about pre-compiled binaries
QA_PREBUILT="usr/bin/matugen"

# The tarball extracts directly into the working directory, not a subfolder
S="${WORKDIR}"

src_install() {
    dobin matugen
}
