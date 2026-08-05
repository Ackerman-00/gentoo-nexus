# AUTONOMOUS_STATE.md

## Status: BLOCKED — GITHUB_TOKEN has no write permissions

The GITHUB_TOKEN returned by `gh api repos/Ackerman-00/gentoo-nexus --jq '.permissions'` shows
`{"admin":false,"maintain":false,"pull":false,"push":false,"triage":false}`.
This prevents pushing fixes, creating PRs, or deleting branches via git.

**Required fix (repo owner):** Go to Settings > Actions > General > Workflow permissions
and select "Read and write permissions" (or add `contents: write` at the repo level).

## Verified This Run

### Overlay Metadata
- `metadata/layout.conf`: OK (masters=gentoo, thin-manifests, BLAKE2B SHA512)
- `profiles/repo_name`: OK (= "gentoo-nexus")
- `profiles/categories`: OK (10 categories match actual dirs)
- `machine/make.conf`, `machine/binrepos.conf`, `machine/package.use`: OK

### Ebuild Validation (18/18)
All pass `bash -n`, all have required vars (EAPI, DESCRIPTION, HOMEPAGE, SRC_URI/EGIT, LICENSE, SLOT, KEYWORDS, DEPS).

### Version Verification (18/18 upstream match)
| Package | Ebuild | Upstream Latest | Status |
|---------|--------|----------------|--------|
| gui-libs/scenefx | 0.5 | 0.5 | up-to-date |
| app-office/obsidian | 1.13.4 | v1.13.4 | up-to-date |
| app-misc/nwg-look | 1.1.1 | v1.1.1 | up-to-date |
| app-misc/rootapp-bin | 0.9.125 | 0.9.125 (fedora-nexus) | up-to-date |
| app-misc/brightnessctl | 0.5.1 | 0.5.1 | up-to-date |
| app-misc/cliphist | 0.7.0 | v0.7.0 | up-to-date |
| dev-python/icoextract | 0.3.0 | 0.3.0 | up-to-date |
| net-im/vesktop | 1.6.5 | v1.6.5 | up-to-date |
| gui-wm/niri | 9999 | HEAD feb3e43f1475 | up-to-date |
| gui-wm/noctalia-v5 | 9999 | HEAD e41c99439605 | up-to-date |
| gui-wm/mangowm | 0.15.6 | 0.15.6 | up-to-date |
| x11-misc/matugen | 4.1.0 | v4.1.0 | up-to-date |
| x11-misc/xcur2png | 0.7.1-r3 | 0.7.1 | up-to-date |
| x11-base/xwayland-satellite | 9999 | HEAD 8d135d3b2854 | up-to-date |
| www-client/brave-origin-bin | 1.93.129 | v1.93.129 | up-to-date |
| games-util/faugus-launcher | 2.0.5 | 2.0.5 | up-to-date |
| www-client/zen-browser | 1.21.10b | 1.21.10b | up-to-date |
| games-util/protonplus | 0.5.22 | v0.5.22 | up-to-date |

### Rolling Release (all 18 overlay packages have binaries)
All .gpkg.tar files present in the rolling release. Packages index exists.

### Live EGIT_COMMIT Pins (3/3 match upstream HEAD)
- niri: feb3e43f1475 ✓
- noctalia-v5: e41c99439605 ✓
- xwayland-satellite: 8d135d3b2854 ✓

### Install Test Sweep (15/15 non-live packages)
All install successfully via `emerge --usepkgonly --getbinpkg` in clean `gentoo/stage3:amd64-openrc` container:
cliphist, brightnessctl, matugen, xcur2png, scenefx, mangowm, protonplus, icoextract,
nwg-look, rootapp-bin, obsidian, vesktop, brave-origin-bin, zen-browser, faugus-launcher.

### BinpkgFetcher Python 3.14 Bug
Portage on the latest stage3 has a Python 3.14 compatibility bug in `BinpkgFetcher._main`
(`AttributeError: 'str' object has no attribute 'fileno'`). This affects `--getbinpkg` downloads
for larger packages. Workaround: use `--usepkgonly` with a local binhost, or update portage.
This is an upstream Portage issue, not an overlay bug.

## Pending Fixes (committed locally, cannot push)

Commit `478bcea` on branch `opencode/schedule-42f146-20260805034350`:
1. **gui-wm/noctalia-v5/noctalia-v5-9999.ebuild**: Added missing copyright header
2. **x11-base/xwayland-satellite/xwayland-satellite-9999.ebuild**: Added missing copyright header
3. **.github/workflows/opencode-schedule.yml**: Fixed cleanup job — use `gh api` for branch deletion instead of `git push` (which fails when GITHUB_TOKEN expires during long runs)

## Open Issues
- #2 (just created): GITHUB_TOKEN has no write permissions — repo owner needs to enable write access

## Next Run Actions
1. After repo owner fixes GITHUB_TOKEN permissions, push commit `478bcea` to main
2. Trigger Build Relay for the updated ebuilds
3. Continue install-test coverage for official-atom packages (mesa, kernel, llvm, gcc, etc.)
