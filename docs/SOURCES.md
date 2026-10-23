# Acquisition data / zdroje získání

Verification build: **12.1.5.70529**; source inspection: **2026-10-23**.

Live metadata comes from `C_TransmogCollection.GetAppearanceSourceDrops` on a
specific source, as used in Blizzard's `CollectionsUtil.lua`. It identifies the
instance, instance type, boss and difficulty strings, without numeric journal IDs.
Alternate appearance sources are considered only when the API marks them valid
for this character. The primary set flags, not alternate item ownership, determine
set progress. A route is not a claim about drop rate or guaranteed loot.

Lokální údaje doplňují především trashe, přesunuté staré dropy a tokeny. Dataset
nepoužívá názvy setů k přiřazení raidu. Databáze uchovává ID předmětu, instance,
encounteru a tokenu; názvy raidů a bossů čte z Journalu. Pokud Journal nevrátí jméno,
ověřený anglický název instance slouží jako fallback. Jméno nedostupného bosse se
nevymýšlí. U všech neznámých vazeb se ukáže „Zdroj neověřen“.

The local dataset in `MogFocus/Data/Sources.lua` is a narrow extraction from
[AllTheThings](https://github.com/DFortun81/AllTheThings) commit
[`43801dcbd75637ab62aa141409404179d5130338`](https://github.com/DFortun81/AllTheThings/tree/43801dcbd75637ab62aa141409404179d5130338),
MIT-licensed; attribution is bundled in `MogFocus/LICENSES/ATT.txt`.

| Source path under `.contrib/.db/standard/` | Included records |
| --- | --- |
| `01 - Dungeons Raids/01 - Classic/1.0 Molten Core.lua` | 81 distinct tier items: 72 Tier 1 items including 18 trash drops, plus nine Tier 2 legs from Ragnaros. Original Retail block only, excluding Season of Discovery. |
| `01 - Dungeons Raids/01 - Classic/1.6 Blackwing Lair.lua` | 63 distinct Tier 2 items, with bosses. Original Onyxia helms are correctly assigned to current Nefarian drops in the `AFTER WRATH` block. No instruction to visit removed level-60 Onyxia. |
| `01 - Dungeons Raids/02 - Burning Crusade/1 Karazhan (Raid).lua` | Token drops: gloves from The Curator (1557), helms from Prince Malchezaar (1563); journal instance 745. |
| `01 - Dungeons Raids/02 - Burning Crusade/2 Gruul's Lair.lua` | Shoulders from High King Maulgar (1564), legs from Gruul (1565); instance 746. |
| `01 - Dungeons Raids/02 - Burning Crusade/3 Magtheridon's Lair.lua` | Chests from Magtheridon (1566); instance 747. |
| `02 - Outdoor Zones/03 Outland/1 - Shattrath City.lua` | All 85 Tier 4 items and their token costs, under `TIER_FOUR_GROUPS`. Asuur (20616), 23.6/32.6, Aldor Rise; Arodis Sunblade (20613), 42.6/90.6, Scryer's Tier; neutral reputation required for the corresponding faction. |

The extraction tool pins the source SHA and checks for **229** distinct items,
including **15** token IDs and **85** exchange outputs. Rebuild with
`python3 tools/import_sources.py /path/to/pinned/AllTheThings` after reviewing
the exact extraction blocks. This is not a generic parser of ATT conditionals;
expanding its range without review is unsafe. New datasets need source references,
current Retail applicability and a verification build.

## Known gaps / známé mezery

Only direct raid drops exposed by live metadata, the listed Classic records and
Tier 4 exchanges have reliable acquisition coverage. Other tokens, vendors,
crafting, quests, restored Tier 3 and original removed drops need additional
curation. Unclassified sets are intentionally omitted from the raid catalog;
already saved goals are never deleted when data becomes unavailable. API labels
such as a tier name are not treated as proof of a raid source. Availability is
never inferred from a missing response. Source names follow the client language;
MogFocus explanations follow the selected Czech/English language.

Záznamy jsou ověřené proti zdrojovým datům, nikoliv vlastním lootením v aktuálním
klientu. Herní checklist požaduje kontrolu Classic, TBC, tokenové výměny a setu
z více raidů. Rozšiřování těchto dat je samostatná práce; neověřené vazby se nesmějí
doplňovat odhadem.
