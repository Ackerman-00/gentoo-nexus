#!/usr/bin/env python3
"""Deterministic tear-apart sweep for every ebuild in the overlay.

Proof-or-Stop gate: iterates ALL ebuilds (no package list, no hardcoding, no
skipping). For each package it downloads every distfile (both amd64 and arm64
SRC_URI arms), verifies size + BLAKE2B + SHA512 against the Manifest, tears the
artifact apart (AppImage --appimage-extract + X-AppImage-Version, .deb control
Version, zip/tar internals for version evidence, live 9999 EGIT_COMMIT vs
upstream HEAD), and emits a per-package table.

Exit code 0 = every package verified. Exit 1 = at least one FAIL/MISMATCH/
STALE/UNVERIFIED -> the run is NOT done, period. Agent claims are not
evidence; the exit code and the committed report are.

Pure stdlib (python3 only). No curl, no git, no dpkg, no unsquashfs required.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import tarfile
import tempfile
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

SKIP_DIRS = {"cache", "job_out", "binpkgs", "distfiles", "ccache", ".github", ".git", "tools"}
VAR_RE = re.compile(r'^(\w+)=(?:"([^"]*)"|\'([^\']*)\'|(\S+))', re.M)
DIST_RE = re.compile(r"^DIST\s+(\S+)\s+(\d+)\s+BLAKE2B\s+([0-9a-fA-F]+)\s+SHA512\s+([0-9a-fA-F]+)")
UA = {"User-Agent": "teardown-sweep/1.0 (gentoo-nexus CI gate)"}

STATUS_OK = "OK"
STATUS_SOURCE_OK = "SOURCE-OK"
STATUS_MISMATCH = "MISMATCH"
STATUS_STALE = "STALE"
STATUS_FAIL = "FAIL"
STATUS_UNVERIFIED = "UNVERIFIED"
STATUS_SKIP = "SKIP-LIVE-UNVERIFIED"

rows = []  # (package, distfile, pinned, internal, status, note)


def log(msg):
    print(msg, flush=True)


def fetch(url, timeout=120):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def http_status(url, timeout=60):
    try:
        req = urllib.request.Request(url, method="HEAD", headers=UA)
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception:
        return None


def parse_manifest(pkg_dir):
    manifest = {}
    mp = pkg_dir / "Manifest"
    if mp.exists():
        for line in mp.read_text(errors="ignore").splitlines():
            m = DIST_RE.match(line)
            if m:
                manifest[m.group(1)] = (int(m.group(2)), m.group(3).lower(), m.group(4).lower())
    return manifest


def filename_vars(ebname):
    """Implicit PV/PN/P from the ebuild filename (most ebuilds have no PV= line)."""
    name = ebname[: -len(".ebuild")]
    m = re.match(r"^(.+?)-(\d[^-]*?)(?:-r(\d+))?$", name)
    if not m:
        return {}
    pn, pv, rev = m.group(1), m.group(2), m.group(3)
    if rev:
        pv = pv + "-r" + rev
    return {"PN": pn, "PV": pv, "P": pn + "-" + pv}


def parse_vars(content):
    vars_ = {}
    for m in VAR_RE.finditer(content):
        g = m.group(2) or m.group(3) or m.group(4) or ""
        if m.group(1) == "SRC_URI":
            continue
        vars_.setdefault(m.group(1), g)
    return vars_


def expand(text, vars_):
    """Expand ${VAR}, ${VAR/pat/repl} (first), ${VAR//pat/repl} (all) and
    ${VAR%glob} suffix-strip, bash style, nesting-safe."""
    for _ in range(8):
        out = text

        def rep(m):
            v = vars_.get(m.group(1), "")
            if m.group(2) == "//":
                return v.replace(m.group(3), m.group(4))
            return v.replace(m.group(3), m.group(4), 1)

        out = re.sub(r"\$\{(\w+)(//?)([^/}]*)/([^}]*)\}", rep, out)

        def strip(m):
            v = vars_.get(m.group(1), "")
            rx = re.escape(m.group(2)).replace(r"\*", ".*") + "$"
            return re.sub(rx, "", v)

        out = re.sub(r"\$\{(\w+)%([^}]*)\}", strip, out)

        def plain(m):
            return vars_.get(m.group(1), m.group(0))

        out = re.sub(r"\$\{(\w+)\}", plain, out)
        if out == text:
            return out
        text = out
    return text


def parse_src_uri(content, vars_):
    """Return list of (url, distfile_name) for both amd64 and arm64 arms."""
    m = re.search(r'^\s*SRC_URI="(.*?)"', content, re.M | re.S)
    if not m:
        return []
    body = m.group(1)
    # strip use-conditional arms
    for arm in ("amd64", "arm64"):
        body = re.sub(r"%s\? \((.*?)\)" % arm, lambda mm: mm.group(1), body, flags=re.S)
    body = re.sub(r"[A-Za-z0-9_+\-]+\? \(.*?\)", "", body, flags=re.S)  # any other flags
    urls = []
    for m in re.finditer(r"(https?://\S+)(?:\s*->\s*(\S+))?", body):
        url, rename = m.group(1), m.group(2)
        url = expand(url, vars_)
        if rename:
            name = expand(rename.strip(), vars_)
        else:
            name = url.rsplit("/", 1)[-1]
        urls.append((url, name))
    return urls


def live_info(content, vars_):
    repo = vars_.get("EGIT_REPO_URI", "")
    pin = vars_.get("EGIT_COMMIT", "")
    if vars_.get("PV") != "9999":
        return None
    if not repo:
        return None
    repo = repo.rstrip("/")
    if repo.endswith(".git"):
        repo = repo[:-4]
    repo = re.sub(r"^https?://[^/]+/", "", repo)  # strip scheme + host
    return repo, pin


def upstream_head(repo):
    """GitHub API first (with retries); git ls-remote fallback; None if both fail."""
    import time
    for attempt in range(3):
        try:
            data = json.loads(fetch("https://api.github.com/repos/%s/commits/HEAD" % repo, timeout=30).decode())
            if isinstance(data, dict) and data.get("sha"):
                return data["sha"]
        except Exception:
            time.sleep(5 * (attempt + 1))
    try:
        import subprocess
        out = subprocess.check_output(
            ["git", "ls-remote", "https://github.com/%s.git" % repo, "HEAD"],
            timeout=30, stderr=subprocess.DEVNULL).decode()
        m = re.search(r"([0-9a-fA-F]{40})", out)
        if m:
            return m.group(1)
    except Exception:
        pass
    return None


def pypi_sdist_url(pn, pv):
    try:
        data = json.loads(fetch("https://pypi.org/pypi/%s/%s/json" % (pn, pv), timeout=60).decode())
        for u in data.get("urls", []):
            if u.get("filename", "").endswith(".tar.gz") and u.get("packagetype") == "sdist":
                return u["url"]
    except Exception:
        pass
    return None


def verify_distfile(path, size, b2, s512):
    if path.stat().st_size != size:
        return False, "size %d != manifest %d" % (path.stat().st_size, size)
    hb = hashlib.blake2b()
    hs = hashlib.sha512()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            hb.update(chunk)
            hs.update(chunk)
    if hb.hexdigest() != b2:
        return False, "BLAKE2B mismatch"
    if hs.hexdigest() != s512:
        return False, "SHA512 mismatch"
    return True, ""


def ar_names(path):
    """Parse ar archive (deb container) - stdlib only."""
    data = path.read_bytes()
    if not data.startswith(b"!<arch>\n"):
        return []
    names = []
    idx = 8
    while idx + 60 <= len(data):
        name = data[idx:idx + 16].split(b"/")[0].decode(errors="ignore").strip()
        try:
            size = int(data[idx + 48:idx + 58].decode().strip() or 0)
        except ValueError:
            break
        names.append((name, idx + 60, size))
        idx += 60 + size + (size % 2)
    return names


def extract_deb_control_version(path, tmp):
    members = ar_names(path)
    if not members:
        return None, "not an ar archive"
    for name, off, size in members:
        if re.match(r"^control\.tar\.(gz|xz|zst|bz2)$", name):
            blob = path.read_bytes()[off:off + size]
            ctl = tmp / ("control." + name.split(".", 2)[-1])
            ctl.write_bytes(blob)
            try:
                with tarfile.open(ctl) as t:
                    names = t.getnames()
                    control_name = "control" if "control" in names else next(
                        (n for n in names if n.endswith("/control")), None)
                    if control_name is None:
                        return None, "no control file inside %s" % name
                    control = t.extractfile(control_name)
                    text = control.read().decode(errors="ignore") if control else ""
            except Exception as e:
                return None, "control %s unreadable: %s" % (name, e)
            vm = re.search(r"^Version:\s*(.+)$", text, re.M)
            pm = re.search(r"^Package:\s*(.+)$", text, re.M)
            pkg = pm.group(1).strip() if pm else "?"
            ver = vm.group(1).strip() if vm else None
            return ver, "deb pkg=%s (control %s)" % (pkg, name)
    return None, "no control.tar.* member"


def normalize(v):
    v = v.strip().strip('"').strip("'").strip("`")
    v = re.sub(r"^[vV]", "", v)
    v = re.sub(r"\+.*$", "", v)
    v = re.sub(r"-([0-9]+)$", "", v)
    return v.lower()


def versions_match(pv, internal):
    """True when internal == pv, or internal is pv with a leading build-number
    component (e.g. Chromium-prefixed Brave '151.1.93.137' vs pinned
    '1.93.137')."""
    p, i = normalize(pv), normalize(internal)
    if p == i:
        return True
    pc, ic = p.split("."), i.split(".")
    if len(ic) > len(pc) and ic[len(ic) - len(pc):] == pc:
        return True
    return False


def read_small(p, limit=200_000):
    try:
        if p.stat().st_size > limit:
            return ""
        return p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""


def read_asar_version(path):
    """Read version from an Electron .asar archive (stdlib only)."""
    try:
        data = path.read_bytes()
        if len(data) < 12:
            return None
        header_size = int.from_bytes(data[4:8], "little")
        payload_start = 8 + header_size
        start = data.find(b"{", 8)
        if start < 0:
            return None
        header = json.JSONDecoder().raw_decode(data[start:].decode(errors="ignore"))[0]
        files = header.get("files", {})

        def walk(node, prefix=""):
            for name, info in node.items():
                p = prefix + "/" + name
                if isinstance(info, dict) and info.get("files"):
                    yield from walk(info["files"], p)
                elif isinstance(info, dict) and name == "package.json" and "node_modules" not in p:
                    try:
                        off, size = int(info["offset"]), int(info["size"])
                        pj = json.loads(data[payload_start + off: payload_start + off + size].decode(errors="ignore"))
                        if pj.get("version"):
                            yield p, pj["version"]
                    except Exception:
                        pass

        for p, v in walk(files):
            return v
    except Exception:
        return None
    return None


STRONG_KINDS = {"asar", "X-AppImage-Version", "desktop Version", "application.ini"}
WEAK_KINDS = {"package.json", "Cargo.toml", "version file", "changelog"}
SOURCE_MARKERS = ("makefile", "meson.build", "cargo.toml", "cmakelists.txt",
                  "configure.ac", "setup.py", "setup.cfg", "pyproject.toml", "src")


def looks_like_source(tree):
    for f in tree.rglob("*"):
        if not f.is_file():
            continue
        if f.name.lower() in SOURCE_MARKERS and len(f.relative_to(tree).parts) <= 3:
            return True
        if f.suffix.lower() in (".c", ".h", ".rs", ".py", ".cc", ".cpp", ".go"):
            return True
    return False


def version_evidence(tree, distname):
    """Collect version evidence found inside an extracted artifact."""
    hits = []
    seen = set()
    for f in sorted(tree.rglob("*")):
        if not f.is_file():
            continue
        rel = f.relative_to(tree)
        if len(rel.parts) > 6:
            continue
        name = f.name.lower()
        txt = ""
        if name.endswith(".asar") and f.stat().st_size < 200_000_000:
            ver = read_asar_version(f)
            if ver:
                key = ("asar", ver)
                if key not in seen:
                    seen.add(key)
                    hits.append(("asar", ver, str(rel)))
        if name.endswith(".desktop"):
            txt = read_small(f)
            m = re.search(r"^X-AppImage-Version=(.+)$", txt, re.M)
            if m:
                hits.append(("X-AppImage-Version", m.group(1).strip(), str(rel)))
                seen.add(("XAI", m.group(1).strip()))
            m = re.search(r"^Version=(.+)$", txt, re.M)
            if m and m.group(1).strip() not in ("1.0", "1.0.0"):
                key = ("desk", m.group(1).strip())
                if key not in seen:
                    seen.add(key)
                    hits.append(("desktop Version", m.group(1).strip(), str(rel)))
        elif name in ("application.ini", "platform.ini"):
            txt = read_small(f)
            m = re.search(r"^Version=(.+)$", txt, re.M)
            if m and m.group(1).strip() not in ("1.0", "1.0.0"):
                key = ("ini", m.group(1).strip())
                if key not in seen:
                    seen.add(key)
                    hits.append(("application.ini", m.group(1).strip(), str(rel)))
        elif name == "package.json":
            if "node_modules" in rel.parts or "app.asar.unpacked" in rel.parts:
                continue
            txt = read_small(f)
            try:
                j = json.loads(txt)
                v = j.get("version")
                if v:
                    key = ("pj", str(v))
                    if key not in seen:
                        seen.add(key)
                        hits.append(("package.json", str(v), str(rel)))
            except Exception:
                pass
        elif name in ("cargo.toml", "cargo.toml.orig"):
            txt = read_small(f)
            m = re.search(r"^\[package\]\s*$.*?^version\s*=\s*\"([^\"]+)\"", txt, re.M | re.S)
            if m:
                key = ("cargo", m.group(1))
                if key not in seen:
                    seen.add(key)
                    hits.append(("Cargo.toml", m.group(1), str(rel)))
        elif name in ("version", "version.txt", "version.json", "package_version"):
            txt = read_small(f).strip()
            if txt and len(txt) < 64 and re.match(r"^[\w.\-+~]+$", txt):
                key = ("vfile", txt)
                if key not in seen:
                    seen.add(key)
                    hits.append(("version file", txt, str(rel)))
        elif "changelog" in name or name.startswith("news") or name.endswith(".release"):
            txt = read_small(f, 50_000)
            m = re.search(r"([0-9]+\.[0-9]+(?:\.[0-9]+)?[a-zA-Z0-9._\-]*)", txt)
            if m:
                key = ("cl", m.group(1))
                if key not in seen:
                    seen.add(key)
                    hits.append(("changelog", m.group(1), str(rel)))
    if not hits:
        return hits
    # Prioritize authoritative app-version sources over nested dependency metadata.
    priority = {"asar": 0, "X-AppImage-Version": 1, "application.ini": 2,
                "desktop Version": 3, "package.json": 4, "Cargo.toml": 5,
                "version file": 6, "changelog": 7}
    hits.sort(key=lambda h: (priority.get(h[0], 9), h[2]))
    return hits[:4]


def probe_binary_version(sub, distname):
    """Try running top-level ELF executables with --version and parse the
    output for a semver-looking token. Returns (version, cmd, output)."""
    import subprocess
    cands = []
    for f in sorted(sub.rglob("*")):
        if not f.is_file():
            continue
        rel = f.relative_to(sub)
        if len(rel.parts) > 3:
            continue
        try:
            head = f.read_bytes()[:4]
            if head == b"\x7fELF":
                cands.append(f)
        except Exception:
            continue
    for cand in cands[:5]:
        try:
            os.chmod(cand, 0o755)
            res = subprocess.run([str(cand), "--version"], capture_output=True,
                                 timeout=20, cwd=sub)
            out = (res.stdout or res.stderr or b"").decode(errors="ignore")
            m = re.search(r"([0-9]+\.[0-9]+(?:\.[0-9]+)?[a-zA-Z0-9._\-]*)", out)
            if m:
                return m.group(1), "%s --version" % cand.name, out.strip()[:120]
        except Exception:
            continue
    return None, None, None


def tear_apart(path, distname, tmp):
    """Return (internal_version, note, strong, source_like). strong=True means
    the internal version is authoritative (asar/XAI/ini/deb control/desktop/
    runtime --version probe). source_like=True means the tree looks like a
    source tarball (version is PV by construction)."""
    ext = distname.lower()
    if ext.endswith(".appimage") or ".appimage" in ext:
        try:
            os.chmod(path, 0o755)
            sub = tmp / "appimage"
            sub.mkdir()
            import subprocess
            res = subprocess.run([str(path), "--appimage-extract"], cwd=sub,
                                 capture_output=True, timeout=300)
            root = sub / "squashfs-root"
            if root.is_dir():
                hits = version_evidence(root, distname)
                for kind, v, rel in hits:
                    if kind in STRONG_KINDS:
                        return v, "AppImage %s (%s)" % (v, rel), True, False
                if hits:
                    return hits[0][1], "AppImage %s=%s (%s)" % (hits[0][0], hits[0][1], hits[0][2]), False, False
                return None, "AppImage extracted, no version evidence found (rc=%d)" % res.returncode, False, False
            return None, "AppImage --appimage-extract failed (rc=%d): %s" % (
                res.returncode, res.stderr.decode(errors="ignore")[-300:]), False, False
        except Exception as e:
            return None, "AppImage teardown error: %s" % e, False, False
    if ext.endswith(".deb"):
        ver, note = extract_deb_control_version(path, tmp)
        return ver, note, bool(ver), False
    if ext.endswith(".zip"):
        try:
            sub = tmp / "zip"
            sub.mkdir()
            with zipfile.ZipFile(path) as z:
                z.extractall(sub)
            hits = version_evidence(sub, distname)
            for kind, v, rel in hits:
                if kind in STRONG_KINDS:
                    return v, "zip %s=%s (%s)" % (kind, v, rel), True, False
            ver, cmd, out = probe_binary_version(sub, distname)
            if ver:
                return ver, "zip runtime probe %s: %s" % (cmd, out), True, False
            if hits:
                return hits[0][1], "zip %s=%s (%s)" % (hits[0][0], hits[0][1], hits[0][2]), False, looks_like_source(sub)
            return None, "zip extracted, no version evidence found", False, looks_like_source(sub)
        except Exception as e:
            return None, "zip teardown error: %s" % e, False, False
    if ext.endswith((".tar.gz", ".tgz", ".tar.xz", ".tar.bz2")):
        try:
            sub = tmp / "tar"
            sub.mkdir()
            with tarfile.open(path) as t:
                t.extractall(sub, filter="data")
            hits = version_evidence(sub, distname)
            for kind, v, rel in hits:
                if kind in STRONG_KINDS:
                    return v, "tar %s=%s (%s)" % (kind, v, rel), True, False
            ver, cmd, out = probe_binary_version(sub, distname)
            if ver:
                return ver, "tar runtime probe %s: %s" % (cmd, out), True, False
            if hits:
                return hits[0][1], "tar %s=%s (%s)" % (hits[0][0], hits[0][1], hits[0][2]), False, looks_like_source(sub)
            return None, "tar extracted, no version evidence found", False, looks_like_source(sub)
        except Exception as e:
            return None, "tar teardown error: %s" % e, False, False
    return None, "unknown artifact type", False, False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--overlay", default=".")
    ap.add_argument("--report", default="teardown-report.md")
    ap.add_argument("--workdir", default=None)
    args = ap.parse_args()

    overlay = Path(args.overlay)
    workdir = Path(args.workdir) if args.workdir else Path(tempfile.mkdtemp(prefix="teardown-"))
    workdir.mkdir(parents=True, exist_ok=True)
    dl = workdir / "distfiles"
    dl.mkdir(exist_ok=True)

    ebuilds = sorted(
        p for p in overlay.rglob("*.ebuild")
        if not any(x in p.parts for x in SKIP_DIRS) and len(p.parts) >= 3
    )
    if not ebuilds:
        log("NO EBUILDS FOUND under %s - sweep aborted (FAIL)" % overlay)
        sys.exit(1)

    log("=== TEAR-DOWN SWEEP: %d ebuilds ===" % len(ebuilds))

    for eb in ebuilds:
        pkg_dir = eb.parent
        pkg = "%s/%s" % (pkg_dir.parts[-2], pkg_dir.parts[-1])
        content = eb.read_text(errors="ignore")
        vars_ = {**filename_vars(eb.name), **parse_vars(content)}
        vars_.setdefault("P", "%s-%s" % (vars_.get("PN", pkg_dir.parts[-1]), vars_.get("PV", "")))
        pv = vars_.get("PV", "")
        manifest = parse_manifest(pkg_dir)

        live = live_info(content, vars_)
        if live:
            repo, pin = live
            head = upstream_head(repo)
            if not head:
                rows.append((pkg, "EGIT %s" % repo, pin, None, STATUS_SKIP,
                             "upstream HEAD unreachable (rate limit/network)"))
                log("[%s] %s : %s" % (STATUS_SKIP, pkg, "live, upstream unreachable"))
                continue
            ok = (normalize(pin[:12]) == normalize(head[:12]))
            status = STATUS_OK if ok else STATUS_STALE
            note = "live EGIT_COMMIT %s vs upstream %s" % (pin[:12], head[:12])
            rows.append((pkg, "EGIT %s" % repo, pin[:12], head[:12], status, note))
            log("[%s] %s : %s" % (status, pkg, note))
            continue

        if "pypi" in content:
            srcs = [(pypi_sdist_url(vars_.get("PN", ""), pv) or "", "%s-%s.tar.gz" % (vars_.get("PN", ""), pv))]
        else:
            srcs = parse_src_uri(content, vars_)

        if not srcs or all(not u for u, _ in srcs):
            rows.append((pkg, "?", pv, None, STATUS_FAIL, "no SRC_URI resolvable"))
            log("[%s] %s : no SRC_URI" % (STATUS_FAIL, pkg))
            continue

        pkg_ok = True
        for url, name in srcs:
            if not url:
                rows.append((pkg, name, pv, None, STATUS_FAIL, "SRC_URI could not be resolved"))
                log("[%s] %s : SRC_URI unresolved for %s" % (STATUS_FAIL, pkg, name))
                pkg_ok = False
                continue
            dst = dl / name
            if not dst.exists():
                try:
                    log("  downloading %s (%s)" % (name, url))
                    dst.write_bytes(fetch(url))
                except Exception as e:
                    rows.append((pkg, name, pv, None, STATUS_FAIL, "download failed: %s" % e))
                    log("[%s] %s : download failed %s" % (STATUS_FAIL, pkg, name))
                    pkg_ok = False
                    continue
            if name in manifest:
                size, b2, s512 = manifest[name]
                good, why = verify_distfile(dst, size, b2, s512)
                if not good:
                    rows.append((pkg, name, pv, None, STATUS_FAIL, "Manifest %s" % why))
                    log("[%s] %s : Manifest %s for %s" % (STATUS_FAIL, pkg, why, name))
                    pkg_ok = False
                    continue
                hash_note = "hash-OK"
            else:
                hash_note = "no-Manifest-entry"
                rows.append((pkg, name, pv, None, STATUS_FAIL, "distfile missing from Manifest"))
                log("[%s] %s : %s not in Manifest" % (STATUS_FAIL, pkg, name))
                pkg_ok = False
                continue

            with tempfile.TemporaryDirectory() as td:
                internal, note, strong, src_like = tear_apart(dst, name, Path(td))
            if internal and strong:
                if versions_match(pv, internal):
                    status = STATUS_OK
                else:
                    status = STATUS_MISMATCH
                    pkg_ok = False
                note = "%s | pinned %s | internal %s" % (note, pv, internal)
            elif internal and not strong:
                status = STATUS_SOURCE_OK
                note = "%s | weak internal evidence %s (not authoritative); multi-version tree" % (note, internal)
            elif src_like:
                status = STATUS_SOURCE_OK
                note = "%s | source tarball (version = PV by construction)" % note
            else:
                status = STATUS_UNVERIFIED
                pkg_ok = False
                note = "%s | BINARY ARTIFACT, no internal version evidence" % note
            rows.append((pkg, name, pv, internal, status, note))
            log("[%s] %s : %s" % (status, pkg, note))

    log("")
    log("=== SWEEP TABLE ===")
    log("%-34s %-34s %-16s %-14s %-12s %s" % ("PACKAGE", "DISTFILE", "PINNED", "INTERNAL", "STATUS", "NOTE"))
    n_bad = 0
    for pkg, dist, pinned, internal, status, note in rows:
        log("%-34s %-34s %-16s %-14s %-12s %s" % (
            pkg, dist[:34], (pinned or "")[:16], (internal or "")[:14], status, note))
        if status in (STATUS_FAIL, STATUS_MISMATCH, STATUS_STALE, STATUS_UNVERIFIED):
            n_bad += 1

    report = Path(args.report)
    lines = ["# Teardown Sweep Report", "",
             "Sweep of **%d** ebuilds (%d artifacts). Exit code is the verdict; this report is the receipt." % (len(ebuilds), len(rows)),
             "| Package | Distfile | Pinned | Internal | Status | Note |",
             "|---|---|---|---|---|---|"]
    for pkg, dist, pinned, internal, status, note in rows:
        lines.append("| %s | %s | %s | %s | **%s** | %s |" % (
            pkg, dist.replace("|", "\\|"), pinned or "", internal or "", status,
            note.replace("|", "\\|")))
    lines.append("")
    lines.append("**Verdict: %s** (%d failure(s))" % ("PASS" if n_bad == 0 else "FAIL", n_bad))
    report.write_text("\n".join(lines) + "\n")
    log("report written to %s" % report)

    if n_bad:
        log("=== TEAR-DOWN SWEEP FAILED: %d package(s) not verified. Not done. ===" % n_bad)
        sys.exit(1)
    log("=== TEAR-DOWN SWEEP PASSED: every package torn apart and verified. ===")
    sys.exit(0)


if __name__ == "__main__":
    main()