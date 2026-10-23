"""Render both language sections from the runtime release data."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime()
namespace = lua.table()
for file in ("Bootstrap.lua", "Locale.lua", "Changelog.lua"):
    lua.eval("function(s) return assert(loadstring(s)) end")((root / "MogFocus" / file).read_text())("MogFocus", namespace)
lines = ["# Changelog / Co je nového", ""]
for _, release in namespace.changelog.items():
    lines += [f"## {release.version} — {release.date}", ""]
    for language, heading in (("cs", "Čeština"), ("en", "English")):
        dictionary = namespace.locales[language]
        lines += [f"### {heading}", ""]
        for category in ("features", "changes", "fixes"):
            lines += [f"**{dictionary['CHANGE_' + category.upper()]}**", "", dictionary[release[category]], ""]
(root / "CHANGELOG.md").write_text("\n".join(lines), encoding="utf-8")
