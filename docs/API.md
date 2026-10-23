# API verification / ověření API

Target / cíl: **WoW Retail 12.1.5.70529**, TOC Interface **120105**.
Inspection date / datum kontroly: **2026-10-23**.

The `live` branch of [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source)
was inspected at commit
[`e7aa82019dc298e0351c7159d60c2a9b916b9b67`](https://github.com/Gethe/wow-ui-source/tree/e7aa82019dc298e0351c7159d60c2a9b916b9b67).
`version.txt` identifies the build. The interface code is derived from that
version (12 * 10000 + 1 * 100 + 5). No running WoW client was available.

Kontrola vychází ze zdrojového kódu této konkrétní verze, nikoliv z běžící hry.
Vlastnosti vykreslení, bezpečnost v boji a skutečná data účtu vyžadují herní test.

Paths below are relative to `Interface/AddOns/` in that commit:

| File | Verified contract / ověřená vazba |
| --- | --- |
| `Blizzard_APIDocumentationGenerated/TransmogSetsDocumentation.lua` | `GetAllSets()`, `GetVariantSets(setID)`, `GetSetInfo(setID)`, `GetSetPrimaryAppearances(setID)`. Info contains `setID`, `baseSetID`, `description`, `label`, `expansionID`, `classMask`, `collected`, `validForCharacter`. No documented raid/PvP flag. |
| `Blizzard_TransmogShared/Blizzard_TransmogShared.lua` | `WardrobeSetsDataProviderMixin:GetSortedSetSources`: `primary.appearanceID` is passed to `C_TransmogCollection.GetSourceInfo` as a **sourceID**, despite its field name. Primary `collected` flags drive Blizzard set counts. |
| `Blizzard_APIDocumentationGenerated/AppearanceSourceDocumentation.lua` | Source struct distinguishes `visualID`, `sourceID`, `itemID`, `invType`, `categoryID`, `isCollected`, usability and `sourceType`. MogFocus deduplicates primary parts by `visualID`, while keeping the specific variant/source for preview and routes. |
| `Blizzard_APIDocumentationGenerated/TransmogItemsDocumentation.lua` | `GetSourceInfo(sourceID)`, `GetSourceIcon(sourceID)`, `GetAppearanceSources(visualID, categoryID?)`, `GetAppearanceSourceDrops(sourceID)`. Drop returns `instance`, `instanceType`, `tiers`, `encounter`, `difficulties`; **no journal IDs**. |
| `Blizzard_FrameXMLUtil/CollectionsUtil.lua` | Blizzard uses drop lookup for `TRANSMOG_SOURCE_BOSS_DROP` and `INSTANCE_TYPE_RAID` for raid metadata; MogFocus follows this classification instead of translated name matching. |
| `Blizzard_APIDocumentationGenerated/TransmogDocumentation.lua` | `TRANSMOG_COLLECTION_UPDATED`, `TRANSMOG_COLLECTION_SOURCE_ADDED`, `TRANSMOG_COLLECTION_SOURCE_REMOVED`, `TRANSMOG_COLLECTION_ITEM_UPDATE`, `TRANSMOG_SOURCE_COLLECTABILITY_UPDATE`. No invented `TRANSMOG_SETS_UPDATE` event. |
| `Blizzard_APIDocumentationGenerated/ItemDocumentation.lua` | `C_Item.GetItemInfo(itemID)`, `GetItemInfoInstant(itemID)`, `RequestLoadItemDataByID(itemID)`, `ITEM_DATA_LOAD_RESULT(itemID, success)`. Missing names do not change collection ownership. |
| `Blizzard_Collections/Blizzard_Collections_Mainline.toc`, `Mainline/Blizzard_Wardrobe.xml` | Load-on-demand addon `Blizzard_Collections`; `WardrobeCollectionFrame` and its `SetsTab`. MogFocus waits for `ADDON_LOADED`, adds its own button, and defers frame creation in combat. No overwrite, tab numbering change or insecure hook of protected behavior. |
| `Blizzard_Settings_Shared/Blizzard_ImplementationReadme.lua` | `Settings.RegisterCanvasLayoutCategory(frame, name)`, `Settings.RegisterAddOnCategory(category)`, `Settings.OpenToCategory(category:GetID())`. Native AddOns category with a custom canvas. |
| `Blizzard_APIDocumentationGenerated/FrameAPIDressUpModelDocumentation.lua` | `DressUpModel:Undress()`, `TryOn(linkOrItemModifiedAppearanceID)` on a **separate** model. Source IDs preserve exact appearance variant. Inherited player-model camera methods provide rotation and portrait zoom. |
| `Blizzard_EncounterJournal/Mainline/Blizzard_EncounterJournal.lua` | `EncounterJournal_OpenJournal(difficultyID, instanceID, encounterID, sectionID, creatureID, itemID, tierIndex)`. Used only for curated numeric mappings after `C_AddOns.LoadAddOn("Blizzard_EncounterJournal")`; never guessed from a boss name. |

Collection results remain loading when absent, empty, malformed, shorter than a
previous complete reply, or inconsistent with the set's authoritative `collected`
flag. First observations establish notification baselines. An unknown saved set
keeps its ID and expansion metadata. Item requests and collection events coalesce
at 250 ms; the visible catalog checks four sets per 60 ms tick and stops when hidden.
No complete collection scan runs on `OnUpdate`. Pending selected goals receive
at most four visible-window retries (0.5, 1, 2 and 4 seconds); hiding the tracker
stops that retry chain. Catalog rows are paged in batches of 50 to bound frame
creation, and live scan redraws are throttled to 400 ms.

Neúplná data se nezmění na falešné 0/N. První načtení pouze založí výchozí stav
oznámení. Zdroje se ověřují pro jednotlivé části, nikoliv odhadem podle názvu setu.
Jména z herního API se nepřekládají. Addon nikdy nepoužívá funkce pro aplikaci
transmogu, inventářové akce ani automatické hraní.
