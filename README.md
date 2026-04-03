<div align="center">

<br>

```
███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
```

<h3>
  <samp>A bleeding-edge Gentoo overlay & autonomous binary host</samp><br>
  <samp>powered by a self-healing GitHub Actions CI/CD cluster</samp>
</h3>

<br>

[![CI/CD Status](https://img.shields.io/github/actions/workflow/status/Ackerman-00/gentoo-nexus/build.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=NEXUS%20FORGE&color=6e40c9&labelColor=0d1117)](https://github.com/Ackerman-00/gentoo-nexus/actions)
[![Packages](https://img.shields.io/badge/PACKAGES-AUTO--BUILT-6e40c9?style=for-the-badge&logo=gentoo&logoColor=white&labelColor=0d1117)](https://Ackerman-00.github.io/gentoo-nexus/)
[![Binhost](https://img.shields.io/badge/BINHOST-LIVE-00c96e?style=for-the-badge&logo=cloudflare&logoColor=white&labelColor=0d1117)](https://Ackerman-00.github.io/gentoo-nexus/)
[![Rolling Release](https://img.shields.io/badge/ROLLING-RELEASE-c96e00?style=for-the-badge&logo=linux&logoColor=white&labelColor=0d1117)](https://github.com/Ackerman-00/gentoo-nexus)

<br>
<br>

```
  OVERLAY ──────► GITHUB ACTIONS ──────► BINHOST ──────► YOUR MACHINE
  (ebuilds)          (CI forge)         (pre-built)       (emerge -G)
```

<br>

</div>

---

<div align="center">
  <h2>◈ &nbsp; W H A T &nbsp; I S &nbsp; T H I S &nbsp; ◈</h2>
</div>

**gentoo-nexus** is a fully autonomous Gentoo overlay with an attached binary host. Every package in this repository is **automatically tracked, built, and published** — you pull pre-compiled binaries directly to your machine instead of spending hours compiling from source.

The CI/CD pipeline watches upstream commits, detects version bumps, rebuilds affected packages, and deposits the finished `.gpkg.tar` artifacts on a GitHub Pages binary vault. Your local Portage is configured to pull from there first, before ever touching the official Gentoo mirrors.

> **No compiling `mesa`. No compiling `llvm`. No compiling `rust`.**  
> They arrive pre-built, hot from the forge.

<br>

<div align="center">
  <h2>◈ &nbsp; T H E &nbsp; S T A C K &nbsp; ◈</h2>
</div>

<div align="center">

| Layer | Package | Description |
|:---:|:---:|:---|
| 🪟 **Compositor** | `niri` | Scrollable tiling Wayland compositor |
| 🐚 **Shell** | `dank-material-shell` | Material Design shell layer (Go) |
| 🎨 **Theming** | `matugen` | Material You color token generator |
| 🖥️ **X Bridge** | `xwayland-satellite` | Rootless XWayland for legacy apps |
| 🔍 **Search** | `danksearch` | Fast system-wide fuzzy search |
| 🎮 **Launch** | `dgop` | Application launcher |
| 🔊 **Audio** | `pipewire` | Low-latency audio/video routing |
| 📦 **Widget** | `quickshell` | Scriptable desktop widget engine |

</div>

<br>

---

<br>

<div align="center">
  <h2>◈ &nbsp; I N S T A L L A T I O N &nbsp; ◈</h2>
  <p><samp>Three steps. Then you're wired in.</samp></p>
</div>

<br>

### ❶ &nbsp; Add the Overlay

Create the repository config so Portage knows where to fetch ebuilds:

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

### ❷ &nbsp; Add the Binary Host

Point Portage at the pre-compiled vault. Priority `99999` means it always checks here **before** the official Gentoo mirrors:

```bash
nano /etc/portage/binrepos.conf/nexus.conf
```

```ini
[gentoo-nexus-bin]
priority       = 99999
sync-uri       = https://Ackerman-00.github.io/gentoo-nexus/
verify-signature = false
```

> `verify-signature = false` is required because the CI forge signs packages with an ephemeral key.  
> Packages are still fetched over HTTPS — the transport is encrypted.

<br>

### ❸ &nbsp; Tune `make.conf`

Tell Portage to prefer binaries and relax strict USE-flag enforcement so it doesn't reject pre-built packages for minor flag differences:

```bash
nano /etc/portage/make.conf
```

```bash
# ── Nexus Binhost Integration ─────────────────────────────────────────────── #

FEATURES="getbinpkg"

EMERGE_DEFAULT_OPTS="--getbinpkg --binpkg-respect-use=n --binpkg-changed-deps=n"
```

<br>

---

<br>

<div align="center">
  <h2>◈ &nbsp; U S A G E &nbsp; ◈</h2>
</div>

<br>

**Upgrade your entire world from the binary vault:**

```bash
emerge -uDNqaG @world
```

**Install a specific package (binary-only):**

```bash
emerge -avG gui-wm/niri
emerge -avG gui-wm/mangowc
emerge -avG app-misc/danksearch
```

**Force a sync then upgrade:**

```bash
emaint sync -r gentoo-nexus && emerge -uDNqaG @world
```

<br>

---

<br>

<div align="center">
  <h2>◈ &nbsp; H O W &nbsp; T H E &nbsp; F O R G E &nbsp; W O R K S &nbsp; ◈</h2>
</div>

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NEXUS CI/CD FORGE                           │
│                                                                     │
│   upstream git  ──►  version detector  ──►  ebuild patcher         │
│                                                   │                 │
│                                                   ▼                 │
│   GitHub Pages  ◄──  gpkg publisher  ◄──  parallel build matrix    │
│   (binary host)                                                     │
│        │                                                            │
│        ▼                                                            │
│   your machine  ──►  emerge -G  ──►  installed in seconds          │
└─────────────────────────────────────────────────────────────────────┘
```

The CI pipeline runs on a schedule **and** triggers on every push to `main`. Each job:

1. 🔎 **Detects** which ebuilds changed or have upstream version bumps
2. 🏗️ **Builds** packages in a clean Docker container with the correct `FEATURES` and `CFLAGS`
3. 📤 **Deploys** finished `.gpkg.tar` files to the GitHub Pages binary host
4. ✅ **Verifies** the published index is intact before marking the run green

<br>

---

<br>

<div align="center">
  <h2>◈ &nbsp; M A N U A L &nbsp; T R I G G E R S &nbsp; ◈</h2>
</div>

The forge runs automatically, but you can kick it manually at any time:

**Trigger a full rebuild:**
> GitHub → [Actions](https://github.com/Ackerman-00/gentoo-nexus/actions) → **Nexus Genesis** → `Run workflow`

**Sniper mode — rebuild one specific package:**
> Same as above, but type the atom into the input box, e.g. `gui-wm/mangowc`

<br>

---

<br>

<div align="center">
  <h2>◈ &nbsp; T R O U B L E S H O O T I N G &nbsp; ◈</h2>
</div>

<br>

**Portage says no binary is available for a package**

The CI forge may still be building it, or the upstream ebuild updated before the pipeline could run. Trigger a manual Sniper Mode build from the Actions tab (see above), then wait a few minutes and retry.

**Binary is rejected due to USE flags**

Double-check that `--binpkg-respect-use=n` and `--binpkg-changed-deps=n` are present in your `EMERGE_DEFAULT_OPTS`. Without these, Portage will refuse binaries compiled with a slightly different USE set.

**Sync fails with authentication error**

The repository is public. If you get auth errors, your system clock may be out of sync. Run `ntpd -q` or `chronyc makestep` to fix it.

**`verify-signature` warning in emerge output**

This is expected and harmless. The warning appears because the binary host does not use Portage's GPG signing infrastructure. The connection itself is encrypted via HTTPS.

<br>

---

<br>

<div align="center">
  <h2>◈ &nbsp; R E P O &nbsp; L A Y O U T &nbsp; ◈</h2>
</div>

```
gentoo-nexus/
│
├── .github/
│   └── workflows/          # CI/CD forge definitions
│       ├── build.yml       # Main parallel build matrix
│       └── deploy.yml      # Binary host publish logic
│
├── metadata/
│   └── layout.conf         # Portage overlay metadata
│
├── profiles/
│   └── repo_name           # Overlay identity
│
├── gui-wm/                 # Window manager ebuilds
│   ├── niri/
│   └── mangowc/
│
├── gui-apps/               # Wayland application ebuilds
│   ├── dank-material-shell/
│   ├── quickshell/
│   ├── danksearch/
│   └── dgop/
│
├── media-sound/            # Audio stack
│   └── pipewire/
│
└── x11-misc/
    ├── matugen/
    └── xwayland-satellite/
```

<br>

---

<br>

<div align="center">

<samp>
Built with obsession on Gentoo Linux.<br>
Rolling release. No training wheels. No binary blobs (except the ones we built ourselves).
</samp>

<br>
<br>

[![GitHub](https://img.shields.io/badge/github-Ackerman--00-6e40c9?style=for-the-badge&logo=github&logoColor=white&labelColor=0d1117)](https://github.com/Ackerman-00)
[![Overlay](https://img.shields.io/badge/overlay-gentoo--nexus-c96e00?style=for-the-badge&logo=gentoo&logoColor=white&labelColor=0d1117)](https://github.com/Ackerman-00/gentoo-nexus)
[![Binhost](https://img.shields.io/badge/binhost-LIVE-00c96e?style=for-the-badge&logo=cloudflare&logoColor=white&labelColor=0d1117)](https://Ackerman-00.github.io/gentoo-nexus/)

<br>

```
 emerge --with-bdeps=n --getbinpkgonly --jobs=$(nproc) @world
```

<br>

<sub>「 The forge never sleeps. 」</sub>

</div>
