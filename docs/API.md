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
| `Blizzard_APIDocumentationGenerated/SimpleFontAPIDocumentation.lua`, `SimpleFontStringAPIDocumentation.lua` | `SimpleFont:SetFont(fontFile, height, flags)` has **no return values**. Only `FontString:SetFont` returns a success boolean. MogFocus checks `pcall` and the private FontObject's `GetFont()` result, with private inheritance from `GameFontNormal` on a real asset failure. `SetFontHeight` is documented for SimpleFont. Verified for the 0.2.1 fix. |
| `Blizzard_APIDocumentationGenerated/TransmogSetsDocumentation.lua` | `GetAllSets()`, `GetVariantSets(setID)`, `GetSetInfo(setID)`, `GetSetPrimaryAppearances(setID)`. Info contains `setID`, `baseSetID`, `description`, `label`, `expansionID`, `classMask`, `collected`, `validForCharacter`. No documented raid/PvP flag. |
| `Blizzard_TransmogShared/Blizzard_TransmogShared.lua` | `WardrobeSetsDataProviderMixin:GetSortedSetSources`: `primary.appearanceID` is passed to `C_TransmogCollection.GetSourceInfo` as a **sourceID**, despite its field name. Primary `collected` flags drive Blizzard set counts. |
| `Blizzard_APIDocumentationGenerated/AppearanceSourceDocumentation.lua` | Source struct distinguishes `visualID`, `sourceID`, `itemID`, `invType`, `categoryID`, `isCollected`, usability and `sourceType`. MogFocus deduplicates primary parts by `visualID`, while keeping the specific variant/source for preview and routes. |
| `Blizzard_APIDocumentationGenerated/TransmogItemsDocumentation.lua` | `GetSourceInfo(sourceID)`, `GetSourceIcon(sourceID)`, `GetAppearanceSources(visualID, categoryID?)`, `GetAppearanceSourceDrops(sourceID)`. Drop returns `instance`, `instanceType`, `tiers`, `encounter`, `difficulties`; **no journal IDs**. |
| `Blizzard_FrameXMLUtil/CollectionsUtil.lua` | Blizzard uses drop lookup for `TRANSMOG_SOURCE_BOSS_DROP` and `INSTANCE_TYPE_RAID` for raid metadata; MogFocus follows this classification instead of translated name matching. |
| `Blizzard_APIDocumentationGenerated/TransmogDocumentation.lua` | `TRANSMOG_COLLECTION_UPDATED`, `TRANSMOG_COLLECTION_SOURCE_ADDED`, `TRANSMOG_COLLECTION_SOURCE_REMOVED`, `TRANSMOG_COLLECTION_ITEM_UPDATE`, `TRANSMOG_SOURCE_COLLECTABILITY_UPDATE`. No invented `TRANSMOG_SETS_UPDATE` event. |
| `Blizzard_APIDocumentationGenerated/ItemDocumentation.lua` | `C_Item.GetItemInfo(itemID)`, `GetItemInfoInstant(itemID)`, `RequestLoadItemDataByID(itemID)`, `ITEM_DATA_LOAD_RESULT(itemID, success)`. Missing names do not change collection ownership. |
| `Blizzard_Collections/Blizzard_Collections_Mainline.toc`, `Mainline/Blizzard_Wardrobe.xml` | Load-on-demand addon `Blizzard_Collections`; `WardrobeCollectionFrame` and its `SetsTab`. MogFocus waits for `ADDON_LOADED` and defers frame creation in combat. Version 0.2.0 adds a main Collections tab; it does not modify the Wardrobe header or its internal tabs. |
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

## 0.2.0 integration contracts

The same pinned `live` commit was fetched again and verified on 2026-10-23.

- `Blizzard_Collections/Mainline/Blizzard_Collections.xml`: the bottom main tabs
  use `CollectionsJournalTab` / `PanelTabButtonTemplate`. The Campsites tab is
  `CollectionsJournal.WarbandScenesTab`; its numeric ID is not assumed. MogFocus
  allocates an unused ID after the registered tab count and places its tab directly
  after Campsites, ahead of other appended tabs. It uses the native selected/disabled
  states and native width fitting. Secure post-hooks maintain anchors/fonts after
  native tab layout. Existing page functions are never overwritten.
- `Mainline/Blizzard_Collections.lua`: `CollectionsJournal_UpdateSelectedTab` hides
  native pages for other IDs and emits `CollectionsJournal.TabSet(journal, id)`.
  MogFocus uses `EventRegistry:RegisterCallback` to toggle its content. Native
  page restoration remains Blizzard's responsibility. It restores the native
  Wardrobe ID in `petJournalTab` while its own tab is active, avoiding a stale
  addon-dependent tab ID at next login. Slash/minimap use `ShowUIPanel` and
  `CollectionsJournal_SetTab`; all entries target the same tracker.
- `Shared/Blizzard_Wardrobe_Sets.lua`, `WardrobeSetsScrollFrameButtonMixin:OnClick`:
  right-click uses `MenuUtil.CreateContextMenu(self, ...)` with tag
  `MENU_WARDROBE_SETS_SET`. The owner has the CURRENT recycled row's base `setID`.
  `Menu.ModifyMenu` appends actions; no row OnClick or Blizzard favorite action is
  replaced. Snapshot numeric IDs when the menu opens. A group requires explicit
  variant selection instead of using an unrelated globally selected detail set.
- `Blizzard_TransmogShared/Blizzard_TransmogShared.lua`: the provider adds the base
  set to `C_TransmogSets.GetVariantSets(baseID)`. MogFocus does the same, deduplicates
  real IDs and respects `hiddenUntilCollected` / `collected`. Blizzard comments
  explicitly state that variant replies are already filtered for hidden visibility.
  `GetAllSets()` builds the cross-class catalog without mutating Blizzard's class,
  search, PvE/PvP or collected filters. `classMask` drives the local class filter;
  `validForCharacter` is not used to discard another class's sets. Raid lookup
  is asynchronous optional enrichment, never an admission test.
- `/mogfocus catalogcheck` compares the catalog with `GetBaseSets()` plus variants
  under CURRENT native filters. This is a real ID audit when run in WoW; the
  build environment verifies the comparison algorithm with fixtures, not live data.
- `Blizzard_Menu/11_0_0_MenuImplementationGuide.lua`: `Menu.ModifyMenu`,
  `description:AddInitializer`, and `button.fontString:SetFontObject` are supported
  extension points. Only MogFocus-created menu descriptions receive private fonts.
- `Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua`:
  `TooltipDataProcessor.AddTooltipPostCall(AllTypes, callback)` reapplies fonts after
  asynchronous data processing, guarded to the PRIVATE MogFocus tooltip only.

Rozhraní používá nativní záložku a původní herní nabídku, bez přepsání jejich
obsluhy. Testy mimo hru nenahrazují kontrolu taintu, vykreslení, skutečné viditelnosti
a úplnosti setů na účtu. Postup pro ověření je v TESTING.md.
