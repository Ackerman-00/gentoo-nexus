EAPI=8

inherit meson vala xdg

DESCRIPTION="Compatibility tools manager for Wine/Proton"
HOMEPAGE="https://github.com/Vysp3r/ProtonPlus"
SRC_URI="https://github.com/Vysp3r/ProtonPlus/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3.0-or-later"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/ProtonPlus-${PV}"

DEPEND="
    app-arch/libarchive:=
    dev-libs/glib:2
    dev-libs/json-glib
    dev-libs/libgee:0.8
    gui-libs/gtk:4
    gui-libs/libadwaita:1
    net-libs/libsoup:3.0
    net-libs/webkit-gtk:6.0
"
RDEPEND="${DEPEND}"
BDEPEND="
    $(vala_depend)
    dev-build/meson
    dev-libs/appstream-glib
    dev-util/desktop-file-utils
    sys-devel/gettext
    virtual/pkgconfig
"

src_prepare() {
    default
    vala_setup
}

pkg_postinst() {
    xdg_pkg_postinst
    elog "ProtonPlus manages compatibility tools for Steam, Lutris, Heroic, and Bottles."
}
