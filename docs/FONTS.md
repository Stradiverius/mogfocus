# Bundled fonts / přibalené fonty

MogFocus ships unmodified **DejaVu Sans** and **DejaVu Sans Bold**, version
2.37, from the environment’s Debian `fonts-dejavu-core` package. Upstream:
https://dejavu-fonts.github.io/. Redistribution license and copyright notices are
in `MogFocus/LICENSES/DejaVu.txt` (Bitstream Vera license; DejaVu changes public domain).

| File | SHA-256 |
| --- | --- |
| `DejaVuSans-Bold.ttf` | `a4c5bc453ca281d90ea079e596da7ae0dfeb5777497c29ec254e76d97ff6f890` |
| `DejaVuSans.ttf` | `57f73e11f51999432bf7ab22ce55b6f945d5eca1bf824404cfa9ec2e3718c84e` |

`Fonts.lua` owns private FontObjects for body, button, title, menu and native tab states. `UI.lua` creates every custom string
with these objects; `Skins.lua` reapplies the same private fonts on refresh, and
row reuse uses the private button font. Search edit boxes, pickers, options,
notifications and changelog use the same paths. The native-tab font override is
restricted to MogFocus’s own tab. Context-menu initializers style only descriptions
added by MogFocus; pooled native menu strings are reset by Blizzard on reuse.
A separate MogFocus tooltip receives fonts both after display and after async
tooltip data processing. No global game font or global GameTooltip is modified.

Version 0.2.1 fixes a startup error in 0.2.0: a SimpleFont object's `SetFont`
method returns no value, so asserting that result incorrectly stopped the entire
font file. The methods are now defined before asset initialization. Loading is
checked with `pcall` and `GetFont`, and a real missing asset falls back inside the
private FontObject to the game font. A single localized warning requests a full
ZIP reinstall; the fallback keeps the UI usable but does not guarantee Czech
glyphs. The shipped TTF files and their hashes are unchanged.

Verze 0.2.1 opravuje pád při načítání: `SimpleFont:SetFont` nevrací potvrzení
úspěchu. Při skutečně chybějícím fontu se použije dočasné písmo hry a zobrazí se
jedna zpráva. Náhrada nemusí podporovat celou češtinu; obnoví ji instalace úplného
ZIPu s oběma fonty. Přibalené soubory fontů zůstávají beze změny.

`tools/check.py` reads BOTH shipped TTF Unicode cmaps using fontTools. It requires
every character from the Czech dictionary and the complete user-provided sample:

> Příliš žluťoučký kůň úpěl ďábelské ódy. ČEŠTINA: ĚŠČŘŽÝÁÍÉŮÚĎŤŇ.

It also checks the status symbols ✓ ★ • − → … . All required glyphs exist in both
fonts. This verifies glyph coverage, not rendering by WoW’s font engine. In-game
checks remain required after every skin/language change and recycled row/menu.

Oba fonty byly ověřeny podle skutečných znakových map, včetně celého českého
slovníku, testovací věty a symbolů stavu. Fonty se nepřepínají podle skinu a
nemění globální písmo hry. Názvy dodané klientem se nepřekládají. Čitelnost,
diakritiku a zachování vlastních fontů při obnově rámů ještě ověřte přímo ve WoW.
