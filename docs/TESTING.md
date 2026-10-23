# Validation / ověření

No WoW client is available in the build environment. Every in-game checkbox below
is **unrun**. Offline mocks validate Lua logic and event wiring, not WoW behavior,
source accuracy on a live account, rendering, model geometry, combat safety or taint.

V sestavovacím prostředí není WoW klient. Herní testy níže zatím **neproběhly**.
Mocky potvrzují jen logiku a propojení; nejsou důkazem funkčnosti ve hře.

## Offline

Run `python3 tools/check.py [path/to/wow-ui-source]` with `tools/requirements.txt`.
The checker fails on syntax errors, missing TOC files, Lua files absent from the
TOC, mismatched translations / formatting placeholders, divergent release versions,
or a Markdown/runtime changelog mismatch. With Blizzard sources it also validates
the names of referenced namespaced functions and collection/item/model events.

Behavior tests cover:

- GUID profile isolation, empty defaults, shared account settings, separate variant
  IDs, duplicate prevention, pinning, manual order, and removing goals.
- Additive v1→v2 migration, preserved unknown fields, idempotence, and refusal of
  newer schemas without data reset; SavedVariables-shaped serialization/reload.
- Source IDs versus visual IDs, appearance deduplication, variable set size,
  missing source data, empty/malformed replies and changed/truncated shapes.
- Set-completion consistency, selected-only summaries, no empty 100%, preserved
  temporarily unavailable IDs, and expansion browsing without changing focus.
- Notification first-load baselines, incomplete→complete transitions, duplicate
  events, persistence across reload, and new-piece tracking.
- Raid counts deduplicated across selected variants and alternative routes;
  verified Tier 4 token routing, relocated original Tier 2 helms, catalog evidence.
- TOC-order initialization and UI wiring with empty and populated profiles, both
  languages, all three skins and sort orders, Settings, changelog, minimap and
  late Wardrobe loading, using strict test stand-ins.
- Coalesced collection events, bounded incomplete-data retries and cancellation
  when the tracker is hidden; irrelevant item events are ignored.
- ZIP contents: one `MogFocus/` root, matching TOC paths, no missing runtime
  dependencies, deterministic archive and SHA-256 digest.

## Herní checklist — Retail 12.1.5.70529

Před testováním zálohujte SavedVariables při ukončené hře. Lua chyby zobrazíte
pomocí `/console scriptErrors 1`; po testu je lze vypnout pomocí hodnoty `0`.
Zaznamenejte výstup `/mogfocus debug`, rozlišení a UI scale. Testujte také bez
dalších addonů, aby šlo určit případné kolize.

- [ ] První spuštění: prázdný profil, žádné oslavy, české texty, Warcraft skin,
  ikona helmy, souhrn 0 z 0 bez 100 %, tlačítko „Vybrat první set“.
- [ ] Před prvním otevřením Collections: slash a minimapa otevřou tracker. Poté
  Collections zobrazí MogFocus ve spodní řadě hned za Campsites; záložka je čitelná,
  kliknutelná a nekoliduje s ostatními záložkami. Nahoře u Items/Sets není tlačítko.
- [ ] Po předchozím načtení Collections a po `/reload` se záložka nevytváří dvakrát.
  Přepnutí na Mounts/Pets/Appearances obnoví původní stránku a skryje tracker.
- [ ] Katalog: filtry expanze, raidu, classy a varianty; textové hledání; první
  otevření i studená cache; neraidové a neověřené kolekce lze vybrat bez čekání na zdroje.
- [ ] Přidat dvě dostupné obtížnosti stejného setu. Přidání každé vytvoří právě
  jeden vlastní cíl. Počty, názvy variant a sloty odpovídají Blizzard Wardrobe.
- [ ] Připnout jeden cíl, změnit vlastní pořadí, zkusit řazení podle dokončení a
  raidu, skrýt hotové, odebrat a znovu přidat variantu.
- [ ] Připravit cíle pro TBC při aktuálním Classic. Pouhé prohlížení TBC nezmění
  cíl Classic. Výslovná změna aktuálního cíle se po `/reload` a loginu zachová.
- [ ] Dvě postavy stejné classy mají odlišné cíle/pořadí/připnutí/zaměření,
  přesto vidí skutečnou sdílenou kolekci. Ověřit i GUID na různých realmech.
- [ ] U několika setů porovnat získáno/celkem s Blizzardem; ověřit sety s jiným
  počtem částí, zdroje stejného vzhledu, varianty a pravidla použitelnosti.
- [ ] Studená item cache: nejdříve načítání nebo ID, později název a ikona bez
  falešného 0/N. Neúplná/pozdní odpověď nesmí vyvolat dokončení.
- [ ] Molten Core: např. Arcanist Boots 16800 → Lucifron; pás/bracery → trash.
  Tier 2 nohy → Ragnaros, původní Onyxia helma (např. Judgment Crown 16955) →
  současný Nefarian v Blackwing Lair, nikoliv odstraněný starý Onyxia raid.
- [ ] TBC token: Justicar Breastplate 29071 → Magtheridon → Chestguard of the
  Fallen Champion 29754 → Asuur/Arodis, správná reputace a výměna.
- [ ] Kompletní Tier 4 varianta: rukavice/helma v Karazhanu, ramena/nohy u
  Maulgara/Gruula, hrudník u Magtheridona. Zdroje se nesmí sjednotit na jeden raid.
- [ ] Kam jít: jeden vzhled ze dvou setů má v raidu počet 1, alternativy jsou
  srozumitelně označeny, neověřené zdroje zůstávají viditelné. Journal otevře
  správnou instanci a bosse pouze u záznamů s platnými ID.
- [ ] Nově odemknout vzhled bez ručního reloadu. Postup se aktualizuje, poslední
  kus se zvýrazní; dokončení má jedno oznámení a zvuk jen při zapnuté volbě.
  Opakovaná událost, otevření, změna skinu, `/reload` a login neopakují oslavu.
  Již hotový set přidaný při prvním načtení také nevyvolá oznámení.
- [ ] Náhled dosud nezískané varianty na několika rasách: celé oblečení, rotace,
  zoom, reload modelu po transformaci. Skutečný transmog zůstává beze změny.
- [ ] Warcraft, Obsidian, Arcane: všechny karty, detaily, picker, Settings,
  oznámení a changelog; čeština a angličtina včetně diakritiky a dlouhých textů.
  Změny neovlivní cíle ani aktuální zaměření. Omezení animací zastaví zvýraznění.
- [ ] Nízké/vysoké rozlišení a UI scale; dlouhé názvy předmětů a tokenové cesty,
  rolování dlouhého katalogu/detailu, žádné překrytí textů. Escape zavře tracker.
- [ ] Levý/pravý klik a tažení minimapy; poloha i skrytí přežijí `/reload`.
  Nastavení otevřít přes všechny vstupy a native Settings → AddOns.
- [ ] Changelog z verze i nastavení, oba jazyky, shodná verze/datum a text jako
  v Markdownu; značka novinek po přečtení zmizí a po `/reload` se nevrátí.
- [ ] Aktualizace přes existující adresář bez smazání SavedVariables zachová
  cíle; otestovat migraci kopie staršího schématu a odmítnutí budoucího schématu.
- [ ] V boji: žádná Lua/taint chyba ani chráněná akce, nový tracker/Settings/
  Journal počká; Collections načtené v boji dostanou vstup až po boji.
- [ ] Skrytý tracker neskenuje katalog ani modely každý frame. Dávkovaná změna
  kolekce nezpůsobuje frontu opakovaných obnov; zkontrolovat CPU a paměť.

## English in-game checklist

Back up SavedVariables with WoW closed. Enable `/console scriptErrors 1`, record
`/mogfocus debug`, resolution and UI scale. Repeat relevant checks without other
addons to isolate integration conflicts.

- [ ] Empty first login, correct defaults, no completion celebration, no empty
  100%, functional first-set button.
- [ ] Slash/minimap before Collections loads; Collections tab before/after first
  opening, reload, page switching and another addon adding controls. No duplicate
  button or overlap with search/filters.
- [ ] Catalog search and expansion/raid/class/variant filters, cold cache, only
  inclusion of non-raid and unknown-source sets. Add two variants separately without duplicates.
- [ ] Compare counts, variants, slots and usability with Blizzard's collection;
  test variable part counts and multiple sources sharing an appearance.
- [ ] Separate browsing from saved current focus; prepare TBC while focused on
  Classic. Pin/order/remove/hide goals and verify `/reload` and a new login.
- [ ] Two characters of the same class have independent goals and focus; shared
  collection ownership remains accurate. Test same-name characters across realms.
- [ ] Cold/missing data shows loading/unavailable, never false zero progress or
  completion. Names and icons recover after asynchronous item data arrives.
- [ ] Verify Classic boss and trash routes; original Tier 2 legs from Ragnaros,
  original Onyxia helms now on Nefarian, never removed legacy Onyxia.
- [ ] Verify a Tier 4 token exchange, including exact token, Asuur/Arodis and
  reputation; verify one complete Tier 4 variant split across all three raids.
- [ ] Where to go deduplicates shared appearances, distinguishes alternatives
  and unknown routes; each enabled Journal link opens the correct encounter.
- [ ] Unlock an appearance and finish a selected goal. One notification, optional
  sound, no repeated celebration on duplicate events, skin changes or reload/login.
  Initially completed goals establish a silent baseline.
- [ ] Preview uncollected variants on multiple races, rotate and zoom; actual
  transmog never changes. Validate transformation/model reload behavior.
- [ ] All three skins and both languages across all custom components, Czech
  glyphs and long source text; reduced animation mode; low/high UI scale and
  resolution; scrolling and Escape.
- [ ] Minimap clicks/drag/hide/persistence, every Settings entry point, changelog
  version/date/text, unread marker cleared permanently after reading.
- [ ] Upgrade without data loss, migration on a backup, future-schema refusal.
- [ ] Combat safety and taint, late Collections load deferred until combat ends;
  hidden-window performance and event coalescing.

## 0.2.0 regression checklist / kontrola aktualizace

The automated runner now executes the 13 original behavior tests plus 8 update
regressions (one in a fresh VM for combat-first initialization), Lua 5.1 syntax/TOC order, 122 keys in both languages, both actual TTF
character maps, changelog parity and optional Blizzard source-contract checks.
Fixture ID comparisons verify the algorithm; they do not establish live catalog
completeness. The following checks are UNRUN without a WoW client:

- [ ] Copy 0.1.0 SavedVariables as a backup, install 0.2.0, verify each character’s
  targets, variants, order, pin/focus, language, skin, and account preferences.
- [ ] Show the exact sample from FONTS.md in Czech Settings, buttons, pickers,
  tooltip, catalog/list rows, action confirmations and changelog. Switch all three
  skins and both languages, scroll/reuse rows, close/reopen. No missing glyph boxes.
- [ ] Right-click an original Blizzard Sets row. Keep Blizzard favorite actions
  functional; verify Czech Add/Already tracked/Remove text uses the bundled font.
  Scroll, search and change class, then right-click a reused row: the action must
  target that row’s set. For a group choose exactly one variant, verify duplicates
  cannot be added, remove it again, and confirm focus/other profiles never change.
- [ ] Collections main tab is immediately after Campsites before/after repeated
  opens, reload, loading Collections for the first time and changing UI scale.
  Check the native selected/unselected states, tab text fitting and other addons
  adding tabs before/after MogFocus. There is no Wardrobe header button.
- [ ] MogFocus displays INSIDE Collections; content fits 703×606 and any native
  size changes, with readable text, scrollable parts and usable preview/actions.
  Switch back to Appearances and all other pages; original content returns.
  Slash and minimap target the same tab; Escape/native close closes Collections.
- [ ] With default Blizzard filters, run `/mogfocus catalogcheck` for EVERY class.
  Compare actual missing ID lists, base/variant IDs, hidden-until-collected rules,
  PvP/event/vendor/raid sets and every available expansion with Blizzard Sets.
  Reset native collected/PvE/PvP/search filters first, then test them individually.
  Expected missing count is zero for every nonempty native view. Retain the output
  and IDs, not just a claim that the number of rows looks right.
- [ ] Catalog appears before raid/source enrichment and offers unknown sources.
  With an empty profile, opening/scanning catalog leaves My sets empty. Each add
  requires an explicit action and selects only that exact setID.
- [ ] Enter combat before first Collections load, while switching tabs and with
  a menu/preview already open. No protected-action/taint error, duplicated tabs
  or changed native callbacks; deferred integration completes after combat.

Při herním ověření zaznamenejte skutečná ID a varianty přes `catalogcheck`, nikoliv
jen počet řádků. Postupně vyberte všechny classy a expanze v původním Blizzard UI.
Samostatně ověřte neraidový set bez známého zdroje, ruční výběr jediné varianty,
české položky pravého tlačítka po scrollování a návrat z MogFocus na původní stránky.
Všechny uvedené herní body zatím čekají na klienta.
