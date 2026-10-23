# MogFocus 0.2.0 — WoW Retail

[Download / stáhnout ZIP](https://github.com/Stradiverius/mogfocus/raw/refs/heads/main/dist/MogFocus-0.2.0.zip)

## Česky

MogFocus sleduje ručně vybrané transmog sety a jednotlivé varianty pro každou
postavu zvlášť. Katalog nyní zahrnuje raidové i ostatní sety, které poskytuje
Blizzard Sets. Znalost zdroje není podmínkou výběru. Addon nemá povinné knihovny,
backend ani externí účet. Je určen pro Retail, nikoliv klienty Classic.

### Instalace a aktualizace

1. Ukončete hru a zálohujte
   `WTF/Account/<účet>/SavedVariables/MogFocus.lua`.
2. Rozbalte `MogFocus-0.2.0.zip` do
   `World of Warcraft/_retail_/Interface/AddOns/`.
3. Výsledná cesta je `Interface/AddOns/MogFocus/MogFocus.toc`. ZIP má právě jednu
   kořenovou složku `MogFocus`, včetně fontů a licencí. Nevytvářejte druhou vnořenou
   složku. Při aktualizaci nemažte SavedVariables.
4. Povolte MogFocus v seznamu addonů. Cílový klient je **12.1.5.70529**, Interface
   **120105**; skutečnou verzi zjistíte `/mogfocus debug` nebo `/dump GetBuildInfo()`.
   Při jiném buildu ověřte API, nepřepisujte pouze číslo v `.toc`.

Verze 0.2.0 zachovává schéma 2, GUID profily, vybrané varianty, pořadí, připnutí,
aktuální expanzi i všechna nastavení verze 0.1.0. Načtení katalogu nepřidává cíle.

### Otevření a používání

- Otevřete **Collections → MogFocus** ve spodní hlavní řadě ihned napravo od
  **Campsites**. Tracker je přímo v okně Collections. Přepnutí zpět na Appearances,
  Mounts nebo jinou záložku zobrazí původní stránku. Původní tlačítko překrývající
  postup nahoře v Appearances bylo odstraněno.
- Ikona helmy u minimapy i `/mogfocus` otevřou stejnou záložku. Levý klik ji
  přepíná, pravý klik otevře nastavení; tažením ikony uložíte polohu. Nové otevření
  trackeru a Settings/Journal je v boji odloženo nebo odmítnuto krátkou zprávou.
- Nová postava začíná bez cílů. **Vybrat první set / Přidat sety** otevře katalog.
  Výchozí filtr je aktuální classa; lze vybrat jinou classu i všechny. Expanze,
  varianta, hledání a nepovinný filtr konkrétního raidu zůstávají dostupné.
- Katalog načte ID a názvy bez čekání na dropy. Podrobnosti zdrojů dohledává
  dávkově a jen při otevření katalogu. Set bez známého zdroje lze normálně přidat.
  Hidden-until-collected varianty respektují data Blizzardu. Výběr jedné varianty
  nepřidá ostatní. Nezaškrtnuté sety se nikdy automaticky nesledují.
- V původním **Appearances → Sets** klikněte pravým tlačítkem na set. Nabídka
  zachová původní položky Blizzardu a doplní **Přidat do MogFocus**. U skupiny
  nejprve zvolte konkrétní variantu v podnabídce MogFocus. Již sledovaná varianta
  má stav **Již sledováno** a akci **Odebrat z MogFocus**. Přidání potvrdí krátké
  oznámení. Aktuální expanze ani cíle jiných postav se nemění.
- **Moje sety** obsahují pouze cíle této postavy ve zvolené expanzi. Výběr lze
  připnout, odepnout, seřadit, skrýt po dokončení nebo odebrat. Prohlížení jiné
  expanze nezmění uložený **Aktuální cíl**; použijte výslovnou změnu zaměření.
- Detail zobrazuje skutečný počet získaných vzhledů, sloty, ikony, tooltipy a
  zdroje. **Pouze chybějící** omezí seznam. `? / ?` je neúplná odpověď, ne 0/N.
  **Obnovit** umožňuje opakovat načtení. Náhled obléká pouze samostatný model vaší
  postavy, nepoužívá aplikaci transmogu. Tažením jej otočíte, kolečkem přiblížíte.
- **Kam jít** seskupuje chybějící vzhledy podle doložených raidů a ostatních
  zdrojů. V rámci raidu jsou počty bez duplicit. Alternativy jsou možnosti získání
  stejného vzhledu, nikoliv další povinné dropy. Neznámé vazby mají stav
  **Zdroj neověřen**. Journal se nabízí pouze u ověřených číselných ID.
- Nastavení otevřete v **Settings → AddOns → MogFocus**, tlačítkem v trackeru,
  pravým klikem na minimapu nebo `/mogfocus options`. Obsahuje češtinu/angličtinu,
  Warcraft/Obsidian/Arcane, minimapu, hustotu karet, řazení, dokončené cíle,
  chybějící části, oznámení, zvuk a omezení animací. Kliknutí na verzi nebo
  **Co je nového** otevře dvojjazyčný changelog a odstraní značku novinek.

Vlastní rozhraní používá přibalený **DejaVu Sans** a vlastní FontObjects. Přepnutí
skinu ani opětovné použití řádku nesmí obnovit font Blizzardu bez českých znaků.
Nemění se globální fonty WoW. Názvy setů, bossů a předmětů zůstávají podle klienta.
Licence je v `MogFocus/LICENSES/DejaVu.txt`, podrobnosti v [docs/FONTS.md](docs/FONTS.md).

### Diagnostika, rozsah dat a testování

`/mogfocus debug` vypíše verzi, build a dostupnost API bez osobních údajů.
`/mogfocus catalogcheck` porovná ID aktuálního filtrovaného seznamu Blizzard Sets
a jeho variant s katalogem MogFocus a vypíše chybějící ID. Pro ověření všech class
opakujte příkaz po jejich výběru v původním Blizzard rozhraní; audit nemění filtry
ani sledované cíle. Prázdný filtrovaný seznam není důkazem úplnosti.

Lokální databáze stále obsahuje 229 doložených mapování Classic a Tier 4, doplněných
živými drop daty API. Ostatní tokeny, questy a prodejci mohou mít neověřené zdroje;
**to již neomezuje katalog ani možnost výběru**. Podrobnosti a licence ATT jsou
v [docs/SOURCES.md](docs/SOURCES.md).

Prošly automatické Lua 5.1 testy a kontroly znakových map obou fontů. **Běžící WoW
klient nebyl k dispozici.** Vykreslení, úplnost ID na živém účtu, combat/taint,
načítání modelů a kolize addonů ověřte podle [docs/TESTING.md](docs/TESTING.md).

## English

MogFocus tracks manually selected transmog set variants separately for each
character. The catalog now includes raid and non-raid sets supplied by Blizzard
Sets, across classes and expansions. Source metadata is optional. There are no
required addons, libraries, backend or external accounts. Retail only.

### Install / update

Exit WoW and back up `WTF/Account/<account>/SavedVariables/MogFocus.lua`. Extract
`MogFocus-0.2.0.zip` into `World of Warcraft/_retail_/Interface/AddOns/`; the final
path must be `Interface/AddOns/MogFocus/MogFocus.toc`, without doubled nesting.
Fonts and licenses are bundled. Enable MogFocus and keep your SavedVariables on
upgrade. Version 0.2.0 retains schema 2 and all previous GUID-keyed goals, order,
pin, focus and account options. Catalog loading never selects goals automatically.

Target: **Retail 12.1.5.70529**, Interface **120105**. Check your actual version
with `/mogfocus debug` or `/dump GetBuildInfo()`. Different builds need API
validation, not just a changed TOC number.

### Use

Open the bottom **Collections → MogFocus** tab immediately after **Campsites**.
Its tracker lives inside Collections and restores the original page when another
tab is selected. The overlapping Wardrobe header button is gone. The minimap
helmet and `/mogfocus` open this same tab. Minimap right click opens options;
dragging saves its position. UI creation/opening is guarded during combat.

New characters start empty. **Choose first set / Add sets** opens the catalog,
initially filtered to the current class. Choose another class or all classes,
expansion, variant, search text, or optionally a known raid. Catalog IDs are
available before optional source lookups. Unknown-source and non-raid sets remain
selectable; hidden-until-collected visibility follows Blizzard metadata. Selecting
one variant never selects the group.

Right-click a row in the original **Appearances → Sets** list to **Add to MogFocus**.
A group opens a MogFocus variant submenu requiring an explicit choice. Tracked
variants show **Already tracked / Remove from MogFocus**. A short notification
confirms the action; other characters and saved expansion focus stay unchanged.
The original Blizzard menu actions and left-click behavior remain in place.

**My sets** shows only this character's chosen goals in the browsed expansion.
Pin/unpin, manually reorder, sort by progress/raid, hide completed or remove goals.
Browsing and saved **Current focus** are independent. Detail rows show collection
counts, icons, slots, tooltips and acquisition information; **Missing only** filters
the parts. `? / ?` means incomplete data, never zero progress. **Refresh** retries
loading. The rotatable/zoomable character preview changes only its own model.

**Where to go** groups missing appearances by verified raid or other source,
deduplicates within a raid and identifies alternative acquisition routes. Missing
metadata says **Source unverified**. Journal links require verified numeric IDs.

Use native **Settings → AddOns → MogFocus**, the tracker settings button, minimap
right click or `/mogfocus options`. Options retain both languages, all three
skins, minimap, density, sort order, completed goals, missing parts, notifications,
sound and reduced animations. Click the version / **What's new** for the bilingual
changelog and to clear its unread marker.

Bundled **DejaVu Sans** and private FontObjects provide Czech glyphs throughout
the addon, including reused rows and context-menu additions, without changing any
global WoW font. Game-supplied names remain in client language. See
[docs/FONTS.md](docs/FONTS.md) and the bundled license.

### Diagnostics and validation

`/mogfocus catalogcheck` compares real IDs in the **currently filtered** Blizzard
Sets view and its variants against MogFocus. Repeat with each class selected in
Blizzard's UI to audit all classes. The command changes neither filters nor goals;
zero native results do not establish completeness. `/mogfocus debug` reports the
client and required APIs without personal data.

The existing 229 Classic / Tier 4 mappings and live drop API remain unchanged.
Unknown token, vendor and quest routes **no longer restrict catalog membership**;
see [docs/SOURCES.md](docs/SOURCES.md). **No WoW client was executed.** Automated
checks cover logic, font cmaps and UI wiring; rendering, live-account catalog
parity, combat/taint, models and addon collisions still need the
[in-game checklist](docs/TESTING.md).

## Development / vývoj

```sh
python3 -m venv /tmp/mogfocus-venv
/tmp/mogfocus-venv/bin/pip install -r tools/requirements.txt
/tmp/mogfocus-venv/bin/python tools/check.py /path/to/wow-ui-source
/tmp/mogfocus-venv/bin/python tools/package.py
```

The source checkout argument is optional. Tests use Lua 5.1 through Lupa and
fontTools for the shipped TTF character maps; these are not runtime dependencies.
`tools/render_changelog.py` regenerates Markdown from the runtime release data.
Future releases must update both TOC/Bootstrap version and bilingual Lua changelog.
