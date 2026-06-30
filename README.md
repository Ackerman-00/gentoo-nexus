<div align="center">

<img src="https://www.gentoo.org/assets/img/logo/gentoo-signet.svg" width="80px" />

# gentoo-nexus

*A bleeding-edge Gentoo overlay & binary host for the Wayland desktop.*

[![Build](https://img.shields.io/github/actions/workflow/status/Ackerman-00/gentoo-nexus/build.yml?style=for-the-badge&label=FORGE&logo=githubactions&logoColor=white&color=8b5cf6)](https://github.com/Ackerman-00/gentoo-nexus/actions)
&nbsp;&nbsp;
[![Binhost](https://img.shields.io/badge/BINHOST-LIVE-8b5cf6?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/Ackerman-00/gentoo-nexus/releases/tag/rolling)
&nbsp;&nbsp;
[![License](https://img.shields.io/badge/LICENSE-MIT-8b5cf6?style=for-the-badge)](LICENSE)

Pre-compiled binaries &middot; Nightly CI &middot; Drop-in Portage overlay

</div>

---

## About

**gentoo-nexus** is a Gentoo overlay and binary host for the
Wayland desktop. Packages are pre-built nightly and delivered
as `.gpkg` binaries — emerge without the compile.

| | |
|---|---|
| **Overlay** | niri, mangowm, scenefx, and the full Wayland desktop stack |
| **Official rebuilds** | mesa, kernel, llvm, gcc, blender, godot, zed, and more — with 32-bit multilib for gaming |
| **CI** | nightly auto-rebuilds on every upstream release or commit |
| **Setup** | one command — overlay, binhost, and GPG trust together |

> **Architecture:** `amd64` (x86_64) · **CPUs:** Intel & AMD  
> **GPUs:** AMD (primary target), Intel (compatible, unvalidated), NVIDIA (not in test matrix)

---

<details>

<summary><strong>Quick Install</strong> &nbsp; <code>one-liner</code></summary>

AMD64 only. One command. Full desktop. From scratch to login in minutes.

> **Caution:** This script is built around specific hardware profiles and has not been broadly tested. It may not work on your device.

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Ackerman-00/gentoo-nexus/main/setup/quickstart.sh)
```

| | |
|---|---|
| **System** | Partitions disk · Stage3 extraction · Hardware-tuned CFLAGS |
| **Binaries** | Binrepos config · Kernel · Firmware · Dracut · GRUB |
| **Desktop** | Compositor (niri / mangowm / Hyprland / GNOME / KDE) |
| **Services** | Greetd · Elogind · Seatd · Pipewire · Zram · Doas |

Or follow the [manual installation](#manual-installation) below.

</details>

<details>

<summary><strong>Packages</strong> <code>19 available</code></summary>

| Category | Atom | Description | Track |
|----------|------|-------------|-------|
| `gui-wm` | `niri` | Scrollable-tiling Wayland compositor | master |
| `gui-wm` | `mangowm` | Custom Wayland compositor | master |
| `gui-wm` | `noctalia-v5` | Desktop shell for niri | master |
| `gui-libs` | `scenefx` | Scene-graph graphics layer for wlroots | stable |
| `x11-base` | `xwayland-satellite` | Rootless XWayland | master |
| `x11-misc` | `matugen` | Material You color token generator | stable |
| `x11-misc` | `xcur2png` | X cursor to PNG converter | stable |
| `net-im` | `vesktop` | Discord client with Vencord | stable |
| `games-util` | `faugus-launcher` | Game launcher utility | stable |
| `games-util` | `protonplus` | Proton manager | stable |
| `app-misc` | `rootapp-bin` | Rootful app launcher | stable |
| `app-misc` | `cliphist` | Clipboard manager | stable |
| `app-misc` | `brightnessctl` | Backlight control | stable |
| `app-misc` | `nwg-look` | GTK settings for wlroots | stable |
| `app-office` | `obsidian` | Knowledge base | stable |
| `dev-python` | `icoextract` | Icon extractor for PE files | stable |
| `www-client` | `zen-browser` | Privacy-focused Firefox fork | stable |
| `www-client` | `brave-origin-bin` | Brave browser (upstream binary) | stable |

Packages tracking `master` rebuild on every upstream commit.

</details>

</details>

---

<details>

<summary><strong>Manual Installation</strong> (click to expand)</summary>

### Prerequisites

- Gentoo LiveCD or existing installation
- Internet connection
- Root access

### 1. Configure make.conf

```bash
COMMON_FLAGS="-O2 -march=x86-64 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"

USE="elogind -systemd dbus wayland egl vaapi vdpau vulkan amdgpu ffmpeg encode"
VIDEO_CARDS="amdgpu radeonsi"

FEATURES="getbinpkg binpkg-ignore-signature parallel-install"
PORTAGE_BINPKG_SIGVERIFY="0"
EMERGE_DEFAULT_OPTS="--getbinpkg --quiet-build=y --keep-going"
BINPKG_FORMAT="gpkg"
ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="~amd64"
```

### 2. Add the overlay

```bash
mkdir -p /etc/portage/repos.conf
cat > /etc/portage/repos.conf/gentoo-nexus.conf << 'EOF'
[gentoo-nexus]
location = /var/db/repos/gentoo-nexus
sync-type = git
sync-uri = https://github.com/Ackerman-00/gentoo-nexus.git
priority = 9999
auto-sync = yes
EOF

emerge dev-vcs/git
emaint sync -r gentoo-nexus
```

### 3. Add the binhost

```bash
mkdir -p /etc/portage/binrepos.conf
cat > /etc/portage/binrepos.conf/gentoo-nexus.conf << 'EOF'
[gentoo-nexus]
priority = 9999
sync-uri = https://github.com/Ackerman-00/gentoo-nexus/releases/download/rolling/
verify-signature = false
EOF
```

### 4. Initialize GPG trust

```bash
getuto
```

### 5. Accept keywords

```bash
mkdir -p /etc/portage/package.accept_keywords
echo "*/*::gentoo-nexus **" > /etc/portage/package.accept_keywords/nexus
```

### 6. Install the kernel and compositor

```bash
emerge -g1 sys-kernel/gentoo-kernel
emerge --config sys-kernel/gentoo-kernel
emerge -g gui-wm/niri
```

</details>

---

## Staying Updated

```bash
emerge -g -uDN @world
```

The CI pipeline handles version bumps, binary rebuilds, and index updates automatically.

---

## Contributing

<details>

<summary><strong>Ways to Contribute</strong> &nbsp; <code>request · submit · report</code></summary>

<br>

| | |
|---|---|---|
| [![Request](https://img.shields.io/badge/Request-8b5cf6?style=flat-square)](https://github.com/Ackerman-00/gentoo-nexus/issues/new) | Open an issue with the atom and upstream URL |
| [![Submit](https://img.shields.io/badge/Submit-8b5cf6?style=flat-square)](https://github.com/Ackerman-00/gentoo-nexus/pulls) | Follow the existing category structure with `metadata.xml` |
| [![Report](https://img.shields.io/badge/Report-8b5cf6?style=flat-square)](https://github.com/Ackerman-00/gentoo-nexus/actions) | Run the **Build Relay** workflow from the Actions tab |

</details>

<details>

<summary><strong>Adding a New Package</strong> &nbsp; <code>4 steps</code></summary>

<br>

| Step | Action |
|------|--------|
| **1** | Create the ebuild under the appropriate category (e.g., `gui-wm/my-pkg/`) |
| **2** | Generate the Manifest: `ebuild my-pkg-1.0.0.ebuild manifest` |
| **3** | Add a `metadata.xml` with maintainer and upstream information |
| **4** | Submit a [pull request](https://github.com/Ackerman-00/gentoo-nexus/pulls) |

</details>

---

## Troubleshooting

<details>
<summary><strong>Portage compiles from source instead of using the binhost</strong></summary>

Verify `make.conf` contains the required directives:

```bash
BINPKG_FORMAT="gpkg"
FEATURES="getbinpkg binpkg-ignore-signature"
PORTAGE_BINPKG_SIGVERIFY="0"
EMERGE_DEFAULT_OPTS="--getbinpkg --quiet-build=y --keep-going"
```

Run `emerge --info | grep FEATURES` to confirm flags are active.

</details>

<details>
<summary><strong>Signature verification errors</strong></summary>

The nexus binhost does not ship signed package indexes. Ensure:

```bash
FEATURES="... binpkg-ignore-signature"
PORTAGE_BINPKG_SIGVERIFY="0"
```

</details>

<details>
<summary><strong>Package not found / 404 after CI update</strong></summary>

Bust the local binhost cache and resync:

```bash
rm -rf /var/cache/binhost/*
emaint sync -r gentoo-nexus
```

</details>

<details>
<summary><strong>Mesa / Vulkan issues</strong></summary>

Ensure 32-bit USE flags are applied before emerge:

```bash
echo "media-libs/mesa abi_x86_32" >> /etc/portage/package.use/graphics
echo "media-libs/vulkan-loader abi_x86_32" >> /etc/portage/package.use/graphics
```

If flags were added after installation, rebuild:

```bash
emerge -g --oneshot media-libs/mesa media-libs/vulkan-loader
```

</details>

<details>
<summary><strong>Duplicate repository error</strong></summary>

Remove the conflicting entry and re-add:

```bash
eselect repository remove gentoo-nexus
```

Then follow the overlay setup steps above.

</details>

---

<div align="center">

<sub>built on Gentoo &middot; powered by Portage &middot; automated with GitHub Actions</sub>

[![GitHub](https://img.shields.io/badge/Ackerman--00-gentoo--nexus-8b5cf6?style=flat-square&logo=github)](https://github.com/Ackerman-00/gentoo-nexus)

</div>
