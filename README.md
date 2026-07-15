<div align="center">

<img src="https://www.gentoo.org/assets/img/logo/gentoo-signet.svg" width="80px" />

# gentoo-nexus

*A bleeding-edge Gentoo overlay & binary host for the x86-64-v3 Wayland desktop.*

[![CI](https://img.shields.io/actions/workflow/status/Ackerman-00/gentoo-nexus/check-updates.yml?style=for-the-badge&label=CI&logo=githubactions&logoColor=white&color=8b5cf6)](https://github.com/Ackerman-00/gentoo-nexus/actions/workflows/check-updates.yml)
&nbsp;&nbsp;
[![Binhost](https://img.shields.io/badge/BINHOST-rolling-8b5cf6?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/Ackerman-00/gentoo-nexus/releases/tag/rolling)
&nbsp;&nbsp;
[![License](https://img.shields.io/github/license/Ackerman-00/gentoo-nexus?style=for-the-badge&label=LICENSE&color=8b5cf6)](LICENSE)

Pre-compiled binaries &middot; Nightly CI &middot; Drop-in Portage overlay

</div>

---

## About

**gentoo-nexus** is a Gentoo overlay and binary host for the
Wayland desktop, built for the **x86-64-v3** micro-architecture
(AVX2 / BMI2 / FMA — Intel Haswell (2013+) or newer, AMD Excavator / Ryzen (2015+) or newer).
Packages are pre-built nightly and delivered as `.gpkg` binaries — emerge
without the compile.

Binaries are built with the **exact same `CFLAGS` / `CPU_FLAGS_X86` as the
[official Gentoo x86-64-v3 binhost](https://wiki.gentoo.org/wiki/Gentoo_binhost/Available_packages_and_configurations)**,
so a machine that uses a **matching profile** (see the Init system note) can pull from
*either* source with **zero flag-mismatch recompiles**.

> **Init system:** nexus is built under the OpenRC `default/linux/amd64/23.0/desktop/gnome`
> profile (`-systemd` by default), so its binaries are OpenRC-oriented. The official
> x86-64-v3 binhost (in `[gentoo-official-v3]`) is built under *multiple* profiles
> including `desktop/gnome/systemd` and `desktop/plasma/systemd`, so **systemd** users
> are served from that binrepo with no extra configuration. No `systemd` USE flag is
> set in nexus itself — both init systems work across the two binrepos.
>
> **Profile note:** the build profile only sets the *default* USE flags recorded in each
> binary — it does **not** force you to run GNOME. A minimal niri / mangowm / Hyprland
> (OpenRC, `-systemd`) install is fully supported. For maximum binary reuse, select a
> `desktop` OpenRC profile (e.g. `default/linux/amd64/23.0/desktop/gnome` or `…/desktop`)
> and keep `CPU_FLAGS_X86` matching the v3 set; packages whose USE diverges from the
> build defaults are simply rebuilt from source by Portage — no breakage. Any amd64/glibc
> profile is binary-compatible; a more minimal profile just means more local rebuilds.

| | |
|---|---|
| **Overlay** | niri, mangowm, noctalia-v5, scenefx, and the full Wayland desktop stack |
| **Official rebuilds** | mesa, kernel, llvm, gcc, blender, godot, zed, and more — built for x86-64-v3 with 32-bit multilib for gaming |
| **CI** | nightly auto-rebuilds on every upstream release or commit |
| **Setup** | one command — overlay, binhost, and GPG trust together |

> **Architecture:** `amd64` (x86-64-v3)
> **CPUs:** Intel (Haswell, 2013+) or newer · AMD (Excavator / Ryzen, 2015+) or newer
> **GPUs:** AMD (primary, validated) & Intel (compatible) — **NVIDIA is not supported**;
> open an [issue](https://github.com/Ackerman-00/gentoo-nexus/issues) or
> [PR](https://github.com/Ackerman-00/gentoo-nexus/pulls) to request it

---

<details>

<summary><strong>Quick Install</strong> &nbsp; <code>one-liner</code></summary>

AMD64 / x86-64-v3 only. One command. Full desktop. From scratch to login in minutes.

> **Caution:** This script is built around specific hardware profiles and has not been broadly tested. It may not work on your device.

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Ackerman-00/gentoo-nexus/main/setup/quickstart.sh)
```

| | |
|---|---|
| **System** | Partitions disk · Stage3 extraction · Hardware-tuned CFLAGS (`-march=x86-64-v3`) |
| **Binaries** | Binrepos config · Kernel · Firmware · Dracut · GRUB |
| **Desktop** | Compositor (niri / mangowm / Hyprland / GNOME / KDE) |
| **Services** | Greetd · Elogind · Seatd · Pipewire · Zram · Doas |

Or follow the [manual installation](#manual-installation) below.

</details>

<details>

<summary><strong>Packages</strong> <code>overlay + official v3 rebuilds</code></summary>

The overlay provides the following atoms (tracking `master` rebuild on every upstream commit):

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

On top of the overlay, the `rolling` binhost also mirrors the official
Gentoo **x86-64-v3** rebuilds (mesa, gcc, llvm, ffmpeg, ROCm, and the rest of
the desktop `@world`), so most of the tree installs from binaries.

</details>

---

<details>

<summary><strong>Manual Installation</strong> (click to expand)</summary>

### Prerequisites

- An **x86-64-v3** capable CPU (Intel Haswell / AMD Excavator or newer)
- Gentoo LiveCD or existing installation
- Internet connection
- Root access

### 1. Configure make.conf

> Pre-built binaries are keyed on `CPU_FLAGS_X86` (a USE flag Portage checks
> under `--binpkg-respect-use=y`). These **must** match the official x86-64-v3
> binhost exactly, or Portage rejects the binaries and recompiles. `CFLAGS` is
> **not** a binpkg key, but keep it at `-march=x86-64-v3` so any local source
> builds stay compatible with the prebuilt tree.

```bash
# Default flags — x86-64-v3 (matches nexus + official v3 binhost)
COMMON_FLAGS="-O2 -pipe -march=x86-64-v3"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

# MUST match the v3 binhost exactly — USE flag checked by --binpkg-respect-use=y.
# Do NOT add bmi even if your CPU has it, or binaries get rejected.
CPU_FLAGS_X86="avx avx2 f16c fma3 mmx mmxext popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"

# USE is inherited from the desktop/gnome profile. The official Gentoo v3 binhost
# sets NO custom global USE — only profile defaults + */* CPU_FLAGS_X86 — so leave it
# unset for binary compatibility. Set package-specific flags in /etc/portage/package.use
# instead; ffmpeg codecs are SEPARATE (never a global USE flag), e.g.:
#   media-video/ffmpeg x264 x265 vpx opus dav1d vaapi vdpau

# --- VIDEO_CARDS: choose ONE of these (the -* resets to only what you list) ---
# AMD (GCN / Vega / RDNA — Ryzen graphics and discrete Radeon):
VIDEO_CARDS="-* amdgpu radeonsi"
# Intel (integrated graphics):
VIDEO_CARDS="-* intel"
# Both AMD + Intel in one machine:
VIDEO_CARDS="-* amdgpu radeonsi intel"

# Binary host consumption (nexus is unsigned)
FEATURES="getbinpkg parallel-install binpkg-ignore-signature"
EMERGE_DEFAULT_OPTS="--getbinpkg --quiet-build=y --keep-going"
BINPKG_FORMAT="gpkg"
PORTAGE_BINPKG_SIGVERIFY="0"

ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="~amd64"
MAKEOPTS="-j4"
LC_MESSAGES=C.UTF-8
```

> Prefer the drop-in config? Copy `machine/make.conf` over `/etc/portage/make.conf`
> (it ships the AMD + Intel `VIDEO_CARDS` line).

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

### 3. Add the binhosts

`[nexus]` is our `rolling` tree (unsigned); `[gentoo-official-v3]` is the
official x86-64-v3 binhost (signed) used as a fallback.

```bash
mkdir -p /etc/portage/binrepos.conf
cat > /etc/portage/binrepos.conf/gentoo-nexus.conf << 'EOF'
[nexus]
priority = 10
sync-uri = https://github.com/Ackerman-00/gentoo-nexus/releases/download/rolling/
verify-signature = false
location = /var/cache/binhost/nexus

[gentoo-official-v3]
priority = 5
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/
verify-signature = true
location = /var/cache/binhost/gentoo-official-v3
EOF
```

> Prefer the drop-in config? Copy `machine/binrepos.conf` over `/etc/portage/binrepos.conf`.

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
emerge --getbinpkg --oneshot sys-kernel/gentoo-kernel
emerge --config sys-kernel/gentoo-kernel
emerge --getbinpkg gui-wm/niri
```

</details>

---

## The `nexus` CLI

`tools/nexus` is a small wrapper around Portage that lets you query and install
from the `rolling` index without needing the full ebuild tree for the common
set. Drop it on `PATH` (e.g. `/usr/local/bin/nexus`) and make it executable.

| command | what it does |
| --- | --- |
| `nexus sync` | download the `rolling` `Packages` index into `/var/cache/nexus/Packages` |
| `nexus list` | list every package in `rolling` (with repo + build id) |
| `nexus search <term>` | regex search across package names |
| `nexus info <cp\|cpv>` | show versions + USE for a package (`media-libs/mesa` or `media-libs/mesa-26.1.4`) |
| `nexus status` | compare installed (`/var/db/pkg`) vs `rolling`, report upgradables |
| `nexus install <pkg>…` | install package(s) from binaries |
| `nexus update` | upgrade `@world` from binaries |

All commands read from the cached `Packages` index (refreshed by `sync`).
`install` and `update` delegate to `emerge`:

```
emerge --getbinpkg --binpkg-respect-use=y [--usepkgonly] <pkg>
```

- **Default (`install`/`update`)** is **strict**: `--usepkgonly` means a package
  is installed *only* if its binary exists in `rolling`. If it isn't there, the
  command fails hard (no surprise compile).
- **`--fallback`** drops `--usepkgonly`, so Portage may also satisfy the request
  from the `[gentoo-official-v3]` binrepo or, where no binary exists, compile
  from source.

## Staying Updated

```bash
nexus update          # binaries only, from rolling
# or, equivalently:
emerge --getbinpkg -uDN @world
```

The CI pipeline handles version bumps, binary rebuilds, and index updates automatically.

---

## Contributing

<details>

<summary><strong>Ways to Contribute</strong> &nbsp; <code>request · submit · report</code></summary>

<br>

| | |
|---|---|
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
FEATURES="getbinpkg binpkg-ignore-signature"
EMERGE_DEFAULT_OPTS="--getbinpkg --quiet-build=y --keep-going"
```

Run `emerge --info | grep FEATURES` to confirm flags are active. Also confirm
`CPU_FLAGS_X86` matches the x86-64-v3 binhost (above) — a mismatch makes
`--binpkg-respect-use=y` reject the binaries.

</details>

<details>
<summary><strong>Signature verification errors</strong></summary>

The nexus binhost does not ship signed package indexes (`verify-signature = false`).
The `[gentoo-official-v3]` binrepo *is* signed — run `getuto` once to trust it.

</details>

<details>
<summary><strong>Package not found / 404 after CI update</strong></summary>

Bust the local binhost cache and resync:

```bash
rm -rf /var/cache/binhost/*
nexus sync
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
