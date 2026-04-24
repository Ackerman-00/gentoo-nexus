# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit git-r3

DESCRIPTION="Program to read and control device brightness"
HOMEPAGE="https://github.com/Hummer12007/brightnessctl"
EGIT_REPO_URI="https://github.com/Hummer12007/brightnessctl.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="sys-apps/systemd-utils[udev]"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_install() {
	emake install DESTDIR="${D}" PREFIX=/usr
}
