<div align="center">

<img src="https://www.gentoo.org/assets/img/logo/gentoo-signet.svg" width="80px" />

<br/>

# gentoo-nexus

*A bleeding-edge Gentoo overlay & binary host — built for the niri Wayland desktop.*

<br/>

[![Build](https://img.shields.io/github/actions/workflow/status/Ackerman-00/gentoo-nexus/gentoo-build.yml?style=for-the-badge&label=FORGE&logo=githubactions&logoColor=white&color=4f8a5a)](https://github.com/Ackerman-00/gentoo-nexus/actions)
&nbsp;
[![Binhost](https://img.shields.io/badge/BINHOST-LIVE-4f8a5a?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/Ackerman-00/gentoo-nexus/releases/tag/rolling)
&nbsp;
[![License](https://img.shields.io/badge/LICENSE-MIT-4f8a5a?style=for-the-badge)](LICENSE)

<sub>Pre-compiled binaries · Nightly CI · Drop-in Portage overlay</sub>

</div>

---

## Overview

**gentoo-nexus** is an autonomous Gentoo overlay and binary host. Packages are compiled nightly via GitHub Actions and served as ready-to-install `gpkg` binaries — no waiting for compilation on your end.

```
overlay  →  ebuilds tracked & auto-updated from upstream
binhost  →  pre-built gpkg binaries via GitHub Releases (rolling tag)
CI       →  GitHub Actions rebuilds on every version bump or commit
```

---

## Packages

| Atom | Description | Track |
|------|-------------|-------|
| `gui-wm/niri` | Scrollable-tiling Wayland compositor | `9999` |
| `gui-libs/greetd` | Minimal login manager daemon | stable |
| `gui-apps/tuigreet` | TUI greeter frontend for greetd | stable |
| `gui-apps/quickshell` | Scriptable desktop widget engine | stable |
| `app-misc/matugen` | Material You color token generator | stable |
| `x11-misc/xwayland-satellite` | Rootless XWayland for any Wayland compositor | `9999` |
| `gui-apps/dgop` | Fast application launcher | stable |
| `app-misc/danksearch` | System-wide fuzzy search | stable |
| `gui-apps/dank-material-shell` | Material Design shell for niri | stable |

`9999` ebuilds track upstream HEAD and rebuild automatically on every new commit.

---

## Installation Guide

> This guide walks through a complete Gentoo + niri setup using the nexus binhost. All packages are pulled as pre-built `gpkg` binaries — no local compilation required for overlay packages.

---

### ① Configure `make.conf`

```bash
nano /etc/portage/make.conf
```

```bash
# Default flags
COMMON_FLAGS="-O2 -march=x86-64 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

# Wayland/Desktop flags
USE="elogind -systemd dbus wayland egl"

# Binary host flags
FEATURES="getbinpkg parallel-install -binpkg-verify-signature"
EMERGE_DEFAULT_OPTS="--getbinpkg --quiet-build=y --keep-going"
BINPKG_FORMAT="gpkg"
PORTAGE_BINPKG_SIGVERIFY="0"

ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="~amd64"
MAKEOPTS="-j4"
LC_MESSAGES=C.UTF-8

# AMD GPU & codec support
VIDEO_CARDS="amdgpu radeonsi"
USE="${USE} vaapi vdpau vulkan amdgpu ffmpeg encode"
```

---

### ② Prepare Config Directories & Sync Portage

```bash
mkdir -p /etc/portage/repos.conf
mkdir -p /etc/portage/binrepos.conf
```

```bash
emerge-webrsync
```

---

### ③ Configure the Binary Host

```bash
nano /etc/portage/binrepos.conf/gentoo-nexus.conf
```

```ini
[gentoo-nexus]
priority = 9999
sync-uri = https://github.com/Ackerman-00/gentoo-nexus/releases/download/rolling/
```

---

### ④ Add the Overlay

```bash
nano /etc/portage/repos.conf/gentoo-nexus.conf
```

```ini
[gentoo-nexus]
location    = /var/db/repos/gentoo-nexus
sync-type   = git
sync-uri    = https://github.com/Ackerman-00/gentoo-nexus.git
priority    = 9999
auto-sync   = yes
```

Then install git and sync the overlay:

```bash
emerge dev-vcs/git
emaint sync -r gentoo-nexus
```

---

### ⑤ Initialize Gentoo GPG Trust

Required in fresh stage3 containers or new installs — without this, Portage rejects signed packages from the official Gentoo binhost:

```bash
getuto
```

---

### ⑥ Install the Kernel

Pull the pre-built distribution kernel directly from the Gentoo binhost. No manual compilation required:

```bash
emerge -g1 sys-kernel/gentoo-kernel 
```

> `sys-kernel/gentoo-kernel` is Gentoo's distribution kernel — it compiles and installs itself automatically via Portage, with sane defaults for most desktop hardware.

Configure and install the kernel:

```bash
emerge --config sys-kernel/gentoo-kernel
```

---

### ⑦ Accept Keywords for Nexus Packages

```bash
mkdir -p /etc/portage/package.accept_keywords
echo "*/*::gentoo-nexus **" > /etc/portage/package.accept_keywords/nexus
```

---

### ⑧ Configure USE Flags for Graphics & Media

AMD GPU / 32-bit compatibility (needed for Steam and similar):

```bash
echo "media-libs/mesa abi_x86_32" | tee /etc/portage/package.use/graphics
echo "media-libs/vulkan-loader abi_x86_32" | tee -a /etc/portage/package.use/graphics
echo "x11-libs/libdrm abi_x86_32" | tee -a /etc/portage/package.use/graphics
```

PipeWire extras (required for screen sharing, audio routing):

```bash
mkdir -p /etc/portage/package.use
echo "media-video/pipewire extra" >> /etc/portage/package.use/pipewire
```

FFmpeg (disable SDL to avoid circular deps):

```bash
echo "media-video/ffmpeg -sdl" >> /etc/portage/package.use/ffmpeg
```

---

### ⑨ Install niri, greetd & tuigreet

```bash
emerge -g gui-wm/niri gui-libs/greetd gui-apps/tuigreet
```

---

## Staying Updated

No manual intervention needed. Packages update with your system:

```bash
emerge -g -uDN @world
```

The CI pipeline handles version bumps, binary rebuilds, and index updates automatically.

---

## Testing with Distrobox

Try the overlay and binhost safely inside an isolated container — no risk to your host:

```bash
# Create a Gentoo container
distrobox create \
  --image gentoo/stage3:amd64-desktop-openrc \
  --name gentoo-nexus-test

# Enter it
distrobox enter gentoo-nexus-test
```

Then follow the Quick Setup steps above from inside the container.

---

## Contributing

Issues and PRs are welcome.

- **Request a package** → open an issue with the package atom
- **Fix or add an ebuild** → submit a PR following the existing category structure
- **Report a build failure** → Actions → *Gentoo Build Relay* → *Run workflow* with the atom

Version bumps are automated — no need to bump manually.

---

## Troubleshooting

<details>
<summary><strong>Portage ignores the binhost and compiles from source</strong></summary>

Verify your `make.conf` contains all three binary host directives:

```bash
BINPKG_FORMAT="gpkg"
FEATURES="getbinpkg -binpkg-verify-signature"
EMERGE_DEFAULT_OPTS="--getbinpkg --quiet-build=y --keep-going"
```

Also confirm `PORTAGE_BINPKG_SIGVERIFY="0"` is set. Then run `emerge --info | grep FEATURES` to verify the flags are active.

</details>

<details>
<summary><strong>Signature verification error on binhost packages</strong></summary>

The nexus binhost does not ship signed package indexes. Ensure your `make.conf` has:

```bash
FEATURES="... -binpkg-verify-signature"
PORTAGE_BINPKG_SIGVERIFY="0"
```

</details>

<details>
<summary><strong>A package failed to build in CI</strong></summary>

Go to **Actions → Gentoo Build Relay → Run workflow**, enter the package atom (e.g. `gui-wm/niri`), and retry after a few minutes.

</details>

<details>
<summary><strong>eselect repository crashes on duplicate</strong></summary>

If the repo was previously added manually, remove the conflicting entry first:

```bash
eselect repository remove gentoo-nexus
```

Then re-add via `repos.conf` as shown in step ④.

</details>

<details>
<summary><strong>404 Not Found or packages missing after a CI update</strong></summary>

Portage caches the `Packages` index locally. If CI just finished but you're still hitting 404s, bust the cache:

```bash
rm -rf /var/cache/binhost/*
emaint sync -r gentoo-nexus
```

Then retry your emerge.

</details>

<details>
<summary><strong>Mesa / Vulkan not working after install</strong></summary>

Confirm the USE flags were applied before the mesa emerge:

```bash
cat /etc/portage/package.use/graphics
```

Expected output:
```
media-libs/mesa abi_x86_32
media-libs/vulkan-loader abi_x86_32
x11-libs/libdrm abi_x86_32
```

If flags were added after mesa was installed, force a rebuild:

```bash
emerge -g --oneshot media-libs/mesa media-libs/vulkan-loader
```

</details>

---

<div align="center">

<sub>built on Gentoo · powered by Portage · automated with GitHub Actions</sub>

<br/>

[![GitHub](https://img.shields.io/badge/Ackerman--00-gentoo--nexus-4f8a5a?style=flat-square&logo=github)](https://github.com/Ackerman-00/gentoo-nexus)

</div>
