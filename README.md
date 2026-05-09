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

**gentoo-nexus** is an autonomous Gentoo overlay and binary host targeting a fully configured [niri](https://github.com/niri-wm/niri) scrollable-tiling Wayland desktop. Packages are compiled nightly via GitHub Actions and served as ready-to-install `gpkg` binaries — no waiting for compilation on your end.

```
overlay  →  ebuilds tracked & auto-updated from upstream
binhost  →  pre-built gpkg binaries via GitHub Releases (rolling tag)
CI       →  GitHub Actions rebuilds on every version bump or commit
```

---

## Quick Setup

### ① Add the Overlay

One command — adds and syncs the repository immediately:

```bash
eselect repository add gentoo-nexus git https://github.com/Ackerman-00/gentoo-nexus.git \
  && emaint sync -r gentoo-nexus
```

---

### ② Configure the Binary Host

```bash
nano /etc/portage/binrepos.conf/nexus.conf
```

```ini
[gentoo-nexus-bin]
priority         = 99999
sync-uri         = https://github.com/Ackerman-00/gentoo-nexus/releases/download/rolling/
verify-signature = false
```

---

### ③ Update `make.conf`

```bash
nano /etc/portage/make.conf
```

```bash
# Required: gpkg format for Nexus binaries
BINPKG_FORMAT="gpkg"
FEATURES="getbinpkg"
EMERGE_DEFAULT_OPTS="--getbinpkg --binpkg-respect-use=n --binpkg-changed-deps=n"
```

> **Why `--binpkg-respect-use=n`?**  
> Without it, Portage rejects pre-built packages whose USE flags differ from your local profile and falls back to compiling from source — defeating the point of a binhost.

---

## Packages

| Atom | Description | Track |
|------|-------------|-------|
| `gui-wm/niri` | Scrollable-tiling Wayland compositor | `9999` |
| `gui-wm/mangowc` | Lightweight Wayland compositor layer | stable |
| `gui-apps/dank-material-shell` | Material Design shell for niri | stable |
| `gui-apps/quickshell` | Scriptable desktop widget engine | stable |
| `app-misc/matugen` | Material You color token generator | stable |
| `x11-misc/xwayland-satellite` | Rootless XWayland for any Wayland compositor | `9999` |
| `gui-apps/dgop` | Fast application launcher | stable |
| `app-misc/danksearch` | System-wide fuzzy search | stable |

`9999` ebuilds track upstream HEAD and rebuild automatically on every new commit.

---

## Testing with Distrobox

Try the overlay and binhost safely inside an isolated container — no risk to your host:

```bash
# 1. Create a Gentoo container
distrobox create \
  --image gentoo/stage3:amd64-desktop-openrc \
  --name gentoo-nexus-test

# 2. Enter it
distrobox enter gentoo-nexus-test
```

Inside the container (as root):

```bash
# Sync the Portage tree
emerge-webrsync

# Install prerequisites
emerge app-eselect/eselect-repository dev-vcs/git

# Then follow the Quick Setup steps above ↑
```

---

## Staying Updated

No manual intervention needed. Packages update with your system:

```bash
emerge -uDNaG @world
```

The CI pipeline handles version bumps, binary rebuilds, and index updates automatically.

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

Ensure `make.conf` contains all three flags:

```bash
BINPKG_FORMAT="gpkg"
FEATURES="getbinpkg"
EMERGE_DEFAULT_OPTS="--getbinpkg --binpkg-respect-use=n --binpkg-changed-deps=n"
```

</details>

<details>
<summary><strong>Signature verification error</strong></summary>

Set `verify-signature = false` in your `binrepos.conf`. The binhost does not currently ship signed package indexes.

</details>

<details>
<summary><strong>A package failed to build in CI</strong></summary>

Go to **Actions → Gentoo Build Relay → Run workflow**, enter the package atom (e.g. `gui-wm/niri`), and retry after a few minutes.

</details>

<details>
<summary><strong>eselect repository crashes on duplicate</strong></summary>

If the repo was previously added manually, remove the existing entry first:

```bash
eselect repository remove gentoo-nexus
eselect repository add gentoo-nexus git https://github.com/Ackerman-00/gentoo-nexus.git
```

</details>

---

<div align="center">

<sub>built on Gentoo · powered by Portage · automated with GitHub Actions</sub>

<br/>

[![GitHub](https://img.shields.io/badge/Ackerman--00-gentoo--nexus-4f8a5a?style=flat-square&logo=github)](https://github.com/Ackerman-00/gentoo-nexus)

</div>
