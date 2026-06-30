EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..14} )
inherit distutils-r1 pypi

DESCRIPTION="Extract icons from Windows PE files (.exe/.dll)"
HOMEPAGE="https://github.com/jlu5/icoextract"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/pefile[${PYTHON_USEDEP}]
"
