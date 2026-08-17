# AGENTS.md — gentoo-nexus

Work-notes for AI agents and humans maintaining this repo.

Last verified against live Gentoo infrastructure: **2026-08-17** (see
[Sources](#sources) for everything checked).

## What this repo is

A drop-in Portage overlay + binary host ("rolling") for the Wayland desktop.
CI (`build.yml`) rebuilds packages nightly under the **OpenRC
`default/linux/amd64/23.0/desktop/gnome` profile** with
`-march=x86-64-v3` and publishes `.gpkg` binaries to a GitHub release. Consumers
pull from two binrepos: `[nexus]` (this repo, unsigned) and
`[gentoo-official-v3]` (the official Gentoo x86-64-v3 host, signed).

Goal: **no compiling on the consumer machine** — binaries from both worlds,
where nexus covers the AMD / 32-bit / codec deltas and the official host covers
everything else.

## Repo layout

- `machine/` — drop-in consumer config: `make.conf`, `binrepos.conf`,
  `package.use`. **Must stay in sync with `.github/workflows/*.yml`** (both
  producer and consumer use the same flag set).
- `.github/workflows/build.yml` — the nexus binary producer (make.conf + all
  package.use deltas that make nexus different from the official host).
- `.github/workflows/build-gentoo-official.yml`, `check-updates*.yml` — mirror
  the official v3 tree / rebuild triggers. Its default `package_list` is the
  authoritative "what nexus must cover" list (ROCm trio, gentoo-kernel, mesa,
  ffmpeg, vulkan-loader/llvm 32-bit, portage, gcc, …) — everything else is the
  official host's job.
- `tools/nexus` — strict binpkg-only CLI (fails rather than compiles unless
  `--fallback`).
- `setup/quickstart.sh` — full installer.
- `profiles/`, `metadata/` — overlay plumbing.
- Category dirs (`gui-wm/`, `x11-misc/`, …) — ebuilds; every package must be
  built with **profile-default USE** or consumers will be forced to rebuild it.

## The single most important knowledge in this repo

Portage binpkg matching — why a consumer's `emerge` recompiles:

1. **CFLAGS is NOT a binpkg matching key.** The binhost `Packages` index does
   not even contain CFLAGS. `-march=znver4` / `-O3` / `-march=native` in a
   consumer's make.conf never causes binpkg rejection. (Wiki explicitly:
   "Portage can not validate if these requirements match.")
2. **What IS matched per package:** CHOST/CBUILD (index header), KEYWORDS,
   and the **USE set** (incl. `CPU_FLAGS_X86`, `VIDEO_CARDS`, `ABI_X86`,
   `PYTHON_TARGETS`) under `--binpkg-respect-use=y` (the default; auto-disabled
   only under `--usepkgonly`). Dependencies are also checked
   (`--binpkg-changed-deps` auto-on).
3. **Direction of the USE check:** a binpkg with *any* flag the consumer's
   config does not enable is rejected and the package is rebuilt from source
   (e.g. binpkg with `systemd`/`intel`/`x265` enabled, consumer without them →
   source build). This is the #1 reason "some packages compile anyway".

## Official Gentoo x86-64-v3 binhost — verified config

Path: `https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/`

- **CFLAGS:** `-O2 -pipe -march=x86-64-v3` (wiki "Available packages and
  configurations", edited 2026-08-12).
- **CPU_FLAGS_X86** (the ONLY matching CPU key):
  `avx avx2 f16c fma3 mmx mmxext popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3`
- Verified directly against the live `Packages` index (2026-08-17): enabled
  `cpu_flags_x86_*` across all 15,576 entries are **only** those 14 flags.
  The builders' make.conf template (`proj/binhost.git` `milou/openrc-23`)
  defines a wider `CPU_FLAGS_X86_v3` (adds `bmi1 bmi2 lzcnt movbe osxsave`) but
  those are **not** actually enabled in shipped packages. Do not add them.
- **Profiles actually present in the tree** (from per-package USE, verified):
  - `desktop/gnome` (OpenRC — pipewire built with `elogind`, glibc without
    `systemd`) → **this is the matching profile for OpenRC consumers**
  - `desktop/gnome/systemd`, `desktop/plasma/systemd`
  - `no-multilib`
  - leftover `17.0/hardened`-era stage3 packages (old gcc/glibc with `cet`)
- **Header of the index** reports `PROFILE: default/linux/amd64/17.0/hardened`
  and `PACKAGES: 15576` — do not treat the header profile as authoritative;
  per-package USE is.

### Verified per-package USE on the official v3 host (2026-08-17)

| Package | USE deltas that matter |
|---|---|
| `media-libs/mesa` | `video_cards_intel video_cards_nouveau video_cards_radeon video_cards_radeonsi` (no `amdgpu` flag, no `abi_x86_32`, no `opencl`/`rust`/`lm-sensors`; profile-default `X vulkan wayland llvm llvm_slot_22 opengl proprietary-codecs zstd` ± `sysprof`) |
| `llvm-core/llvm` | `xml` ON (profile default), `llvm_targets_AMDGPU` ON, `binutils-plugin libffi ncurses zstd`; 61 builds over slots 17–22, some `debug`; **slots 19–22 also ship `abi_x86_32` builds** (see 32-bit note below) |
| `llvm-core/clang` | `extra` ON, `pie`, `static-analyzer`, `xml`, `python_single_target_python3_{12,13,14}` variants |
| `dev-libs/opencl-clang` | **only 17.0.7 / llvm_slot_17** — the newest OpenCL compiler on the host |
| `media-video/ffmpeg` | all 8.1.2 variants: `x264` + `dav1d` ON (profile global USE `x264` + FFMPEG_IUSE_MAP `+dav1d`), 6/8 also `opus vpx lame theora xvid`; **no `vaapi vdpau x265`** anywhere |
| `media-video/pipewire` | families: `elogind pulseaudio sound-server` (±`gstreamer bluetooth`), `sound-server systemd` (±`gstreamer`) |
| `sys-devel/gcc` | 26 variants: `cet lto multilib pgo pie ssp` ± `jit`, newer ones + `default-stack-clash-protection default-znow` |
| `sys-libs/glibc` | `cet ssp` ± `multilib` ± `systemd`; versions 2.38–2.43 (2.38 = 17.0/hardened-era leftover) |
| `dev-lang/rust` / `rust-bin` | 1.74.1 → 1.96.1 (old hardened-era builds + current) — official host covers rust, nexus does NOT build it |
| `sys-apps/portage` | `native-extensions` + `python_targets_python3_13` and/or `_3_14` (3.14 default since 2026-06-01) |
| `media-libs/vulkan-loader` | `abi_x86_64` only, ±`X wayland` |
| `sys-apps/systemd` / `systemd-utils` | 260.1 present (systemd profiles) |
| 32-bit (`abi_x86_32`) stack | **The official host DOES ship 32-bit builds — 24 distinct packages** (gaming base): `sys-libs/glibc` + `sys-devel/gcc` with `multilib` (32-bit libc!), the whole LLVM stack (llvm/clang/compiler-rt/sanitizers/clang-runtime/libcxxabi/openmp **slots 19–22 with `abi_x86_32`**), `app-emulation/dxvk` + `vkd3d-proton` (Wine/Proton translation layers), and base libs: zlib, xz-utils, zstd, libffi, icu, libxml2, ncurses, libxcrypt, gpm, sandbox, boehm-gc, libatomic_ops (+ virtual/libcrypt, virtual/zlib). **NOT 32-bit on the host**: mesa, libglvnd, vulkan-loader, libdrm, alsa-lib, expat, spirv-tools, wayland, libva, x11-libs (libX11/libxcb/…), freetype, fontconfig, libpng, bzip2, lz4, glib, sdl2, libpulse, dbus, udev — nexus builds these (GAMING block). |

### Official host coverage map — what exists vs. what nexus must build (verified 2026-08-17)

**ON the official x86-64-v3 host:** the whole LLVM stack (llvm/clang/lld/
compiler-rt/sanitizers/libclc/openmp/offload, slots 17–22), mesa (26.0.8 +
26.1.6), vulkan-loader, gcc, glibc, rust + rust-bin (current versions), portage,
pipewire (both init families), ffmpeg, opencl-clang-17.0.7, opencl-icd-loader,
opencl-headers, virtual/opencl, xf86-video-amdgpu, libva, zed (1.7.2/1.10.3),
systemd, gentoo-sources (source ebuild only).

**NOT on the official host — nexus must (and does) build these:**
- **ROCm / modern OpenCL: everything.** No roct-thunk-interface, no
  rocr-runtime, no rocm-opencl-runtime, no hip/rocminfo/rocm-smi anywhere in
  the index (checked all 15,576 CPVs). opencl-clang is stuck at 17.0.7.
  Root cause: the whole ROCm stack is `~amd64`-keyworded in ::gentoo (e.g.
  rocm-opencl-runtime 7.2.0) and the official binhost only builds stable
  keywords — so ROCm can only ever arrive via nexus or a local build.
- **Kernels: everything.** No `gentoo-kernel`, `gentoo-kernel-bin`, or
  `dist-kernel` binaries (kernel config is machine-specific). Consumers always
  get the kernel from nexus, or compile.
- gaming/tools: heroic-bin, rustup, blender-bin, godot, libva-intel-media-driver.
- All nexus deltas: mesa `-rust -opencl` + `amdgpu radeonsi` + `abi_x86_32`
  (no `lm-sensors`! profile default is off for mesa, so enabling it would
  reject nexus mesa for every consumer), ffmpeg codecs, llvm `-xml` +
  `abi_x86_32`, vulkan-loader `abi_x86_32 layers`, libdrm
  `video_cards_amdgpu video_cards_radeon` (no `video_cards_intel` — the
  consumer's `-* amdgpu radeonsi` resets it; see `build-gentoo-official.yml`
  default `package_list`).
- The USES heredoc (`package.use/nexus`, both workflows, byte-identical) was
  re-audited 2026-08-17 against consumer effective flags and the live v3
  index. Every line must equal the consumer's effective USE, never a superset
  or subset:
  - `installkernel dracut grub` (consumer quickstart sets both — `grub` was
    missing → nexus binpkg rejected → installkernel source build).
  - `linux-firmware redistributable initramfs` (NO `compress-zstd` — that flag
    is not profile-default on the consumer; initramfs/redistributable are
    IUSE-default ON).
  - `networkmanager bluetooth modemmanager` (consumer has both: `bluetooth`
    from the desktop global USE, `modemmanager` is an IUSE default; the old
    `-modemmanager -bluetooth` made nexus NM rejected for every consumer with
    `abi_x86_32` NM, since the official host ships no 32-bit NM).
  - `ncurses gpm` (consumer has `gpm` from the desktop global USE; official
    32-bit ncurses lacks gpm → nexus is the only 32-bit gpm source).
  - `seatd server` (consumer sets `sys-auth/seatd server` in quickstart
    global_overrides + `machine/package.use` so the seatd daemon builds and
    matches; NO `builtin` — the consumer doesn't enable it).
  - `opus abi_x86_64`, `gtk introspection` (gnome target USE), `dbus -systemd
    elogind`, `pipewire -systemd elogind -ffmpeg`, mesa, libdrm, `VIDEO_CARDS`
    reset, ffmpeg codecs (opt-in delta) — verified matching; dormant lines
    (`minizip-ng compat`, `libdbusmenu gtk3`, `zlib-ng abi_x86_32 abi_x86_64
    compat`) build packages nothing in the consumer graph pulls — harmless.

Consumer implication: an OpenCL/ROCm or kernel user depends on nexus; a plain
desktop user gets nearly everything from the official host + nexus mesa/ffmpeg.

### 32-bit gaming (`abi_x86_32`) — three-way split (verified 2026-08-17)

A Steam/Proton consumer enables `abi_x86_32` on ~142 packages (see
`setup/quickstart.sh` steam block / the Steam wiki list). Coverage is split
between three sources:

1. **Official host already ships 32-bit** (~24 pkgs, the cheap/small base):
   glibc+glibc (multilib), gcc (multilib), zlib, xz-utils, zstd, libffi, icu,
   libxml2, ncurses, libxcrypt, gpm, sandbox, boehm-gc, libatomic_ops, the
   whole LLVM stack slots 19–22 (llvm/clang/compiler-rt/sanitizers/clang-
   runtime/libcxxabi/openmp), dxvk + vkd3d-proton.
2. **Nexus GAMING block ships 32-bit** (~136 pkgs — the FULL Steam wiki list
   mirror, grown 2026-08-17): the graphics stack (mesa, libglvnd,
   vulkan-loader `layers`, alsa-lib, libdrm, spirv-tools, expat, elfutils,
   x11-libs set, wayland, libva, libdisplay-info), plus the whole middle
   tier that previously compiled on the consumer: freetype, fontconfig,
   libpng, glib, sdl2+sdl3, libpulse, pipewire, gtk+/cairo/pango/pixman/
   harfbuzz, openssl/curl/sqlite/nss/nspr/gnutls, dbus, systemd-utils,
   util-linux, libcap, pam, readline, libudev-compat, libusb, lz4,
   libgcrypt/libgpg-error, jpeg-turbo/tiff/lcms, vorbis/ogg/flac/sndfile/
   openal/opus, cups, networkmanager, colord, gdk-pixbuf, librsvg, vulkan-
   layers/glslang, and `sys-libs/glibc hash-sysv-compat` (EAC anti-cheat;
   the official host's glibc lacks that flag → without this, EAC consumers
   would rebuild glibc).
   Excluded on purpose (NOT in the GAMING heredoc, keep them out):
   - `dev-lang/rust` + `rust-bin` — no `abi_x86_32` IUSE (inert flags; the
     official host already covers rust 64-bit). The quickstart steam block
     keeps the lines — they're harmless no-ops on the consumer.
   - `x11-libs/extest` — only exists in steam-overlay, not ::gentoo, so the
     nexus builder (plain ::gentoo) cannot build it.
   - `sys-apps/systemd` — dormant on OpenRC consumers (masked by the
     quickstart; systemd-profile users get it from the official host).
   - NVIDIA-only: `x11-drivers/nvidia-drivers`, `gui-libs/egl-*` (can't
     build proprietary drivers on AMD CI).
   The GAMING heredoc is duplicated in BOTH `build.yml` and
   `build-gentoo-official.yml` and **must stay byte-identical to the
   quickstart steam block** (minus the exclusions above, plus
   `media-libs/libsdl3` which quickstart also now has). Every non-virtual
   GAMING atom is ALSO in `TRACKED_PKGS` (`check-updates-gentoo-official.yml`)
   and the default `package_list` (`build-gentoo-official.yml`) so bumps get
   rebuilt nightly. `virtual/*` atoms are deliberately NOT tracked: their
   `.gpkg.tar` asset name would collide with their provider's (virtual/glu →
   `glu-…` vs media-libs/glu → `glu-…`).
3. **Neither — must compile on the consumer** (~8 pkgs, by design): only
   rust/rust-bin 32-bit (inert), extest, nvidia/egl-* (NVIDIA-only, AMD
   consumers never pull them), systemd (dormant on OpenRC). Everything else
   on the Steam list is now binary-served by official + nexus.

### The trap table — what makes a consumer rebuild (vs. pull a binary)

| Consumer setting | Effect |
|---|---|
| `CPU_FLAGS_X86` ≠ exact 14-flag set (e.g. adds `bmi1 bmi2 avx512* aes pclmul`) | **all** CPU-flag packages rebuilt from source |
| `VIDEO_CARDS="-* amdgpu radeonsi"` | official mesa rejected (has `intel`+) → mesa source build unless nexus provides it (it does) |
| `media-libs/mesa abi_x86_32` etc. | official mesa/vulkan-loader rejected → nexus builds the 32-bit stack (see `build.yml` gaming block) |
| Builder `mesa lm-sensors` or `libdrm video_cards_intel` (latent bugs, fixed 2026-08-17) | nexus binpkg carries a flag the `-*` consumer doesn't enable → nexus itself rejected → mesa/libdrm source build. Nexus must build mesa `-rust -opencl` + `amdgpu radeonsi` (NO `lm-sensors`) and libdrm `video_cards_amdgpu video_cards_radeon` (NO `intel`) — exactly what the consumer's profile + package.use produce |
| `llvm-core/llvm -xml` | official llvm rejected (xml is profile-default ON) → nexus builds llvm `-xml` (it does, via the gaming block) |
| `media-video/ffmpeg x265 vaapi vdpau …` | official ffmpeg rejected (no x265/vaapi/vdpau) → nexus builds it. Plain x264/dav1d consumers match official 8.1.2 builds directly |
| OpenRC user on `desktop/gnome/systemd` or any systemd profile | glibc/pipewire/etc. mismatched |
| Global `USE="…"` in make.conf deviating from profile defaults | whole-tree mismatches |
| Python 3.13-only targets after 3.14 default | portage/most of tree rebuilt |
| Any ROCm/OpenCL or `sys-kernel/gentoo-kernel` atom | nothing on the official host — nexus is the only binary source (or source build) |

Strategy (both worlds): **consumer keeps profile-default USE everywhere**; every
deviation from official is covered by a nexus ebuild/build. Deviations that
have no nexus build → source build is unavoidable (by design).

## Portage behavior notes (2026)

- Since **2026-05-03** (news item, rev 3): remote binpkgs are **signature-
  verified by default** and fetched packages are cached in
  `/var/cache/binhost/NAME` (per `location=` in `binrepos.conf`).
  Unsigned custom binhosts (nexus) must set `verify-signature = false`.
- **Portage 3.0.74+** (Feb 2026): per-repo `usepkg-include` / `usepkg-exclude`
  in `repos.conf`; `verify-signature` per binrepo. Current tree ships
  portage-3.0.81.x.
- `--getbinpkgonly` (`-G`) / `--usepkgonly` (`-K`): never compile; fail instead
  (nexus CLI's strict mode). `--binpkg-respect-use=n` force-installs mismatched
  binaries (dangerous; not recommended).
- 2026-01-15 news: desktop profiles enable `pipewire pulseaudio screencast`
  globally + `media-video/pipewire[sound-server]`. Any consumer on a
  pre-2026 desktop profile (or with `USE="-pipewire …"`) loses pipewire bins.
- Still no per-package "prefer binary" toggle (bug 463964/924772); the
  `packages.binpkgs` enhancement (bug 969628) is open.

## Verification commands

```bash
# does my CPU support x86-64-v3?
/usr/lib/ld.so --help | grep -A1 "Subdirectories of glibc-hwcaps"

# what does the official host actually ship (USE per package)?
curl -s https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/Packages \
  | grep -A30 '^CPV: media-libs/mesa' | grep '^USE:'

# deep check: all builds of a package + which CPU flags exist anywhere in the tree
curl -s https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/Packages \
  -o /tmp/v3-Packages
grep '^USE:' /tmp/v3-Packages | grep -o 'cpu_flags_x86_[a-z0-9_]*' | sort | uniq -c
python3 - <<'EOF'
import re
blocks, cur = {}, None
for line in open('/tmp/v3-Packages'):
    m = re.match(r'^(CPV|USE): (.*)$', line.rstrip('\r\n'))
    if not m: continue
    k, v = m.group(1), m.group(2)
    if k == 'CPV': cur = re.sub(r'-\d.*$', '', v); blocks.setdefault(cur, []); continue
    if cur: blocks[cur].append(v)
for p in ('llvm-core/llvm','media-libs/mesa','media-video/pipewire'):
    print(p, len(blocks.get(p, [])), 'builds:', ' | '.join(blocks.get(p, [])[:3]))
EOF

# is package X on the official host at all? (kernel/ROCm/OpenCL checks)
grep '^CPV: ' /tmp/v3-Packages | grep -iE 'gentoo-kernel|rocr|rocm|hip|opencl-clang' | sort -u

# why is a package rebuilding instead of using a binary?
emerge --pretend --verbose --getbinpkg --usepkgonly --binpkg-respect-use=n <pkg>
# diff that USE against your config; every extra flag in the binpkg = rebuild.

# consumer sanity check
emerge --info | grep -E 'FEATURES|CPU_FLAGS|CFLAGS|PROFILE'
eselect profile list | grep -E '23.0'
```

## Rules for agents working here

- **Never add `bmi`/`avx512`/`aes`/etc. to `CPU_FLAGS_X86`** in machine config
  or workflows — it silently destroys binpkg compatibility with the official
  host (the only place this is OK is the temporary `CPU_FLAGS_X86_v3`
  definition in the upstream builders' make.conf, which is unused in practice).
- Keep `machine/` and `.github/workflows/*.yml` flags identical (they are
  duplicated on purpose; both comment that fact).
- Keep global USE at profile defaults in consumer configs; put deltas in
  `package.use` and ensure a nexus build covers each delta.
- `setup/quickstart.sh` must generate the same shape: `desktop/gnome` profile,
  **no global `USE=` line**, `VIDEO_CARDS` reset in `package.use`, and no
  `--usepkg-exclude` for packages the official host ships (pipewire, elogind,
  wireplumber, …). Its make.conf diverges from `machine/` only in
  `-march=${CPU_ARCH}` — allowed, because CFLAGS is not a binpkg key.
- The steam block in `setup/quickstart.sh` and the GAMING heredoc in BOTH
  workflows must stay in sync (quickstart = GAMING + the known exclusions).
  When the Steam wiki list changes, update all three + `TRACKED_PKGS` +
  default `package_list` in the same commit.
- Never add a flag to the nexus builder that the consumer config doesn't
  enable (mesa `lm-sensors`, libdrm `video_cards_intel` were exactly this bug
  — fixed 2026-08-17). The `-* amdgpu radeonsi` VIDEO_CARDS reset applies to
  EVERY package: the builder must not re-add intel/nouveau anywhere.
- When adding a new ebuild to the overlay, verify its USE stays
  profile-default (or is explicitly covered by the nexus builder) or consumers
  get source builds.
- When a consumer wants a package the official host ships (mesa, llvm, rust,
  zed, …), prefer matching the official USE exactly; only build it in nexus
  when the consumer's USE genuinely deviates (VIDEO_CARDS reset, 32-bit,
  codecs) or the official host lacks it entirely (ROCm, kernels).
- When the official binhost changes (new profile, python target bump, USE
  shifts), the tree will drift: re-verify with the curl command above and
  update this file's "verified" date.

## Autonomous-brain prompt logic (opencode-schedule.yml / opencode.yml, 2026-08-17)

The scheduled brain-agent prompt (in `opencode-schedule.yml` PROMPT env, and
the lighter on-demand version in `opencode.yml`) encodes this repo's
verification doctrine. Keep these sections in sync when the repo changes:

- **GIT IDENTITY**: commits are authored ONLY by
  `opencode-agent[bot] <41898282+opencode-agent[bot]@users.noreply.github.com>`
  (set via git config + GIT_AUTHOR_*/GIT_COMMITTER_* env). Never any other
  name/email, never `--author`, never Co-Authored-By/Signed-off-by trailers
  (the opencode default `Co-Authored-By: opencode <noreply@opencode.ai>`
  misattributes commits to a real human account — real incident). Verify
  `git config --get user.name/email` before and `git log -1 --format='%an
  <%ae>'` + `grep -ci co-authored` after every commit; amend
  `--reset-author` + force-push-with-lease on violation.
- **Web search freshness**: "today is August 2026" — never trust stale
  results; verify upstream versions via tags/releases API, packages.gentoo.org
  and the ::gentoo tree; re-verify when a result looks old.
- **Issue/PR duty**: EVERY open issue gets a reply and a verdict (fixed /
  not-a-bug / user error / duplicate); user-error issues are closed
  completed/not-planned with an explanation. EVERY PR gets a review comment;
  merge (squash) only with build+install evidence, otherwise REQUEST CHANGES
  or CLOSE. Never merge on "it probably builds".
- **Failed builds = top priority**: dismissal FORBIDDEN — "transient /
  superseded / covered later" are not closures; only a NEWER succeeded build
  run of current sources with a matching rolling-release asset counts. Work
  one package to green before the next; revbump (-r1) fixes so consumers
  pick them up; prove fixes in a clean stage3 docker before pushing; verify
  the push→Build-Relay dispatch chain fired (new run appears after push).
- **Relay model**: `.opencode-relay.md` on main is the SINGLE completion
  record — the workflow's gate checks it contains this run's `run_id:
  $RUN_ID` + `status: complete` after the model exits; otherwise the run is
  FAILED and the next model retries. Never delete the file; handoffs set
  `status: unfinished` + trigger `gh workflow run opencode-schedule.yml -f
  relay=true` before the timeout.
- **Advanced web search**: actually run searches (site: queries on
  packages.gentoo.org / repology / GitHub releases, exact-quote error
  searches, dated "<topic> 2026" queries), cross-check 2-3 independent
  sources, never rely on memory.
- **Install-verification sweep**: every rolling-release binary must
  `emerge --getbinpkg --usepkgonly`-install in a CLEAN stage3 container and
  pass the NO-SOURCE-REBUILD consumer simulation (`emerge --pretend
  --verbose --getbinpkg` with quickstart config — NOT --usepkgonly, which
  bypasses USE matching). Kernel packages additionally verify installkernel
  `dracut` post-install hooks.
- **Failure RCA protocol**: on any failure — capture the exact failing log,
  classify (upstream-missing / packaging error / dependency break /
  environment / config mismatch), check upstream FIRST (::gentoo ebuild,
  packages.gentoo.org, curl -sI the SRC_URI) to decide ours-vs-upstream,
  fix PRIMARY cause before downstream symptoms, prove the hypothesis with a
  command before editing, re-run the exact failing command after the fix.
- **STEP E full-repo sweep**: one clean desktop-openrc docker mounts the
  overlay + the DOWNLOADED rolling-release binaries (never local rebuilds)
  and sweeps the whole repo: bash -n every ebuild, manifest hash check,
  `emerge --pretend` dep graphs, install + no-source-rebuild check for every
  release binary. Missing release asset = sweep FAIL.
- **PRE-COMPLETION GATE item 0**: final full-binary compatibility pass —
  every rolling-release asset (overlay + official-atom) must install as a
  binary with zero rejections before the run is declared done.

## Sources (last checked 2026-08-17)

- https://wiki.gentoo.org/wiki/Gentoo_Binary_Host_Quickstart (2026-08-12)
- https://wiki.gentoo.org/wiki/Gentoo_binhost/Available_packages_and_configurations (2026-08-12)
- https://wiki.gentoo.org/wiki/Binary_package_guide (2026-07-08)
- https://wiki.gentoo.org/wiki/CPU_FLAGS_* (no date; matches live index)
- https://gitweb.gentoo.org/proj/binhost.git/tree/builders/milou (openrc-23
  make.conf: LTOFLAGS, `USE="bindist cet native-extensions"`, gpkg/xz)
- https://www.gentoo.org/support/news-items/2026-05-03-portage-binpkg-changes.html
- https://www.gentoo.org/support/news-items/2026-01-15-desktop-profile-pipewire.html
- https://www.gentoo.org/news/2024/02/04/x86-64-v3.html
- Live index: `distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/Packages` (15,576 pkgs, portage-3.0.81.2)