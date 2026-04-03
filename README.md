<div align="center">
<br>

<img src="https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=700&size=38&duration=1&pause=99999&color=7C3AED&center=true&vCenter=true&repeat=false&width=600&height=70&lines=gentoo-nexus" alt="gentoo-nexus" />

<img src="https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=400&size=14&duration=1&pause=99999&color=6B7280&center=true&vCenter=true&repeat=false&width=600&height=30&lines=Autonomous+Gentoo+overlay+%C2%B7+self-healing+binary+host+%C2%B7+rolling+release" alt="subtitle" />

<br>

[![Forge](https://img.shields.io/github/actions/workflow/status/Ackerman-00/gentoo-nexus/build.yml?branch=main&style=flat-square&label=forge&color=7c3aed&labelColor=0d1117&logo=githubactions&logoColor=white)](https://github.com/Ackerman-00/gentoo-nexus/actions)
[![Binhost](https://img.shields.io/badge/binhost-live-059669?style=flat-square&labelColor=0d1117&logo=linux&logoColor=white)](https://Ackerman-00.github.io/gentoo-nexus/)
[![Rolling](https://img.shields.io/badge/release-rolling-d97706?style=flat-square&labelColor=0d1117)](https://github.com/Ackerman-00/gentoo-nexus)
[![Target](https://img.shields.io/badge/amd64-wayland-2563eb?style=flat-square&labelColor=0d1117)](https://wayland.freedesktop.org/)
[![License](https://img.shields.io/github/license/Ackerman-00/gentoo-nexus?style=flat-square&labelColor=0d1117&color=4b5563)](LICENSE)

<br>

[Installation](#installation) · [Usage](#usage) · [The Stack](#the-stack) · [Troubleshooting](#troubleshooting)

<br>
</div>

---

Every package in this overlay is automatically tracked upstream, compiled in an isolated container, and published to a GitHub Pages binary vault — on every push and on a nightly schedule. Your local Portage pulls from that vault first. Heavy packages like `niri`, `mesa`, and `rust` arrive pre-built in seconds, not hours.

---

## Installation

### 1 — Add the overlay

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

```bash
emaint sync -r gentoo-nexus
```

### 2 — Add the binary host

```bash
nano /etc/portage/binrepos.conf/nexus.conf
```

```ini
[gentoo-nexus-bin]
priority         = 99999
sync-uri         = https://Ackerman-00.github.io/gentoo-nexus/
verify-signature = false
```

> `verify-signature = false` is required — the forge does not use Portage GPG signing. Transport is encrypted over HTTPS.

### 3 — Configure make.conf

```bash
nano /etc/portage/make.conf
```

```bash
# ── Nexus Binary Host ──────────────────────────────────────────────────────── #

FEATURES="getbinpkg"
EMERGE_DEFAULT_OPTS="--getbinpkg --binpkg-respect-use=n --binpkg-changed-deps=n"
```

Without `--binpkg-respect-use=n`, Portage rejects pre-built packages whose USE set differs from your local profile and falls back to compiling from source.

---

## Usage

```bash
# Upgrade entire system via binary host
emerge -uDNaG @world

# Install a specific package (binary-preferred)
emerge -avG gui-wm/niri

# Binary-only, no source fallback
emerge --getbinpkgonly gui-wm/niri

# Sync overlay then upgrade
emaint sync -r gentoo-nexus && emerge -uDNaG @world
```

**Manual build trigger —** [Actions](https://github.com/Ackerman-00/gentoo-nexus/actions) → **Nexus Genesis** → `Run workflow`. To rebuild a single package, enter its atom (e.g. `gui-wm/mangowc`) into the input field before running.

---

## The Stack

A bleeding-edge Wayland desktop centred on the **niri** scrollable-tiling compositor.

<div align="center">
<br>

| Package | Purpose |
|:---|:---|
| `gui-wm/niri` | Scrollable-tiling Wayland compositor |
| `gui-wm/mangowc` | Lightweight Wayland compositor layer |
| `gui-apps/dank-material-shell` | Material Design shell (Go) |
| `gui-apps/quickshell` | Scriptable desktop widget engine |
| `app-misc/matugen` | Material You color token generator |
| `x11-misc/xwayland-satellite` | Rootless XWayland for legacy apps |
| `gui-apps/dgop` | Fast application launcher |
| `app-misc/danksearch` | System-wide fuzzy search |

<br>
</div>

Dependencies for `quickshell`, `scenefx`, and `libdisplay-info` are pulled from [GURU](https://wiki.gentoo.org/wiki/Project:GURU).

---

## Troubleshooting

**No binary found for a package** — the forge may still be building it. Trigger a manual build from Actions and retry after a few minutes.

**Binary rejected / USE flag mismatch** — confirm `--binpkg-respect-use=n` and `--binpkg-changed-deps=n` are in `EMERGE_DEFAULT_OPTS`.

**`verify-signature` warning** — expected and harmless. HTTPS secures the transport; Portage GPG signing is not configured.

**Sync auth error** — the repo is public. A skewed system clock is the usual cause. Fix with `ntpd -q` or `chronyc makestep`.

**Binary host ignored entirely** — confirm `getbinpkg` is in `FEATURES` and that `sync-uri` ends with a trailing `/`.

---

<div align="center">
<br>

*the forge never sleeps*

<br>
</div>
