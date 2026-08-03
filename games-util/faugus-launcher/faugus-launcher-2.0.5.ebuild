# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
inherit meson python-single-r1

DESCRIPTION="A simple and lightweight app for running Windows games using UMU-Launcher"
HOMEPAGE="https://github.com/Faugus/faugus-launcher"
SRC_URI="https://github.com/Faugus/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pygobject:3[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/vdf[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/dbus-python[${PYTHON_USEDEP}]
		dev-python/icoextract[${PYTHON_USEDEP}]
	')
	gui-libs/gtk:4
	gui-libs/libadwaita
	dev-libs/libmanette
	media-libs/vulkan-loader
"
DEPEND="${RDEPEND}"
BDEPEND="
	${PYTHON_DEPS}
"

pkg_setup() {
	python-single-r1_pkg_setup
}

src_install() {
	meson_src_install
}
