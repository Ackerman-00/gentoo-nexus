# Autonomous Run State

Last fully-verified run: **2026-08-02** (opencode dispatch; Build Relay #30760011122).

## Goal
Keep the gentoo-nexus overlay + rolling binhost working: ebuilds correct, live
packages pinned to current commits, and the rolling `Packages` index an exact,
dangling-free mirror of the published assets.

## Status: HEALTHY
- Rolling index: 505 entries, **0 dangling** (no entry references a missing asset),
  **0 genuinely missing** (every non-acct release `.gpkg.tar` is indexed; the 3
  acct-group/acct-user packages `cuse`, `plugdev`, `seat` are intentionally
  filtered from the served index by the upload step).
- `Packages` and `Packages.gz` are identical; both uploaded by the Build Relay.
- Key packages indexed: mesa 26.1.5, llvm 22.1.8, gcc 16.1.1_p20260718,
  gentoo-kernel 7.1.5, portage 3.0.81.2-6, perl 5.44.0, dav1d 1.5.1 (both -1/-2).
- `commits.json` (live 9999 packages): `gui-wm/noctalia-v5`=f0ac340a58f0,
  `x11-base/xwayland-satellite`=8d135d3b2854, `gui-wm/niri`=7f26c3ee804f.

## Recurring gotchas (read before touching the build)
1. **Noctalia deps**: `gui-wm/noctalia-v5-9999.ebuild` needs
   `dev-cpp/nlohmann_json` (underscore!), `dev-libs/stb` (for
   `stb/stb_image_resize2.h` + `stb_image_write.h`), plus libsodium, libsecret,
   libjxl, libsndfile, libical. Missing any -> meson configure fails.
2. **md5-cache**: regenerate with `egencache --update --repo gentoo-nexus` in a
   container with the overlay at `/var/db/repos/gentoo-nexus` and a
   `/etc/portage/repos.conf/gentoo-nexus.conf` (masters=gentoo). The first
   container run can silently no-op; rerun if the cache file mtime did not change.
3. **Perl self-heal** (build.yml): detects installed vs `best_visible` perl slot,
   emerges the new perl, `perl-cleaner --all`, then `emaint binhost --fix`. This
   runs after `.build_start` so the rebuilt perl stack is uploaded too.
4. **Reconcile contract**: the index must match the release *after* upload. Newly
   built files (mtime > `.build_start`) are always indexed; restored assets are
   indexed only if still present in the release and no new build of the same
   package name replaces them (the upload deletes `${PN}-[0-9]*.gpkg.tar` old
   assets). Do NOT dedup by CPV — the release intentionally retains multiple
   build-ids per CPV (e.g. `dav1d-1.5.1-1` and `dav1d-1.5.1-2`) as separate assets.
5. **Git push**: must use the OpenCode App token via OIDC exchange
   (see `.git/config` extraheader). Renew by POSTing an OIDC token
   (audience `opencode-github-action`) to `https://api.opencode.ai/exchange_github_app_token`.
   Node's TLS fingerprint passes Cloudflare; Python's urllib gets HTTP 403/1010.

## Package build proofs (last verified)
- `gui-wm/noctalia-v5-9999` builds from source at f0ac340a; binary uploaded as
  `noctalia-v5-9999-1.gpkg.tar` (17MB, valid stripped x86-64 ELF).
- `x11-misc/xcur2png-0.7.1-r3` builds (SRC_URI fixed to the no-`-r3` upstream tag).
- stage3 container proof earlier: brightnessctl 0.5.1, cliphist 0.7.0, niri 9999
  compiled from source; binaries produced.
- perl 5.44.0 + rebuilt perl modules uploaded to rolling by the self-heal.

## Known acceptable state
- `spirv-tools` lacks abi_x86_32 binaries; no overlay target pulls it as a dep,
  so source fallback is acceptable.
- ccache binary is present and used; not a blocker.
