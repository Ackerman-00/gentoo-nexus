EAPI=8

inherit git-r3 meson

DESCRIPTION="A lightweight Wayland shell built directly on Wayland and OpenGL ES"
HOMEPAGE="https://github.com/noctalia-dev/noctalia-shell"
EGIT_REPO_URI="https://github.com/noctalia-dev/noctalia-shell.git"
EGIT_BRANCH="v5"
EGIT_COMMIT="08cc34240cbc"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="
    dev-cpp/sdbus-c++
    dev-libs/glib:2
    dev-libs/jemalloc
    dev-libs/wayland
    gnome-base/librsvg:2
    media-libs/fontconfig
    media-libs/freetype
    media-libs/libwebp
    media-libs/mesa[egl(+)]
    media-video/pipewire
    net-misc/curl
    sys-auth/polkit
    sys-libs/pam
    x11-libs/cairo
    x11-libs/libxkbcommon
    x11-libs/pango
"
RDEPEND="${DEPEND}"

BDEPEND="
    dev-libs/wayland-protocols
    dev-util/wayland-scanner
    virtual/pkgconfig
"
