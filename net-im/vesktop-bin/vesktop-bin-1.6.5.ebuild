# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg

DESCRIPTION="Custom Discord desktop client with Vencord preinstalled (Wayland Optimized)"
HOMEPAGE="https://github.com/Vencord/Vesktop"
SRC_URI="
    https://github.com/Vencord/Vesktop/releases/download/v${PV}/vesktop-${PV}.tar.gz
    https://raw.githubusercontent.com/Vencord/Vesktop/v${PV}/assets/icon.png -> vesktop-${PV}.png
"

LICENSE="GPL-3.0-or-later"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip test"

RDEPEND="
    app-accessibility/at-spi2-core:2
    dev-libs/expat
    dev-libs/glib
    dev-libs/nspr
    dev-libs/nss
    media-libs/alsa-lib
    media-libs/mesa[gbm(+)]
    net-print/cups
    sys-apps/dbus
    x11-libs/cairo
    x11-libs/gdk-pixbuf:2
    x11-libs/gtk+:3
    x11-libs/libX11
    x11-libs/libXcomposite
    x11-libs/libXdamage
    x11-libs/libXext
    x11-libs/libXfixes
    x11-libs/libXrandr
    x11-libs/libdrm
    x11-libs/libxcb
    x11-libs/libxkbcommon
    x11-libs/pango
"

S="${WORKDIR}/vesktop-${PV}"

QA_PREBUILT="*"

src_install() {
    local destdir="/opt/Vesktop"
    dodir "${destdir}"

    # Preserve ALL executable permissions
    cp -a "${S}"/* "${ED}/${destdir}/" || die "Failed to copy application files"

    # Set crucial security permissions for Electron's sandbox
    fowners root:root "${destdir}/chrome-sandbox"
    fperms 4711 "${destdir}/chrome-sandbox"

    # Create the Wayland-Optimized Native Wrapper for Niri
    cat <<-EOF > "${T}/vesktop"
#!/bin/sh
exec env ELECTRON_OZONE_PLATFORM_HINT=auto ${destdir}/vesktop "\$@"
EOF

    exeinto /usr/bin
    doexe "${T}/vesktop"
    
    # 1. Use doicon to force the icon into the hicolor theme directory. 
    cp "${DISTDIR}/vesktop-${PV}.png" "${WORKDIR}/vesktop.png" || die
    doicon -s 256 "${WORKDIR}/vesktop.png"
    
    # 2. Use domenu to install a perfectly named .desktop file.
    cat <<-EOF > "${WORKDIR}/vesktop.desktop"
[Desktop Entry]
Name=Vesktop
GenericName=Discord Client
Exec=vesktop %U
Icon=vesktop
Terminal=false
Type=Application
StartupWMClass=Vesktop
Categories=Network;InstantMessaging;
EOF

    domenu "${WORKDIR}/vesktop.desktop"
}
