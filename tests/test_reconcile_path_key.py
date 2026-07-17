import os, tempfile, tarfile, io

def read_gpkg_metadata(fullpath):
    meta = {}
    try:
        with tarfile.open(fullpath) as tf:
            for m in tf.getmembers():
                if m.name.startswith('metadata/') and m.isfile():
                    val = tf.extractfile(m).read().decode().strip()
                    meta[m.name.split('/')[-1]] = val
    except Exception:
        pass
    return meta

def reconcile(pkgdir, packages_file):
    header = []
    entries = []
    if os.path.exists(packages_file):
        with open(packages_file) as f:
            text = f.read()
        blocks = text.split('\n\n')
        header = blocks[0].splitlines() if blocks else []
        for blk in blocks[1:]:
            d = {}
            for line in blk.splitlines():
                if ':' in line:
                    k, v = line.split(':', 1)
                    d[k.strip()] = v.strip()
            if 'CPV' in d:
                entries.append(d)

    indexed_paths = set()
    for d in entries:
        p = d.get('PATH', '')
        if p:
            indexed_paths.add(p.replace('\\', '/'))

    META_KEYS = ('BUILD_ID','BUILD_TIME','USE','CHOST','CBUILD','CFLAGS','CXXFLAGS',
                 'LDFLAGS','FEATURES','LICENSE','KEYWORDS','REQUIRED_USE','PROPERTIES',
                 'RESTRICT','DEFINED_PHASES','IUSE','SLOT','EAPI','REPO_REVISIONS',
                 'SIZE','MD5','SHA1','SHA512')

    added = 0
    for root, _dirs, files in os.walk(pkgdir):
        for f in files:
            if not f.endswith('.gpkg.tar'):
                continue
            fullpath = os.path.join(root, f)
            relpath = os.path.relpath(fullpath, pkgdir).replace('\\', '/')
            if relpath in indexed_paths:
                continue
            meta = read_gpkg_metadata(fullpath)
            cpv = meta.get('CPV')
            if not cpv:
                base = re.sub(r'-\d+$', '', f[:-9])
                m = re.match(r'^(.+?)-(\d[\w.*+-]*(?:-r\d+)?)$', base)
                if not m:
                    continue
                pn, ver = m.group(1), m.group(2)
                cat = meta.get('CATEGORY')
                if not cat:
                    continue
                cpv = f"{cat}/{pn}-{ver}"
            bid = meta.get('BUILD_ID', '')
            block = {'CPV': cpv, 'PATH': relpath}
            for k in META_KEYS:
                if k in meta:
                    block[k] = meta[k]
            if 'BUILD_ID' not in block and bid:
                block['BUILD_ID'] = bid
            entries.append(block)
            added += 1
    return entries, added

import re

d = tempfile.mkdtemp()
pkgdir = os.path.join(d, 'binpkgs')
os.makedirs(pkgdir)
oses = os.path.join(pkgdir, 'dev-ruby')
os.makedirs(oses)
gp = os.path.join(oses, 'rubygems-4.0.4-1.gpkg.tar')
with tarfile.open(gp, 'w') as tf:
    def add(name, content):
        b = content.encode()
        ti = tarfile.TarInfo(name); ti.size = len(b)
        tf.addfile(ti, io.BytesIO(b))
    add('metadata/CATEGORY', 'dev-ruby')
    add('metadata/CPV', 'dev-ruby/rubygems-4.0.4')
    add('metadata/BUILD_ID', '1')

# First run: emaint would have written the index with the CORRECT (virtual) CPV
# but the SAME on-disk PATH. Simulate that stale-but-path-correct index.
pf = os.path.join(pkgdir, 'Packages')
with open(pf, 'w') as f:
    f.write('\'hello\'\n\n')
    f.write('CPV: virtual/rubygems-4.0.4\n')
    f.write('PATH: dev-ruby/rubygems-4.0.4-1.gpkg.tar\n')
    f.write('BUILD_ID: 1\n\n')

entries, added = reconcile(pkgdir, pf)
print('Run1 added (expect 0):', added)
assert added == 0, f'FAIL: expected 0 added, got {added}'
assert any(e['CPV']=='virtual/rubygems-4.0.4' for e in entries), 'index CPV preserved'
print('PASS: no phantom re-add despite gpkg self-CPV != index CPV')
print('entries:', len(entries))
