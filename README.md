<div align="center">

<img src="https://www.gentoo.org/assets/img/logo/gentoo-signet.svg" width="80px" />

# gentoo-nexus

*A bleeding-edge Gentoo overlay & binary host for the Wayland desktop.*

[![Build](https://img.shields.io/github/actions/workflow/status/Ackerman-00/gentoo-nexus/build.yml?style=for-the-badge&label=FORGE&logo=githubactions&logoColor=white&color=4f8a5a)](https://github.com/Ackerman-00/gentoo-nexus/actions)
&nbsp;
[![Binhost](https://img.shields.io/badge/BINHOST-LIVE-4f8a5a?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/Ackerman-00/gentoo-nexus/releases/tag/rolling)
&nbsp;
[![License](https://img.shields.io/badge/LICENSE-MIT-4f8a5a?style=for-the-badge)](LICENSE)

Pre-compiled binaries &middot; Nightly CI &middot; Drop-in Portage overlay

</div>

---

## About

gentoo-nexus is an automated Gentoo overlay and binary host. Packages are compiled
nightly via GitHub Actions and distributed as ready-to-install gpkg binaries.
No local compilation required for overlay packages.

```
overlay  ->  ebuilds synced from git
binhost  ->  pre-built gpkg via GitHub Releases (rolling)
CI       ->  auto-rebuilds on version bumps and commits
```

> **AMD64 only.** This overlay is built and tested on AMD/AMD64 hardware with
> AMD GPUs. NVIDIA hardware is not supported and will not be added. If you
> need NVIDIA support, please open a PR -- I will not implement it myself.
>

---

## Quick Install

The fastest way to set up a complete Gentoo desktop with nexus is the quickstart
script. It handles partitioning, stage3 extraction, chroot, and full installation.

```bash
# From a Gentoo LiveCD or any Linux live environment:
bash <(curl -Ls https://raw.githubusercontent.com/Ackerman-00/gentoo-nexus/main/setup/quickstart.sh)
```

**What it does:**
- Partitions your disk (cfdisk) and auto-detects partitions by GPT type UUID
- Downloads and extracts the latest stage3 (desktop-openrc)
- Configures make.conf with hardware-tuned CFLAGS (znver3, znver4, etc.)
- Sets up binrepos (nexus priority 100, Gentoo priority 1)
- Installs kernel, firmware, dracut, GRUB
- Configures your compositor of choice (niri, mangowm, Hyprland, GNOME, KDE)
- Sets up greetd, elogind, seatd, pipewire, zram
- Creates a user with doas, enables services

Or follow the manual installation below.

---

## Packages

| Atom | Description | Track |
|------|-------------|-------|
| `gui-wm/niri` | Scrollable-tiling Wayland compositor | master |
| `gui-wm/mangowm` | Custom Wayland compositor | master |
| `gui-wm/noctalia-shell` | Desktop shell for niri | master |
| `gui-wm/dank-material-shell` | Material Design shell | stable |
| `gui-apps/noctalia-qs` | Quickshell-based launcher | master |
| `gui-apps/quickshell` | Scriptable widget engine | master |
| `gui-apps/dgop` | Application launcher | stable |
| `sys-apps/danksearch` | System-wide fuzzy search | stable |
| `x11-misc/matugen` | Material You color token generator | stable |
| `x11-misc/xwayland-satellite` | Rootless XWayland | master |
| `net-im/vesktop-bin` | Discord client with Vencord | stable |
| `games-util/steam-launcher` | Steam (from steam-overlay) | stable |
| `games-util/heroic-bin` | Heroic Games Launcher | stable |
| `games-util/protonplus-bin` | Proton manager | stable |
| `app-misc/rootapp-bin` | Rootful app launcher | stable |
| `app-misc/cliphist` | Clipboard manager | stable |
| `www-client/zen-browser` | Privacy-focused Firefox fork | stable |
| `app-office/obsidian` | Knowledge base | stable |
| `gui-apps/tuigreet` | TUI greeter for greetd | stable |
| `gui-libs/greetd` | Minimal login manager | stable |
| `app-misc/brightnessctl` | Backlight control | stable |
| `app-misc/nwg-look` | GTK settings for wlroots | stable |

Packages tracking `master` rebuild automatically on every upstream commit.

---

## Manual Installation

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

---

## Staying Updated

```bash
emerge -g -uDN @world
```

The CI pipeline handles version bumps, binary rebuilds, and index updates
automatically. No manual intervention needed for overlay packages.

---

## Contributing

Issues and PRs are welcome.

- **Request a package** -- open an issue with the package atom and upstream URL
- **NVIDIA support** -- not planned. open an issue if you need it, or submit a PR
- **Submit an ebuild** -- follow the existing category structure, include metadata.xml
- **Report a build failure** -- run the Build Relay workflow from the Actions tab

### Adding a new package

1. Create the ebuild under the appropriate category (e.g., `gui-wm/my-pkg/`)
2. Generate the Manifest: `ebuild my-pkg-1.0.0.ebuild manifest`
3. Add a metadata.xml with maintainer and upstream information
4. Submit a PR

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

[![GitHub](https://img.shields.io/badge/Ackerman--00-gentoo--nexus-4f8a5a?style=flat-square&logo=github)](https://github.com/Ackerman-00/gentoo-nexus)

</div>
