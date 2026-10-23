#!/usr/bin/env python3
"""Offline Lua 5.1 checks; mocks do not establish WoW compatibility."""
import re
import sys
from pathlib import Path

from lupa.lua51 import LuaRuntime
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "MogFocus"
toc = (ADDON / "MogFocus.toc").read_text(encoding="utf-8")
files = [line.strip().replace("\\", "/") for line in toc.splitlines() if line.strip() and not line.startswith("#")]
assert len(files) == len(set(files)), "Duplicate TOC entry"
assert set(files) == {str(p.relative_to(ADDON)) for p in ADDON.rglob("*.lua")}, "Missing / extra TOC Lua file"
assert "## Interface: 120105" in toc
assert "## SavedVariables: MogFocusDB" in toc
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval("function(source, name) local fn, err = loadstring(source, name); assert(fn, err); return fn end")
chunks = []
for name in files:
    path = ADDON / name
    assert path.is_file(), f"Missing {name}"
    chunks.append(compile_lua(path.read_text(encoding="utf-8"), "@" + name))
print(f"PASS Lua 5.1 syntax and TOC: {len(files)} files")
lua.execute((ROOT / "tests/wow_mock.lua").read_text())
namespace = lua.table()
for chunk in chunks:
    chunk("MogFocus", namespace)
lua.globals().M = namespace
lua.execute((ROOT / "tests/test.lua").read_text())
lua.execute((ROOT / "tests/update.lua").read_text())

combat_lua = LuaRuntime()
combat_lua.execute((ROOT / "tests/wow_mock.lua").read_text())
combat_namespace = combat_lua.table()
for name in files:
    combat_lua.eval("function(s) return assert(loadstring(s)) end")((ADDON / name).read_text())("MogFocus", combat_namespace)
combat_lua.globals().M = combat_namespace
combat_lua.execute((ROOT / "tests/combat.lua").read_text())

# Literal localization usages and runtime changelog parity.
keys = set(namespace.locales.en.keys())
assert keys == set(namespace.locales.cs.keys()), "Locale dictionaries differ"
for path in ADDON.rglob("*.lua"):
    for key in re.findall(r'\bL\("([A-Z_0-9]+)"', path.read_text()):
        assert key in keys, f"Missing key {key} in {path}"
for key in keys:
    def placeholders(text):
        return re.findall(r"%(?:\d+\$)?[-+ #0]*\d*(?:\.\d+)?[cdeEfgGiouXxsq]", text.replace("%%", ""))
    assert placeholders(namespace.locales.en[key]) == placeholders(namespace.locales.cs[key]), key
version = re.search(r"## Version: (.+)", toc)[1]
assert version == namespace.version == namespace.changelog[1].version
markdown = (ROOT / "CHANGELOG.md").read_text()
release = namespace.changelog[1]
assert release.date in markdown and version in markdown
for language in ("en", "cs"):
    for category in ("features", "changes", "fixes"):
        assert namespace.locales[language][release[category]] in markdown, f"Changelog drift: {language}/{category}"
print(f"PASS localization: {len(keys)} keys per language; placeholders and bilingual changelog")

sample = "Příliš žluťoučký kůň úpěl ďábelské ódy. ČEŠTINA: ĚŠČŘŽÝÁÍÉŮÚĎŤŇ."
characters = set(sample + " ✓★•−→…")
characters.update("„“áčďéěíňóřšťúůýžÁČĎÉĚÍŇÓŘŠŤÚŮÝŽ")
for key in keys:
    characters.update(namespace.locales.cs[key])
font_paths = list((ADDON / "Fonts").glob("*.ttf"))
assert {p.name for p in font_paths} == {"DejaVuSans.ttf", "DejaVuSans-Bold.ttf"}
for path in font_paths:
    with TTFont(path) as font:
        cmap = font.getBestCmap()
        missing = {c for c in characters if not c.isspace() and ord(c) not in cmap}
        assert not missing, f"{path.name}: missing glyphs {missing}"
    print(f"PASS font Unicode coverage: {path.name}, {len(characters)} characters")
assert (ADDON / "LICENSES/DejaVu.txt").is_file()
for path in (ADDON / "UI.lua", ADDON / "Skins.lua"):
    assert "GameFont" not in path.read_text(), f"Global FontObject restored in {path}"

# Optional source-contract check against the verified Blizzard UI checkout.
if len(sys.argv) > 1:
    api = Path(sys.argv[1]) / "Interface/AddOns/Blizzard_APIDocumentationGenerated"
    namespaces = {}
    for path in api.glob("*Documentation.lua"):
        source = path.read_text()
        match = re.search(r'Namespace = "(C_[^"]+)"', source)
        if match:
            namespaces.setdefault(match[1], set()).update(re.findall(r'Name = "([^"]+)",\s*Type = "Function"', source))
    checked = set()
    for path in ADDON.rglob("*.lua"):
        text = path.read_text()
        calls = re.findall(r'M\.Call\((C_\w+), "(\w+)"', text)
        calls += re.findall(r'\b(C_\w+)\.(\w+)\(', text)
        for space, function in calls:
            assert function in namespaces.get(space, set()), f"Unverified API {space}.{function}"
            checked.add((space, function))
    docs = "\n".join(p.read_text() for p in api.glob("*Documentation.lua"))
    for event in re.findall(r'"((?:TRANSMOG_|ITEM_DATA_|UNIT_MODEL_)[A-Z_]+)"', (ADDON / "Core.lua").read_text()):
        assert f'LiteralName = "{event}"' in docs, f"Unverified event {event}"
    print(f"PASS Blizzard source contracts: {len(checked)} API functions and collection/item/model events")
print("Offline checks completed. No WoW client was executed.")
