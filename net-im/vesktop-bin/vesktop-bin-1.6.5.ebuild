EAPI=8

inherit desktop xdg-utils

DESCRIPTION="Custom Discord desktop client with Vencord preinstalled (Binary Repackage)"
HOMEPAGE="https://github.com/Vencord/Vesktop"
SRC_URI="https://github.com/Vencord/Vesktop/releases/download/v${PV}/vesktop_${PV}_amd64.deb"

LICENSE="GPL-3.0-or-later"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

# Dependencies mapped from your Void and Fedora templates
RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[gbm(+)]
	net-print/cups
	x11-libs/gtk+:3
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-misc/xdg-utils
"

BDEPEND="app-arch/xz-utils"

S="${WORKDIR}"

# Prevents Gentoo from trying to 'fix' the pre-compiled JS/Node binaries
QA_PREBUILT="*"

src_unpack() {
	# Unpack the .deb archive
	unpack ${A}
	# Unpack the data payload (wildcard handles both .xz and .zst)
	unpack ./data.tar.*
}

src_prepare() {
	default
	# Fix the path in the desktop entry so it finds our wrapper
	sed -i 's|Exec=/opt/Vesktop/vesktop|Exec=vesktop|g' usr/share/applications/vesktop.desktop || die
}

src_install() {
	# 1. Install the main application folder to /opt
	insinto /opt/Vesktop
	doins -r opt/Vesktop/*

	# 2. Install icons and desktop files
	insinto /usr/share
	doins -r usr/share/icons
	doins -r usr/share/applications

	# 3. Create the Wayland-Optimized Wrapper (as seen in your Fedora spec)
	# This ensures it runs natively on niri/Wayland
	make_wrapper vesktop \
		"env ELECTRON_OZONE_PLATFORM_HINT=auto /opt/Vesktop/vesktop"

	# 4. Set correct permissions for the sandbox
	fperms 4755 /opt/Vesktop/chrome-sandbox
}
