EAPI=8

inherit cargo git-r3

DESCRIPTION="A Material You color generation tool with templates"
HOMEPAGE="https://github.com/InioX/matugen"
EGIT_REPO_URI="https://github.com/InioX/matugen.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""

BDEPEND="virtual/pkgconfig"

QA_FLAGS_IGNORED="usr/bin/matugen"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}
