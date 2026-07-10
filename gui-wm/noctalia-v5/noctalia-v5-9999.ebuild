EAPI=8

inherit git-r3 meson

DESCRIPTION="A lightweight Wayland shell built directly on Wayland and OpenGL ES"
HOMEPAGE="https://github.com/noctalia-dev/noctalia"
EGIT_REPO_URI="https://github.com/noctalia-dev/noctalia.git"
EGIT_BRANCH="main"
EGIT_COMMIT="313732302e64"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="
    dev-cpp/sdbus-c++
    dev-libs/glib:2
    dev-libs/jemalloc
    dev-libs/libxml2
    dev-libs/wayland
    gnome-base/librsvg:2
    media-libs/fontconfig
    media-libs/freetype
    media-libs/harfbuzz
    media-libs/libwebp
    media-libs/mesa[egl(+),gles2(+)]
    media-video/pipewire
    net-misc/curl
    sci-libs/libqalculate
    sys-auth/polkit
    sys-libs/pam
    x11-libs/cairo
    x11-libs/libxkbcommon
    x11-libs/pango
"
RDEPEND="${DEPEND}"

BDEPEND="
    dev-build/just
    dev-libs/wayland-protocols
    dev-util/wayland-scanner
    virtual/pkgconfig
"
