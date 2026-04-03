<div align="center">
<br>

```
 ██████╗ ███████╗███╗   ██╗████████╗ ██████╗  ██████╗       ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██╔═══██╗██╔═══██╗      ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
██║  ███╗█████╗  ██╔██╗ ██║   ██║   ██║   ██║██║   ██║█████╗██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
██║   ██║██╔══╝  ██║╚██╗██║   ██║   ██║   ██║██║   ██║╚════╝██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
╚██████╔╝███████╗██║ ╚████║   ██║   ╚██████╔╝╚██████╔╝      ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
 ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝  ╚═════╝       ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
```

<br>

*A self-healing Gentoo overlay and autonomous binary host.*<br>
*Track upstream. Build automatically. Deliver pre-compiled. Stay bleeding-edge.*

<br>

[![Forge](https://img.shields.io/github/actions/workflow/status/Ackerman-00/gentoo-nexus/build.yml?branch=main&style=flat-square&label=forge&color=7c3aed&labelColor=0d1117&logo=githubactions&logoColor=white)](https://github.com/Ackerman-00/gentoo-nexus/actions)
[![Binhost](https://img.shields.io/badge/binhost-live-059669?style=flat-square&labelColor=0d1117&logo=linux&logoColor=white)](https://Ackerman-00.github.io/gentoo-nexus/)
[![Rolling](https://img.shields.io/badge/release-rolling-d97706?style=flat-square&labelColor=0d1117)](https://github.com/Ackerman-00/gentoo-nexus)
[![Target](https://img.shields.io/badge/target-wayland%20%C2%B7%20amd64-2563eb?style=flat-square&labelColor=0d1117)](https://wayland.freedesktop.org/)
[![License](https://img.shields.io/github/license/Ackerman-00/gentoo-nexus?style=flat-square&labelColor=0d1117&color=4b5563)](LICENSE)

<br>

[Overview](#-overview) · [The Stack](#-the-stack) · [How It Works](#-how-it-works) · [Installation](#-installation) · [Usage](#-usage) · [Troubleshooting](#-troubleshooting)

<br>
</div>

---

<br>

## Overview

**gentoo-nexus** is a Gentoo overlay with an attached autonomous binary host. Every package is tracked, compiled inside isolated containers by a GitHub Actions CI/CD pipeline, and published to a GitHub Pages vault — automatically, on every push and on a nightly schedule.

Your local Portage is pointed at that vault before the official Gentoo mirrors. The result is a fully rolling, bleeding-edge Wayland desktop where heavy packages like `niri`, `mesa`, and `rust` arrive pre-built in seconds, not hours.

There are no stable snapshots. The forge runs continuously.

<br>

---

<br>

## The Stack

A modern Wayland desktop centred on the **niri** scrollable-tiling compositor.

<br>

<div align="center">

| Package | Category | Purpose |
|:---|:---:|:---|
| `niri` | Compositor | Scrollable-tiling Wayland compositor |
| `mangowc` | Compositor | Lightweight Wayland compositor layer |
| `dank-material-shell` | Shell | Material Design shell layer (Go) |
| `quickshell` | Widgets | Scriptable desktop widget engine |
| `matugen` | Theming | Material You color token generator |
| `xwayland-satellite` | Compatibility | Rootless XWayland for legacy apps |
| `dgop` | Launcher | Fast application launcher |
| `danksearch` | Search | System-wide fuzzy search |

</div>

<br>

Dependencies for `quickshell`, `scenefx`, and `libdisplay-info` are pulled from the [GURU](https://wiki.gentoo.org/wiki/Project:GURU) overlay.

<br>

---

<br>

## How It Works

```
  upstream git
       │
       ▼
  ┌─────────────────────────────────────────────────────┐
  │                  NEXUS CI/CD FORGE                  │
  │                                                     │
  │   version detector  ──►  ebuild patcher             │
  │                               │                     │
  │                               ▼                     │
  │   parallel build matrix  (isolated containers)      │
  │                               │                     │
  │                               ▼                     │
  │              gpkg publisher                         │
  └───────────────────┬─────────────────────────────────┘
                      │
                      ▼
              GitHub Pages vault
              (.gpkg.tar artifacts)
                      │
                      ▼
            your machine  ──►  emerge -G  ──►  done
```

**Per-run sequence**

1. Detect changed ebuilds and upstream version bumps
2. Build each package in a clean Portage container
3. Publish finished `.gpkg.tar` files to the binary host
4. Verify the `Packages` index before marking the run green

Large Rust builds (e.g. `niri`) use `--jobs=2` to prevent OOM on GitHub's runners. `dank-material-shell` builds without the `go-module` eclass to avoid vendor-directory requirements.

<br>

---

<br>

## Installation

### 1 — Add the overlay

Create the repos.conf entry so Portage can fetch the ebuilds:

```bash
nano /etc/portage/repos.conf/gentoo-nexus.conf
```

```ini
[gentoo-nexus]
location  = /var/db/repos/gentoo-nexus
sync-type = git
sync-uri  = https://github.com/Ackerman-00/gentoo-nexus.git
priority  = 9999
```

Sync it down:

```bash
emaint sync -r gentoo-nexus
```

<br>

### 2 — Add the binary host

Point Portage at the pre-compiled vault. Priority `99999` makes your system check here before any official mirror:

```bash
nano /etc/portage/binrepos.conf/nexus.conf
```

```ini
[gentoo-nexus-bin]
priority         = 99999
sync-uri         = https://Ackerman-00.github.io/gentoo-nexus/
verify-signature = false
```

> `verify-signature = false` is required — the forge does not use Portage's GPG signing infrastructure. The connection itself is encrypted over HTTPS.

<br>

### 3 — Configure make.conf

Tell Portage to prefer binaries and not reject packages over minor USE-flag differences:

```bash
nano /etc/portage/make.conf
```

```bash
# ── Nexus Binary Host ──────────────────────────────────────────── #

FEATURES="getbinpkg"

EMERGE_DEFAULT_OPTS="--getbinpkg --binpkg-respect-use=n --binpkg-changed-deps=n"
```

Without `--binpkg-respect-use=n`, Portage will refuse pre-built packages whose USE set differs from your local profile and fall back to compiling from source.

<br>

---

<br>

## Usage

**Full system upgrade via binary host:**
```bash
emerge -uDNaG @world
```

**Install a specific package (binary-preferred):**
```bash
emerge -avG gui-wm/niri
emerge -avG gui-apps/dank-material-shell
```

**Binary-only, no source fallback:**
```bash
emerge --getbinpkgonly gui-wm/niri
```

**Sync overlay then upgrade:**
```bash
emaint sync -r gentoo-nexus && emerge -uDNaG @world
```

**Trigger a manual build in the forge:**  
Go to [Actions](https://github.com/Ackerman-00/gentoo-nexus/actions) → **Nexus Genesis** → `Run workflow`. To rebuild a single package, type its atom into the input field before running (e.g. `gui-wm/mangowc`).

<br>

---

<br>

## Troubleshooting

**No binary found for a package**  
The forge may still be building it, or a version bump happened before the nightly run. Trigger a manual build from the Actions tab, wait a few minutes, then retry.

**Binary rejected — USE flag mismatch**  
Confirm `--binpkg-respect-use=n` and `--binpkg-changed-deps=n` are present in `EMERGE_DEFAULT_OPTS`.

**`verify-signature` warning in emerge output**  
Expected and harmless. The binary host uses HTTPS for transport security; Portage GPG signing is not configured.

**Sync fails with an auth error**  
The repository is public. Auth errors usually mean a skewed system clock — fix with `ntpd -q` or `chronyc makestep`.

**Portage ignores the binary host entirely**  
Confirm `getbinpkg` is in `FEATURES` and that `sync-uri` in `binrepos.conf` ends with a trailing `/`.

<br>

---

<br>

<div align="center">

[![GitHub](https://img.shields.io/badge/Ackerman--00-0d1117?style=flat-square&logo=github&logoColor=white)](https://github.com/Ackerman-00)
[![Binhost](https://img.shields.io/badge/binary%20host-live-059669?style=flat-square&labelColor=0d1117&logo=githubpages&logoColor=white)](https://Ackerman-00.github.io/gentoo-nexus/)

<br>

```
the forge never sleeps
```

<br>
</div>
