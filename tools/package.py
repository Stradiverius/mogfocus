#!/usr/bin/env python3
"""Validate and create a deterministic, single-root install archive."""
import hashlib
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(ROOT / "tools/check.py")], check=True, cwd=ROOT)
addon = ROOT / "MogFocus"
toc = (addon / "MogFocus.toc").read_text()
version = re.search(r"## Version: (.+)", toc)[1]
output = ROOT / "dist"
output.mkdir(exist_ok=True)
archive = output / f"MogFocus-{version}.zip"
entries = {str(path.relative_to(ROOT)): path for path in addon.rglob("*") if path.is_file()}
for name in ("README.md", "CHANGELOG.md", "LICENSE"):
    entries["MogFocus/" + name] = ROOT / name
for path in (ROOT / "docs").glob("*.md"):
    entries["MogFocus/docs/" + path.name] = path
with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for name, path in sorted(entries.items()):
        info = zipfile.ZipInfo(name, date_time=(2026, 10, 23, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        z.writestr(info, path.read_bytes())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert set(z.namelist()) == set(entries)
    assert {name.split("/")[0] for name in z.namelist()} == {"MogFocus"}
    assert "MogFocus/MogFocus.toc" in z.namelist()
    assert not any("MogFocus/MogFocus/" in name or ".." in name.split("/") for name in z.namelist())
    for name, path in entries.items():
        assert z.read(name) == path.read_bytes(), name
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
(output / (archive.name + ".sha256")).write_text(f"{digest}  {archive.name}\n")
print(f"PASS archive: {len(entries)} files, single MogFocus/ root, {archive.stat().st_size} bytes")
print(f"SHA256 {digest}")
print(archive)
