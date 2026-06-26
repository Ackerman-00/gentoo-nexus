EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
inherit meson python-single-r1

DESCRIPTION="A simple and lightweight app for running Windows games using UMU-Launcher"
HOMEPAGE="https://github.com/Faugus/faugus-launcher"
SRC_URI="https://github.com/Faugus/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pygobject:3[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/vdf[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/pygame[${PYTHON_USEDEP}]
		dev-python/icoextract[${PYTHON_USEDEP}]
	')
	media-libs/libcanberra
	media-gfx/imagemagick
	dev-libs/libayatana-appindicator
	dev-util/vulkan-tools
"
RDEPEND="${DEPEND}"
BDEPEND="
	${PYTHON_DEPS}
"

pkg_setup() {
	python-single-r1_pkg_setup
}

src_install() {
	meson_src_install
	
	python_fix_shebang "${ED}/usr/bin"
}
