# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Obsidian 1.12.x uses Electron v39, which targets Chromium 142
CHROMIUM_VERSION="142"
CHROMIUM_LANGS="
    af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he hi
    hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv
    sw ta te th tr uk ur vi zh-CN zh-TW
"
inherit chromium-2 desktop linux-info unpacker xdg

DESCRIPTION="A second brain, for you, forever."
HOMEPAGE="https://obsidian.md/"

# The .deb is downloaded purely to extract the .desktop file and app icon.
SRC_URI="
    https://github.com/obsidianmd/obsidian-releases/releases/download/v${PV}/${P/-/_}_amd64.deb -> ${P}.gh.deb
    amd64? ( https://github.com/obsidianmd/obsidian-releases/releases/download/v${PV}/${P}.tar.gz -> ${P}-amd64.tar.gz )
    arm64? ( https://github.com/obsidianmd/obsidian-releases/releases/download/v${PV}/${P}-arm64.tar.gz )
"

DIR="/opt/${PN^}"

S="${WORKDIR}"

LICENSE="Obsidian-EULA"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="appindicator wayland"
RESTRICT="mirror strip bindist"

RDEPEND="
    >=app-accessibility/at-spi2-core-2.46.0:2
    app-crypt/libsecret[crypt]
    dev-libs/expat
    dev-libs/glib:2
    dev-libs/nspr
    dev-libs/nss
    media-libs/alsa-lib
    media-libs/fontconfig
    media-libs/mesa[gbm(+)]
    net-print/cups
    sys-apps/dbus
    sys-apps/util-linux
    sys-libs/glibc
    x11-libs/cairo
    x11-libs/libdrm
    x11-libs/gdk-pixbuf:2
    x11-libs/gtk+:3
    x11-libs/libX11
    x11-libs/libXScrnSaver
    x11-libs/libXcomposite
    x11-libs/libXdamage
    x11-libs/libXext
    x11-libs/libXfixes
    x11-libs/libXrandr
    x11-libs/libxcb
    x11-libs/libxkbcommon
    x11-libs/libxshmfence
    x11-libs/pango
    appindicator? ( dev-libs/libayatana-appindicator )
"

QA_PREBUILT="*"

CONFIG_CHECK="~USER_NS"

set_obsidian_src_dir() {
    if use amd64; then
        S_OBSIDIAN="${WORKDIR}/${P}"
    elif use arm64; then
        S_OBSIDIAN="${WORKDIR}/${P}-arm64"
    else
        die "Obsidian only supports amd64 and arm64"
    fi
}

src_configure() {
    default
    chromium_suid_sandbox_check_kernel_config
}

src_prepare() {
    default
    
    set_obsidian_src_dir
    
    # Cleanup languages
    pushd "${S_OBSIDIAN}/locales/" >/dev/null || die "location change for language cleanup failed"
    chromium_remove_language_paks
    popd >/dev/null || die "location reset for language cleanup failed"

    # Create a copy of upstream's .desktop
    cp usr/share/applications/obsidian.desktop \
        usr/share/applications/obsidian-wayland.desktop \
        || die "failed to create obsidian-wayland.desktop file"

    # Inject modern Electron Wayland flags
    sed -i \
        '
            /Exec/s/obsidian /obsidian --ozone-platform-hint=auto /
            /^Name/s/$/ Wayland/
            /^Comment/s/$/ with Wayland support enabled/
        ' \
        'usr/share/applications/obsidian-wayland.desktop' ||
        die "sed failed for obsidian-wayland.desktop file"
}

src_install() {
    local destdir="${DIR}"
    
    dodir "${destdir}"
    set_obsidian_src_dir

    pushd "${S_OBSIDIAN}" >/dev/null || die "location change for main install failed"
    
    # Dynamically copy payload to survive upstream Electron layout changes
    cp -pPR * "${ED}${destdir}/" || die "failed to copy obsidian files"
    
    popd >/dev/null || die "location reset for main install failed"

    # Chrome-sandbox requires the setuid bit to be specifically set.
    fowners root "${destdir}/chrome-sandbox"
    fperms 4711 "${destdir}/chrome-sandbox"

    dosym "${destdir}/obsidian" "/usr/bin/obsidian"

    if use appindicator; then
        dosym ../../usr/lib64/libayatana-appindicator3.so "${destdir}/libappindicator3.so"
    fi

    domenu usr/share/applications/obsidian.desktop
    if use wayland; then
        domenu usr/share/applications/obsidian-wayland.desktop
    fi

    local size
    for size in 16 32 48 64 128 256 512; do
        doicon --size ${size} usr/share/icons/hicolor/${size}x${size}/apps/${PN}.png
    done
}

pkg_postinst() {
    xdg_pkg_postinst

    ewarn "This package provides application entries for both Obsidian and"
    ewarn "Obsidian Wayland. If Obsidian Wayland breaks for you under Wayland,"
    ewarn "try the other Obsidian entry to launch with XWayland."
}
