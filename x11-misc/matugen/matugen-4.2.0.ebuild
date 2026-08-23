# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A Material You color generation tool with templates"
HOMEPAGE="https://github.com/InioX/matugen"
SRC_URI="https://github.com/InioX/matugen/releases/download/v${PV}/matugen-${PV}-x86_64.tar.gz"

S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

QA_PREBUILT="usr/bin/matugen"
QA_PRESTRIPPED="usr/bin/matugen"

RDEPEND="
	dev-libs/openssl:=
"

src_install() {
	dobin matugen
}
