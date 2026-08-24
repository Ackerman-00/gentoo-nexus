<div align="center">

<img src="https://capsule-render.vercel.app/api?type=soft&color=0:0f0c29,50:44337a,100:8b5cf6&height=200&section=header&text=gentoo-nexus&fontSize=54&fontColor=ffffff&fontAlignY=36&animation=fadeIn&desc=A%20pre-built%20Gentoo%20overlay%20and%20binary%20host%20for%20the%20Wayland%20desktop&descAlignY=60&descSize=16" width="100%" alt="gentoo-nexus — a pre-built Gentoo overlay and binary host for the Wayland desktop" />

<img src="https://www.gentoo.org/assets/img/logo/gentoo-signet.svg" width="48px" />

[![Build](https://img.shields.io/github/actions/workflow/status/Ackerman-00/gentoo-nexus/build.yml?branch=main&style=for-the-badge&label=Build%20Relay&logo=githubactions&logoColor=white&color=8b5cf6)](https://github.com/Ackerman-00/gentoo-nexus/actions/workflows/build.yml)
&nbsp;
[![Binhost](https://img.shields.io/badge/BINHOST-rolling-8b5cf6?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/Ackerman-00/gentoo-nexus/releases/tag/rolling)
&nbsp;
[![License](https://img.shields.io/github/license/Ackerman-00/gentoo-nexus?style=for-the-badge&label=LICENSE&color=8b5cf6)](LICENSE)

`No compiling` · `Scheduled rebuilds` · `Drop-in Portage overlay`

Gentoo normally means building everything from source. **gentoo-nexus skips that** —
an overlay plus a binary host, so `emerge` installs finished packages instead.

</div>

---

### Contents

- [What this is](#what-this-is)
- [Compatibility with stock Gentoo](#compatibility-with-stock-gentoo)
- [Quick install](#quick-install)
- [What's included](#whats-included)
- [Manual install](#manual-install)
- [The `nexus` CLI](#the-nexus-cli)
- [Staying updated](#staying-updated)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)

---

## What this is

Targets the **x86-64-v3** CPU baseline (Haswell-class Intel or Excavator/Ryzen-class AMD,
2013+) and focuses on the Wayland desktop stack — compositors, shells, and the everyday
tools around them.

| What | Details |
|---|---|
| **Overlay** | niri, mangowm, noctalia-git, scenefx, and the rest of the Wayland stack |
| **Official rebuilds** | mesa, kernel, llvm, gcc, blender, godot, zed, and more, recompiled for x86-64-v3, with 32-bit support for gaming |
| **CI** | Rebuilds on a 12-hour rotating schedule — repo update → official update → brain-agent audit — or whenever upstream ships something new |
| **Setup** | One script sets up the overlay, binary host, and package signing together |

> [!IMPORTANT]
> **Hardware:** x86-64-v3 CPUs only (Intel Haswell+ / AMD Excavator+).
> **GPUs:** AMD ✓ · Intel ✓ (via the official v3 host) · NVIDIA: nouveau only
> (proprietary `nvidia-drivers` are not built here — AMD CI).

## Compatibility with stock Gentoo

Binaries are matched by `CPU_FLAGS_X86` and the **USE set** (not by CFLAGS —
Portage never checks CFLAGS when matching a binpkg). nexus builds with the
same flags as the
[official Gentoo x86-64-v3 binhost](https://wiki.gentoo.org/wiki/Gentoo_binhost/Available_packages_and_configurations)
and the same profile-default USE, so your system can pull binaries from *both*
sources at once without triggering a rebuild — as long as your `CPU_FLAGS_X86`
matches (see [Manual install](#manual-install)).

One nuance: nexus is built under an **OpenRC** profile, so its binaries default
to `-systemd`. The official binhost also builds systemd profiles, so **systemd
users are unaffected** — they simply pull from that repo instead. Either way,
this only affects *default* USE flags baked into a binary; you're free to run
niri, mangowm, or Hyprland regardless of init system or profile. Anything with
USE flags that don't match gets rebuilt locally — nothing breaks, you just
lose the binary shortcut for that one package.

## Quick install

One command. Partitions the disk, installs Gentoo, and lands you at a working
Wayland desktop.

> [!WARNING]
> This script assumes specific hardware and hasn't been tested broadly. Read
> it before running it on anything you care about.

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Ackerman-00/gentoo-nexus/main/setup/quickstart.sh)
```

| Stage | Handles |
|---|---|
| **System** | Disk partitioning, Stage3 extraction, CPU-tuned build flags |
| **Binaries** | Binary host config, kernel, firmware, Dracut, GRUB |
| **Desktop** | Your choice of compositor — niri, mangowm, Hyprland, GNOME, or KDE |
| **Services** | Greetd, Elogind, Seatd, PipeWire, Zram, Doas |

Prefer to do it by hand? See [Manual install](#manual-install).

## What's included

Everything below tracks upstream automatically — when a new release or commit
lands, CI rebuilds it.

| Category | Package | What it is |
|---|---|---|
| `gui-wm` | `niri` | Scrollable-tiling Wayland compositor |
| `gui-wm` | `mangowm` | Custom Wayland compositor |
| `gui-wm` | `noctalia-git` | Desktop shell for niri |
| `gui-libs` | `scenefx` | Scene-graph rendering layer for wlroots |
| `x11-base` | `xwayland-satellite` | Rootless XWayland |
| `x11-misc` | `matugen` | Material You color palette generator |
| `x11-misc` | `xcur2png` | X cursor → PNG converter |
| `net-im` | `vesktop` | Discord client with Vencord |
| `games-util` | `faugus-launcher` | Game launcher |
| `games-util` | `protonplus` | Proton version manager |
| `app-misc` | `rootapp` | Rootful app launcher |
| `app-misc` | `cliphist` | Clipboard history manager |
| `app-misc` | `brightnessctl` | Backlight control |
| `app-misc` | `nwg-look` | GTK theme settings for wlroots |
| `app-office` | `obsidian` | Knowledge base / notes app |
| `dev-python` | `icoextract` | Icon extractor for Windows executables |
| `www-client` | `zen-browser` | Privacy-focused Firefox fork |
| `www-client` | `brave-origin` | Brave browser (upstream binary) |
| `www-client` | `helium-browser` | Private, fast Chromium-based web browser (tar.xz binary) |
| `dev-util` | `opencode-desktop` | Desktop app for OpenCode, the open source AI coding agent (.deb binary) |

On top of these, the `rolling` binary host also mirrors the **official** Gentoo
x86-64-v3 rebuilds — mesa, gcc, llvm, ffmpeg, portage, and most of a typical
desktop `@world` — so almost everything installs pre-built. Packages the
official host does NOT ship (ROCm/OpenCL, `gentoo-kernel`, gaming tools) are
built here directly, with nexus covering the AMD / 32-bit / codec deltas.

## Manual install

**Prerequisites:** an x86-64-v3 CPU, a Gentoo LiveCD or existing install,
internet access, and root.

### 1 · Configure make.conf

> [!IMPORTANT]
> Binaries are matched by `CPU_FLAGS_X86`. If yours doesn't match the official
> x86-64-v3 set exactly, Portage rejects the binary and rebuilds from source.
> Don't add extra flags (like `bmi`) even if your CPU supports them.

```bash
COMMON_FLAGS="-O2 -pipe -march=x86-64-v3"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

CPU_FLAGS_X86="avx avx2 f16c fma3 mmx mmxext popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"

# Package-specific USE goes in /etc/portage/package.use, e.g.:
#   media-video/ffmpeg x264 x265 vpx opus dav1d vaapi vdpau

# Pick ONE (the '-*' reset lives in /etc/portage/package.use, see below —
# Portage rejects '-*' in make.conf):
VIDEO_CARDS="amdgpu radeonsi"        # AMD
VIDEO_CARDS="intel"                  # Intel
VIDEO_CARDS="amdgpu radeonsi intel"  # Both
```
```bash
# package.use — VIDEO_CARDS reset goes HERE, not in make.conf:
mkdir -p /etc/portage/package.use
echo "*/* VIDEO_CARDS: -* amdgpu radeonsi" > /etc/portage/package.use/nexus
```
```
FEATURES="getbinpkg parallel-install binpkg-ignore-signature"
EMERGE_DEFAULT_OPTS="--getbinpkg --quiet-build=y --keep-going"
BINPKG_FORMAT="gpkg"
PORTAGE_BINPKG_SIGVERIFY="0"

ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="~amd64"
MAKEOPTS="-j4"
LC_MESSAGES=C.UTF-8
```

> Or copy the ready-made config: `machine/make.conf` → `/etc/portage/make.conf`.

### 2 · Add the overlay

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
```

```bash
# install git if you don't already have it
emerge dev-vcs/git

# pull down the overlay
emaint sync -r gentoo-nexus
```

### 3 · Add the binary hosts

`[nexus]` is this repo's `rolling` tree (unsigned). `[gentoo-official-v3]` is
the official signed x86-64-v3 host, used as a fallback.

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

Or copy the ready-made config: `machine/binrepos.conf` → `/etc/portage/binrepos.conf`.

### 4 · Trust the official binhost

```bash
getuto
```

### 5 · Accept keywords

```bash
mkdir -p /etc/portage/package.accept_keywords
echo "*/*::gentoo-nexus **" > /etc/portage/package.accept_keywords/nexus
```

### 6 · Install the kernel and a compositor

Installkernel must match the nexus binary (`dracut grub` flags — the nexus
binhost and quickstart both set these, so the kernel binary matches as-is):

```bash
echo "sys-kernel/installkernel dracut grub" > /etc/portage/package.use/nexus
emerge --getbinpkg --oneshot sys-kernel/gentoo-kernel
emerge --config sys-kernel/gentoo-kernel
emerge --getbinpkg gui-wm/niri
```

## The `nexus` CLI

`tools/nexus` is a thin wrapper around Portage — a faster way to browse and
install from the `rolling` index without pulling the whole ebuild tree. It's a
single Python 3 script using only the standard library — no pip packages, no
dependencies beyond a `python3` interpreter.

### 1 · Make sure Python 3 is installed

On a fresh Gentoo install (or any minimal box), confirm `python3` exists:

```bash
# as root
if ! command -v python3 >/dev/null 2>&1; then
  emerge --getbinpkg -a dev-lang/python:3.13
fi
python3 --version   # must print Python 3.x
```

> [!NOTE]
> A normal Gentoo install already pulls in Python via `@world`. This step
> only matters if you're running the CLI standalone on a non-nexus machine.

### 2 · Install the script

**One-liner (download from GitHub):**

```bash
curl -fsSL https://raw.githubusercontent.com/Ackerman-00/gentoo-nexus/main/tools/nexus \
  -o /usr/local/bin/nexus && chmod +x /usr/local/bin/nexus
```

Already synced the overlay? Copy it locally instead:

```bash
install -m 0755 /var/db/repos/gentoo-nexus/tools/nexus /usr/local/bin/nexus
```

> [!TIP]
> `quickstart.sh` installs this for you automatically (step 9) — nothing to
> do here if you used the one-liner.

| Command | Does |
|---|---|
| `nexus sync` | Downloads the `rolling` package index |
| `nexus list` | Lists everything available in `rolling` |
| `nexus search <term>` | Regex search by package name |
| `nexus info <pkg>` | Shows versions and USE flags for a package |
| `nexus status` | Compares installed packages against `rolling`, flags upgrades |
| `nexus install <pkg>…` | Installs from binaries |
| `nexus update` | Upgrades `@world` from binaries |

By default, `install`/`update` are **strict**: if a binary isn't in `rolling`,
the command fails rather than silently compiling. Add `--fallback` to also
allow the official binhost, or a source build as a last resort.

## Staying updated

```bash
nexus update
# equivalent to:
emerge --getbinpkg -uDN @world
```

CI handles version bumps, rebuilds, and index updates on its own — you just pull.

## Contributing

**Ways to help**

| | |
|---|---|
| [Request a package](https://github.com/Ackerman-00/gentoo-nexus/issues/new) | Open an issue with the atom name and upstream URL |
| [Submit one yourself](https://github.com/Ackerman-00/gentoo-nexus/pulls) | Follow the existing folder structure, include a `metadata.xml` |
| [Report a build failure](https://github.com/Ackerman-00/gentoo-nexus/actions) | Run the **Build Relay** workflow from the Actions tab |

**Adding a package**

1. Add the ebuild under the right category (e.g. `gui-wm/my-pkg/`)
2. Generate the manifest: `ebuild my-pkg-1.0.0.ebuild manifest`
3. Add a `metadata.xml` with maintainer + upstream info
4. Open a [pull request](https://github.com/Ackerman-00/gentoo-nexus/pulls)

## Troubleshooting

Click whichever matches what you're seeing:

<details>
<summary>Portage keeps compiling instead of using the binhost</summary>
<br>

Check that `make.conf` has:

```bash
FEATURES="getbinpkg binpkg-ignore-signature"
EMERGE_DEFAULT_OPTS="--getbinpkg --quiet-build=y --keep-going"
```

Confirm with `emerge --info | grep FEATURES`, and double-check
`CPU_FLAGS_X86` matches exactly — even one flag off will make Portage reject
the binary.

</details>

<details>
<summary>Signature verification errors</summary>
<br>

`nexus`'s own binaries are unsigned (`verify-signature = false`) — that's
expected. The official `[gentoo-official-v3]` host *is* signed; run `getuto`
once to trust it.

</details>

<details>
<summary>Package not found / 404 after an update</summary>
<br>

Clear the local cache and resync:

```bash
rm -rf /var/cache/binhost/*
nexus sync
```

</details>

<details>
<summary>Mesa / Vulkan problems</summary>
<br>

Make sure 32-bit support is enabled:

```bash
echo "media-libs/mesa abi_x86_32" >> /etc/portage/package.use/graphics
echo "media-libs/vulkan-loader abi_x86_32" >> /etc/portage/package.use/graphics
```

If you added these after installing, rebuild:

```bash
emerge -g --oneshot media-libs/mesa media-libs/vulkan-loader
```

</details>

<details>
<summary>"Error: circular dependencies" when installing Electron apps (obsidian, vesktop, zen-browser, brave, rootapp)</summary>
<br>

<b>Fixed at the root on 2026-08-24.</b> Upstream <code>sys-libs/ncurses</code>
with the <code>gpm</code> flag and <code>sys-libs/gpm</code> require each other
at runtime — a cycle Portage cannot order inside one binary-only transaction.
The binhost now ships <code>ncurses</code> built with <code>-gpm</code>
(exactly like the official Gentoo x86-64-v3 binhost) and the shipped
<code>machine/package.use</code> pins <code>sys-libs/ncurses -gpm</code>, so
the ncurses→gpm runtime edge never exists and the cycle cannot occur.
If you pinned <code>+gpm</code> manually, switch to the shipped config.

</details>

<details>
<summary>A few packages always recompile instead of using the binary</summary>
<br>

Binaries are matched by USE flags too. When ::gentoo flips a profile default
(e.g. `sysprof`, `gstreamer`), packages built by the binhost before the flip
no longer match a fresh tree. The shipped `machine/package.use` pins the
consumer's flags to the published binaries for exactly this reason — keep it
in sync (it mirrors the builder). Symptom in emerge output:

```text
!!! The following binary packages have been ignored due to non matching USE:
    =dev-libs/glib-2.88.3 sysprof
```

Add the shown flag to `/etc/portage/package.use/` (or copy the latest
`machine/package.use`) and the binary is accepted again.

</details>

<details>
<summary>Duplicate repository error</summary>
<br>

```bash
eselect repository remove gentoo-nexus
```

Then redo the overlay setup ([Manual install](#manual-install), step 2).

</details>

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=soft&color=0:0f0c29,50:44337a,100:8b5cf6&height=120&section=footer" width="100%" alt="" />

<sub>built on Gentoo · powered by Portage · automated with GitHub Actions</sub>

[![GitHub](https://img.shields.io/badge/Ackerman--00-gentoo--nexus-8b5cf6?style=flat-square&logo=github)](https://github.com/Ackerman-00/gentoo-nexus)

</div>
