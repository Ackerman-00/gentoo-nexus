# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

DESCRIPTION="Discord alternative for gaming communities"
HOMEPAGE="https://rootapp.com/"
SRC_URI="https://installer.rootapp.com/installer/Linux/X64/Root.AppImage -> ${P}.AppImage"

LICENSE="custom"
SLOT="0"
KEYWORDS="~amd64"
IUSE="suid"

RESTRICT="bindist mirror strip"

QA_PREBUILT="opt/rootapp/*"

RDEPEND="
    dev-libs/icu
    dev-libs/nss
    media-libs/alsa-lib
    sys-apps/dbus
    x11-libs/gtk+:3
"

BDEPEND="sys-fs/squashfs-tools"

S="${WORKDIR}"

src_unpack() {
    mkdir -p "${S}" || die
    cd "${S}" || die
    cp "${DISTDIR}/${P}.AppImage" . || die "Failed to copy AppImage from distfiles"
    chmod +x "${P}.AppImage" || die

    # Method 1: Use the AppImage's built-in extract (standard method from appimage.eclass)
    if ./"${P}.AppImage" --appimage-extract >/dev/null 2>&1; then
        einfo "Extracted via --appimage-extract"
        [ -d squashfs-root ] && mv squashfs-root "${P}" 2>/dev/null || true
    # Method 2: Compute offset with objdump and use unsquashfs
    elif command -v objdump >/dev/null 2>&1; then
        local offset
        offset=$(objdump -p "${P}.AppImage" 2>/dev/null | grep -oP 'offset \K0x[0-9a-f]+' | head -1)
        if [ -n "${offset}" ]; then
            einfo "Extracting AppImage at offset ${offset}"
            unsquashfs -o "${offset}" -d squashfs-root "${P}.AppImage" || die "Failed to extract AppImage via offset"
        else
            die "Could not determine AppImage offset"
        fi
    else
        die "Could not extract AppImage — neither --appimage-extract nor objdump available"
    fi
}

src_install() {
    local target_dir="/opt/rootapp"
    dodir "${target_dir}"

    # Find the extracted content (either in ${P} or squashfs-root)
    local src_dir
    if [ -d "${P}" ]; then
        src_dir="${P}"
    elif [ -d squashfs-root ]; then
        src_dir="squashfs-root"
    else
        die "Could not find extracted AppImage content"
    fi

    cp -a "${src_dir}"/* "${ED}${target_dir}/" || die "Failed to copy application files"
    dosym "../../opt/rootapp/AppRun" /usr/bin/rootapp

    local icon_found=0
    if [[ -f "${src_dir}/Root.png" ]]; then
        doicon "${src_dir}/Root.png"
        icon_found=1
    elif [[ -f "${src_dir}/.DirIcon" ]]; then
        newicon "${src_dir}/.DirIcon" Root.png
        icon_found=1
    fi

    if [[ ${icon_found} -eq 1 ]]; then
        make_desktop_entry "rootapp" "RootApp" "Root" "Network;Chat;"
    fi
}

pkg_postinst() {
    if use suid; then
        chmod u+s "${EROOT}/opt/rootapp/chrome-sandbox" 2>/dev/null || \
            ewarn "Could not set SUID bit on chrome-sandbox."
    fi
}
