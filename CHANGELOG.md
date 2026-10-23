# Changelog / Co je nového

## 0.2.1 — 2026-10-23

### Čeština

**Nové funkce**

Diagnostika nově ukazuje připravenost fontů, nastavení, Collections a trackeru. Chybějící font má dočasnou náhradu s jednorázovým vysvětlením.

**Změny**

Jednotlivé části rozhraní mohou načítání zopakovat nezávisle. Nedokončené rámy zůstávají skryté a opětovné otevření Collections může načítání dokončit bez duplicitních záložek a obsluh událostí. Uložené cíle a nastavení se nemění.

**Opravy**

Opravena fatální kontrola fontu: SimpleFont:SetFont v Retailu nevrací hodnotu. Opraven testovací model a doplněno ověření pořadí přihlášení, běžného otevření Collections bez příkazu, odložení v boji a přerušeného načítání. Ještě je nutné ověření přímo ve hře.

### English

**New features**

Startup diagnostics now report font, Settings, Collections and tracker readiness. A missing font uses a temporary fallback with one explanatory message.

**Changes**

UI setup stages can retry independently. Incomplete frames remain hidden, and reopening Collections can finish setup without duplicate tabs or callbacks. Saved goals and settings are unchanged.

**Fixes**

Fixed the fatal font assertion: SimpleFont:SetFont returns no value in Retail. Corrected the test mock and covered login order, normal Collections opening without a slash command, combat deferral and interrupted initialization. In-game validation remains required.

## 0.2.0 — 2026-10-23

### Čeština

**Nové funkce**

Nativní záložka Collections vedle Campsites a sledování pravým tlačítkem v Blizzard Sets s výslovným výběrem varianty. Katalog zahrnuje i neraidové sety, všechny classy a expanze poskytované Blizzardem.

**Změny**

Tracker se přizpůsobuje oknu Collections při čitelné velikosti písma. ID katalogu jsou dostupná před načtením zdrojů. Existující profily, nastavení a ručně vybrané cíle zůstávají zachované.

**Opravy**

Přibalený licencovaný DejaVu Sans a vlastní FontObjects podporují češtinu ve všech skinech, opakovaně používaných řádcích, nabídkách, tooltipech, nastavení, oznámeních a changelogu. Odstraněno překrývající tlačítko nahoře ve Wardrobe a opraveno odepnutí cíle.

### English

**New features**

A native Collections tab beside Campsites and right-click tracking from Blizzard Sets, with explicit variant selection. Catalog includes non-raid sets, all classes and expansions exposed by Blizzard.

**Changes**

The tracker fits Collections at native font size. Catalog IDs appear before optional source details. Existing profiles, settings and manually selected goals are preserved.

**Fixes**

Bundled licensed DejaVu Sans and private FontObjects cover Czech text in every skin, reused row, menu, tooltip, Settings, notification and changelog. Removed the overlapping Wardrobe header button and corrected unpinning.

## 0.1.0 — 2026-10-23

### Čeština

**Nové funkce**

Cíle jednotlivých postav a variant, postup kolekce, seskupení raidových zdrojů, vstup z Wardrobe, náhled postavy, minimapa, Settings, tři skiny a české/anglické rozhraní.

**Změny**

První vydání. Ověřená lokální mapování Molten Core / Blackwing Lair a tokenů Tier 4 doplňují živá data kolekce. Neověřené zdroje zůstávají viditelné.

**Opravy**

Bez předchozího vydání. Ještě je nutné ověření přímo ve hře; viz přiložený checklist.

### English

**New features**

Per-character variant goals, collection progress, raid-source grouping, Wardrobe entry, character preview, minimap, Settings, three skins and Czech/English UI.

**Changes**

First release. Verified local Molten Core / Blackwing Lair and Tier 4 token mappings supplement live collection data. Unverified sources stay visible.

**Fixes**

No previous release. In-client validation remains required; see the bundled checklist.
