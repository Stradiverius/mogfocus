# MogFocus 0.1.0

Skutečný addon v Lua pro **World of Warcraft Retail**, určený ke sledování ručně
vybraných raidových transmog setů jednotlivých postav. Nejde o addon pro Classic
klienty. První vydání vyžaduje ověření přímo ve hře; offline testy nejsou herní test.

## Česky

### Instalace a verze klienta

1. Ukončete hru. Rozbalte `MogFocus-0.1.0.zip` do
   `World of Warcraft/_retail_/Interface/AddOns/`.
2. Výsledná cesta musí být `Interface/AddOns/MogFocus/MogFocus.toc`, nikoliv
   `MogFocus/MogFocus/MogFocus.toc`. Žádné další addony ani knihovny nejsou potřeba.
3. Na obrazovce postav povolte MogFocus. Po přihlášení použijte `/mogfocus`.
4. Cílový build je **12.1.5.70529**, Interface **120105**, ověřený proti zdrojům
   Blizzard UI uvedeným v [docs/API.md](docs/API.md). `/mogfocus debug` vypíše
   skutečnou verzi vašeho klienta i dostupnost API. Verzi lze zjistit také příkazem
   `/dump GetBuildInfo()`. Nesoulad klienta a `.toc` vyžaduje nové ověření API,
   nikoli jen přepsání čísla nebo ignorování označení zastaralého addonu.

### Používání

- Otevřete **Collections → Appearances** a tlačítko **MogFocus** vedle záložky Sets.
  Používáme samostatné tlačítko, aby nevznikaly kolize s interními ID záložek Blizzardu.
  Funguje také ikona helmy u minimapy a `/mogfocus`.
- Nová postava nemá žádné cíle. Klikněte na **Vybrat první set** nebo **Přidat sety**.
  Katalog se dávkově načítá pouze při zobrazení; nabízí filtry expanze, classy,
  raidu a varianty a hledání podle herních názvů. Zobrazuje pouze sety s doloženým
  raidovým původem primárních částí. Výchozí classa je classa aktuální postavy.
- Každá obtížnost má vlastní `setID`. Přidání Normal nepřidá Heroic nebo Mythic.
  Opětovným kliknutím lze cíl odebrat. Změna katalogového filtru expanze nezmění
  aktuální cíl. Použijte **Nastavit jako aktuální cíl** nebo horní **Aktuální cíl**.
- **Moje sety** obsahují jen cíle této postavy v zobrazené expanzi. Lze připnout
  jeden cíl a posouvat pořadí nahoru/dolů při vlastním řazení. Souhrn popisuje
  pouze váš výběr. Dobrovolný přechod k další expanzi žádné sety nepřidává.
- Detail ukazuje získané vzhledy, chybějící části, sloty a zdroje přímo v řádcích.
  Názvy předmětů se načítají asynchronně. `? / ?` znamená neúplná data, ne nulový
  postup. **Obnovit** znovu načte stav a umožní opakovat nedostupná item data.
- **Kam jít** seskupí chybějící vzhledy podle doložených raidů. Kliknutím skupinu
  rozbalíte. Počet v každém raidu je bez duplicit napříč sety. Alternativní raidy
  jsou možnosti získání stejného vzhledu; jejich počty nesčítejte jako povinnosti.
  Neověřené zdroje zůstávají ve zvláštní skupině. Journal lze otevřít pouze pro
  lokálně ověřené ID instance/bosse. Textové drop údaje API takové ID neobsahují.
- 3D náhled obléká pouze model vaší postavy. Tažením se otáčí, kolečkem přibližuje;
  nepoužívá API pro aplikaci skutečného transmogu. Podporu konkrétních modelů,
  ras a nezískaných vzhledů je nutné ověřit ve hře.
- **Settings → AddOns → MogFocus**, tlačítko nastavení v trackeru, pravý klik
  na minimapu nebo `/mogfocus options` otevřou nastavení. Jazyk a skin mění jen
  zobrazení. Levý klik na minimapu otevře tracker; přetažením se uloží úhel ikony.
- Kliknutím na verzi nebo **Co je nového** v nastavení otevřete changelog.
  Hvězdička novinek zmizí po přečtení.

Výchozí nastavení: čeština, Warcraft, viditelná minimapa, standardní karty,
vlastní pořadí, viditelné dokončené sety, všechny části, oznámení zapnutá,
zvuk vypnutý. Obsidian používá barvu classy, Arcane modrofialové panely a světlé
detaily. Volba omezení animací zastaví zvýraznění nově získaných ikon.

### Data a omezení

Účtová nastavení a profily podle GUID ukládá `MogFocusDB`. Dvě stejně pojmenované
postavy ani dvě postavy stejné classy nesdílí cíle. Vzhledy vycházejí ze společné
herní kolekce a příznaků dokončení konkrétního setu. Před aktualizací zálohujte
`WTF/Account/<účet>/SavedVariables/MogFocus.lua` při ukončené hře. Tento soubor
nemažte při běžné aktualizaci. Migrace jsou doplňující; novější neznámé schéma
se neotevře ani neresetuje.

Lokální databáze má **229 položek**: Tier 1 a některé Tier 2 zdroje v Molten Core,
současné Tier 2 dropy v Blackwing Lair (včetně původních Onyxia helem, dnes
Nefarian) a všech 85 Tier 4 výměnných předmětů pro tehdejší classy/specy.
Tier 4 rozlišuje Karazhan → The Curator / Prince Malchezaar,
Gruul's Lair → High King Maulgar / Gruul a Magtheridon's Lair → Magtheridon.
Zobrazuje konkrétní token a výměnu u Asuura / Arodise v Shattrathu, s podmínkou
neutrální reputace. API doplňuje další raidové dropy podle konkrétního zdroje.

**Datové mezery:** tokeny mimo Tier 4, questy/prodejci bez lokální vazby, původní
Naxxramas / obnovené Tier 3 a další zdroje bez drop záznamu API zatím nemají
úplné lokální pokrytí. Takové části ukazují „Zdroj neověřen“; nezařazené sety
bez doloženého primárního raidového zdroje nejsou v katalogu. Addon netvrdí, že
tyto zdroje jsou nedostupné. Neobsahuje drop rates, lockouty ani plánovač tras.
Pro úplný katalog všech historických raidových setů je třeba doplnit ověřená
mapování. Kontrola údajů přímo v aktuálním klientu je stále nutná.

### Diagnostika a testy

`/mogfocus debug` vypíše verzi, build, Interface a přítomnost funkcí API bez
osobních údajů. Pro hlášení chyby přiložte tento výpis, kroky reprodukce, `setID`
z katalogu a případnou Lua chybu. Checklist je v [docs/TESTING.md](docs/TESTING.md).

## English

### Installation and client version

1. Exit WoW and extract `MogFocus-0.1.0.zip` into
   `World of Warcraft/_retail_/Interface/AddOns/`.
2. Check for `Interface/AddOns/MogFocus/MogFocus.toc` with no doubled directory.
   No other addon, library, web account or service is required.
3. Enable MogFocus on the character screen and enter `/mogfocus` after login.
4. The target is **Retail 12.1.5.70529**, Interface **120105**. Source verification
   is recorded in [docs/API.md](docs/API.md). `/mogfocus debug` reports your actual
   client version and API availability; `/dump GetBuildInfo()` also shows the build.
   A different client requires API validation, not merely changing the TOC number.

### Use

Open **Collections → Appearances → MogFocus**, beside the Sets tab. A separate
button avoids collisions with Blizzard's tab IDs. The helmet minimap icon and
`/mogfocus` also open the tracker. First login starts with an empty character
profile. Choose **Choose first set** / **Add sets**, then search and filter by
expansion, class, raid and variant. The class defaults to your current class.
The catalog scans in batches while visible and admits only sets with evidence
of a raid primary source.

Each variant is a separate `setID`; selecting Normal never adds other variants.
Expansion browsing is separate from **Current focus**. Use **Make current focus**
to persist the browsed expansion. You may prepare later goals without changing
the current focus. On reopening, the tracker displays your saved focus.

**My sets** shows this character's selected goals in the filtered expansion.
Pin one main goal; move cards up/down in custom sorting mode. Summary percentages
refer to selected goals only. The optional next-expansion action adds no goals.
The detail shows variable appearance counts, slots, tooltips, missing status,
and visible acquisition routes. `? / ?` is an incomplete API response, not zero
progress. **Refresh** retries collection and item data.

**Where to go** groups missing appearances by verified raid. Expand each group
to see parts, sets, bosses, difficulties and token exchanges. Counts within a
raid deduplicate appearances across goals. Alternative raids are options for the
same appearance, not additional required drops. Unknown sources remain visible.
Journal buttons exist only when verified instance/encounter IDs are available;
the live drop API supplies names without IDs.

The preview dresses a separate model of your character, including uncollected
source IDs where supported. Drag to rotate and use the wheel to zoom. It never
applies a transmog to your character. Model/geometry behavior still needs in-game
validation for different races and sources.

Open **Settings → AddOns → MogFocus**, the tracker settings button, minimap right
click, or `/mogfocus options`. Minimap left click opens the tracker; drag to save
its angle. Account options include language, three skins, minimap visibility,
card density, ordering, completed goals, missing-only parts, notifications, sound,
and reduced animations. Click the version / **What's new** to read the changelog
and clear its unread marker. Names supplied by the game remain in client language.

Defaults: Czech, Warcraft, visible minimap icon, standard cards, custom order,
completed sets visible, all parts visible, notifications on, sound off. Obsidian
uses a flat graphite palette with class accents; Arcane uses blue/violet textured
panels and silver accents. Reducing animations stops new-piece icon highlighting.

### Persistence, coverage and diagnostics

`MogFocusDB` stores account options and separate GUID-keyed goals, order, pin,
focus and notification history. Collection ownership remains game-wide, using
Blizzard's set completion flags. Back up
`WTF/Account/<account>/SavedVariables/MogFocus.lua` while WoW is closed before
updating. Do not delete it on upgrade. Migrations preserve existing/unknown fields;
a future schema is refused without reset.

The local database covers **229 items**: Molten Core Tier 1 and Tier 2 parts,
current Blackwing Lair Tier 2 drops (including original Onyxia helms now dropped
by Nefarian), and all 85 Tier 4 exchange items. Tier 4 routes distinguish Karazhan,
Gruul's Lair and Magtheridon's Lair, the individual boss and token, and the Asuur /
Arodis exchanges in Shattrath requiring neutral reputation. Live collection drop
data supplements those records. See [docs/SOURCES.md](docs/SOURCES.md) for provenance.

**Known coverage gaps:** tokens beyond Tier 4, vendors/quests without local
mappings, original Naxxramas / restored Tier 3, and sources without live drop
metadata. Such parts say **Source unverified**. Sets without any verified raid
primary source cannot yet enter the catalog. This does not assert unavailability.
A complete historical raid catalog needs additional verified mappings. There are
no invented drop rates, route planning, lockouts or automation.

Use `/mogfocus debug` for version, build and API checks without personal data.
Report its output, reproduction steps, the catalog `setID` and Lua error text.
See [docs/TESTING.md](docs/TESTING.md) for required client checks.

## Development / vývoj

Python 3.12 and the optional development dependency `lupa==2.8` run the Lua 5.1
checks; none of this tooling ships as a runtime dependency.

```sh
python3 -m venv /tmp/mogfocus-venv
/tmp/mogfocus-venv/bin/pip install -r tools/requirements.txt
/tmp/mogfocus-venv/bin/python tools/check.py
/tmp/mogfocus-venv/bin/python tools/package.py
```

Pass a `Gethe/wow-ui-source` checkout as the optional argument to `tools/check.py`
to check the referenced API contracts against generated documentation.
Source files load in TOC order. Saved data, localization, collection, acquisition
sources, skins, UI, options and integration are separate modules. Future release
changes must update the TOC/Bootstrap version, Lua changelog and bilingual Markdown
changelog together. Packaging rejects checks that fail and verifies archive paths.
