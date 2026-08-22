# AGENTS.md — gentoo-nexus

Work-notes for AI agents and humans maintaining this repo.

## Self-healing sweep architecture (added 2026-08-21)

Three-layer defense-in-depth for package staleness and integrity:

### Layer 1: Deterministic Python sweep (`tools/teardown-sweep.py`) — AUXILIARY, NOT VERDICT

Pure stdlib helper the **agent calls** (not a separate CI gate). Downloads every
artifact, tears it apart (AppImage extract, .deb control, zip internals, Electron
.asar, `application.ini`, ELF `--version` probe), verifies checksums (sha256,
BLAKE2B+SHA512, SRI), reads internal versions vs upstream, and (2026-08) runs
`pkgcheck scan` hooks + `check_rpm_dependencies` for RPM deps.
The agent IS the teardown — it must tear every ebuild apart itself, run
`pkgcheck scan --net` + `pkgdev manifest` + `emerge --pretend`, produce the
dependency audit table, and ensure excellent EAPI 8 ebuilds. Sweep is evidence,
not a pass-anyway script; CI gate hard-fails if the agent skips it.

Key functions:
- `resolve_canonical_repo()`: detects GitHub forks via API `parent.full_name`,
  compares against canonical upstream (not the fork)
- `is_chromium_build_number()`: filters Chromium engine build numbers
  (first component >= 50) from version probes
- `is_template_version()`: auto-detects RPM macros (%{bumpver}, %{shortcommit0}),
  bash expansions, git snapshots — skips them automatically (no hardcoded lists)
- `versions_match()`: handles both prefix and suffix version alignment
  (e.g. Chromium `143.1.93.137` vs Brave `1.93.137`)
- `staleness_pv()`: strips +build, .git-hash, -r1, ^git, ~beta suffixes
- `repology_newest()`: queries Repology API (120+ repos) for ANY package
- `repology_dep_info()`: gets upstream version + status from Repology
- `osv_query()`: queries OSV.dev for known CVEs on ANY package
- `compute_libyear()`: computes libyear drift from GitHub release dates
- `fix_stale_pkg()`: mechanical auto-fix — sed version in ebuild/spec/nix/template
- `--autofix` flag: when STALE is detected, auto-fix and re-verify

Exit code = verdict. Exit 0 = all packages verified. Exit 1 = any
FAIL/MISMATCH/STALE/UNVERIFIED → CI opens an issue.

### Layer 1b: Docker battle test + dependency sweep (`tools/docker-sweep.py`) — MANDATORY

Runs INSIDE the agent, clean `gentoo/stage3:amd64-desktop-openrc` container every run:
1. Downloads EVERY .gpkg.tar from rolling release (overlay + official atoms) + Packages index
2. `emerge --getbinpkg --usepkgonly <atom>` + `equery check` + `ldd` + `<bin> --version` for each binary (at least 5 diverse per run, oldest-uncovered first)
3. Battle-tests `tools/nexus --help` / `list` and `setup/quickstart.sh` dry-run inside same container; if CLI/setup broken or README instructions don't reproduce, fix them and re-test
4. Verifies `emerge --pretend --getbinpkg` shows `[binary]` (no source rebuild) with consumer `quickstart.sh` config
5. Reports `| package | emerge --usepkgonly | ldd | --version | status |` — any fail = fix ebuild/Manifest/tool/README and re-run

Key features:
- `trivy_scan_image()`: scans base images for CRITICAL/HIGH/MEDIUM CVEs
- `--scan-images` flag: enables Trivy CVE scanning
- No manual `tar` fallback — docker battle test is mandatory

### Layer 2: Agentic self-healing prompt (opencode-schedule.yml PROMPT) — MANDATORY

YOU are the sweep. The PROMPT's TEAR-APART + DOCKER BATTLE TEST is NOT optional and NOT pass-anyway:
1. Tear every ebuild + Manifest apart itself (SRC_URI download → extract → Cargo.toml/meson.build vs RDEPEND), run 2026 toolchain: `pkgcheck scan --net` + `pkgcheck scan --commits` (EAPI 8), `pkgdev manifest`, `emerge --pretend`, `tc-getPKG_CONFIG` — log output
2. Produce mandatory `| package | upstream deps | in ebuild | missing | status |` for ALL 18 packages and think: if a dep is missing upstream, fix the ebuild; if CLI/setup would break for a new user, fix it — otherwise leave as is
3. Docker battle-test every binary + `tools/nexus` + `setup/quickstart.sh` as above; update repo instructions only if battle test proves they’re wrong

### Layer 3: CI gate + issue auto-open — ENFORCED

`gate_passes()` now hard-checks that `.opencode-relay.md` contains `run_id` + `status: complete` + `PACKAGE.*BR.*Req` / `deps-verified` / `dependency audit`.
If the agent skips the table, the job fails and retries with stronger model.

### Why this architecture

- **Deterministic + intelligent**: the sweep is pure Python (no LLM needed,
  no hallucination, fast). The agent handles complex cases that require
  reasoning about upstream changes.
- **Universal**: works for ANY package — Repology, OSV.dev, GitHub API,
  Trivy. No hardcoded skip lists or package-specific logic.
- **Self-healing**: genuinely stale packages get auto-fixed by the sweep's
  `--autofix` and/or the agent's investigation. False positives get caught
  and the sweep is improved.
- **Proof-or-Stop**: exit code = verdict. No claims without evidence.
  The sweep output is committed to the repo as a receipt.
- **Defense-in-depth**: even if one layer misses, the next catches it.
  Fork detection, template version detection, libyear budget, and
  Trivy CVE scanning prevent the known false positive classes.
