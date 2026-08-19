# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 meson

DESCRIPTION="A lightweight Wayland shell built directly on Wayland and OpenGL ES"
HOMEPAGE="https://github.com/noctalia-dev/noctalia"
EGIT_REPO_URI="https://github.com/noctalia-dev/noctalia.git"
EGIT_BRANCH="main"
EGIT_COMMIT="b38bf2dde119"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
PROPERTIES="live"
IUSE=""

DEPEND="
    app-crypt/libsecret
    dev-cpp/nlohmann_json
    dev-cpp/sdbus-c++
    dev-libs/glib:2
    dev-libs/jemalloc
    dev-libs/libical
    dev-libs/libsodium
    dev-libs/libxml2
    dev-libs/wayland
    gnome-base/librsvg:2
    media-libs/fontconfig
    media-libs/freetype
    media-libs/harfbuzz
    media-libs/libepoxy
    media-libs/libglvnd
    media-libs/libjxl
    media-libs/libsndfile
    media-libs/libwebp
    media-libs/mesa[egl(+),gles2(+)]
    media-video/pipewire
    media-video/wireplumber
    dev-libs/md4c
    dev-cpp/tomlplusplus
    dev-libs/stb
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
