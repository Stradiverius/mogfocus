# API verification / ověření API

Target / cíl: **WoW Retail 12.1.5.70575**, TOC Interface **120105**.
Latest review / poslední kontrola: **2026-10-31** (0.3.0 preview/UI and Collections isolation below).

The original 0.2.x contracts were inspected on 2026-10-23 in the `live` branch of
[Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), build 12.1.5.70529, at commit
[`e7aa82019dc298e0351c7159d60c2a9b916b9b67`](https://github.com/Gethe/wow-ui-source/tree/e7aa82019dc298e0351c7159d60c2a9b916b9b67).
`version.txt` identifies the build. The interface code is derived from that
version (12 * 10000 + 1 * 100 + 5). No running WoW client was available.

Kontrola vychází ze zdrojového kódu této konkrétní verze, nikoliv z běžící hry.
Vlastnosti vykreslení, bezpečnost v boji a skutečná data účtu vyžadují herní test.

Paths in the original table below are relative to `Interface/AddOns/` in that commit.
The 0.3.0 section records the new build and the preview contracts checked again.

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

## Collections, menu and catalog contracts

The menu/catalog contracts were checked against the original pinned commit on
2026-10-23. Collections tab handling was replaced in 0.3.0 after the blocked-toy
report, using the 70575 source commit identified below.

- `Blizzard_Collections/Mainline/Blizzard_Collections.xml`: the bottom main tabs
  use `CollectionsJournalTab` / `PanelTabButtonTemplate`. The Campsites tab is
  `CollectionsJournal.WarbandScenesTab`; its numeric ID is not assumed. MogFocus
  places an independent tab directly after Campsites, without allocating a native
  ID or registering it with CollectionsJournal. It retains native visual states
  and width fitting. The template is parented to a private host because its
  `parentArray="Tabs"` would otherwise modify the journal's registry implicitly.
- `Mainline/Blizzard_Collections.lua`: `CollectionsJournal_UpdateSelectedTab` hides
  native pages for other IDs and emits `CollectionsJournal.TabSet(journal, id)`.
  MogFocus uses `EventRegistry:RegisterCallback` only to close its own content
  when a native tab is selected. It never calls the native tab setter or writes
  `selectedTab`, `numTabs`, `Tabs` or `petJournalTab`. Its opaque, mouse-enabled
  content covers the existing page without hiding/showing or updating that page.
  Slash/minimap open the journal through `securecallfunction(ShowUIPanel, journal)`
  and activate the private view; closing restores only native tab/title visuals.
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

## 0.3.0 preview and appearance contracts

Inspected on **2026-10-29** at
[`15881d522c44cd106d3d8660106ec9f9d2f44167`](https://github.com/Gethe/wow-ui-source/tree/15881d522c44cd106d3d8660106ec9f9d2f44167),
`live` build **12.1.5.70575**. Interface remains **120105**. Paths below are relative
to `Interface/AddOns/` in this new commit.

| File | Contract used by Preview.lua / Skins.lua |
| --- | --- |
| `Blizzard_APIDocumentationGenerated/FrameAPIDressUpModelDocumentation.lua` | `SetUnit("player", false, useNativeForm)` returns readiness. `TryOn(linkOrItemModifiedAppearanceID)` accepts the numeric source ID and returns a nullable `ItemTryOnReason`. `IsGeoReady()` describes character appearance geometry and is checked **after** dressing; gating the first TryOn on it can stall loading. `GetItemTransmogInfoList()` reads the current outfit. Auto-dressing, transmog-choice and hidden-transmog flags are disabled only on the addon's own models. |
| `Blizzard_APIDocumentationGenerated/UIModelInfoSharedDocumentation.lua` | `Enum.ItemTryOnReason`: Success = 0, WrongRace = 1, NotEquippable = 2, DataPending = 3. Nil/unknown responses remain pending, never assumed successful. |
| `Blizzard_APIDocumentationGenerated/FrameAPICharacterModelBaseDocumentation.lua`, `SimpleModelAPIDocumentation.lua` | Inherited `SetRotation(radians, animate)`, `SetPortraitZoom`, `GetModelFileID`, `SetLight` and camera/model methods exist for DressUpModel. SetRotation and IsGeoReady were valid before this fix; they were not removed APIs. |
| `Blizzard_Collections/Shared/Blizzard_Wardrobe_Sets.lua`, `.xml`; `Blizzard_UIPanels_Game/Mainline/DressUpFrames.lua` | Blizzard passes primary set source IDs to TryOn, uses `IsUnitModelReadyForUI("player")`, and reads `appearanceID` / `secondaryAppearanceID` from model outfit structs. Native model lighting uses vector/color objects. The wardrobe XML includes the `GarrMission-AbilityHighlight` atlas used for the stage halo. |
| `Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua`, `SimpleFontStringAPIDocumentation.lua` | Native `SetGradient(orientation, minColor, maxColor)` accepts ColorMixin values. Private title FontStrings support `SetMaxLines`; long headings are bounded to preserve controls. |

Both inline and popup previews use the same controller. It sets the player model,
waits for unit/model data, reads the exact variant's **complete primary list**, and
undresses once per selection/source-list change. It retries only unsuccessful
parts, preserves successful appearances, checks outfit readback after late model
loads and handles UNIT_MODEL_CHANGED. It makes one attempt plus at most eight
timed retries (.1, .2, .4, .6, 1, 1.5, 2, 3 seconds). Hiding or changing the set
invalidates old callbacks. OnUpdate is used only while dragging the model.
An exception always releases the dressing guard and is retained in debug output.

Collection counts and source-route completeness never block an otherwise available
preview; the Missing only setting filters the parts list, not the outfit. Wrong-race
or unequippable parts produce a partial status. Exhausted loading has an explicit
manual retry. Opening the popup does not mutate saved goals, expansion focus or
the user's actual transmog. Only Add/Remove performs the selected tracking action.

The screenshot establishes that the old model displayed without the set; it does
not establish the exact in-game failure. The fix addresses observable one-shot
loading and failure-handling defects, validated with controlled API responses.
Actual geometry, appearance on different races/forms and event timing still need
the in-game checks in TESTING.md.

### Native action isolation after the blocked Hearthstone report

The same 70575 commit exposes this possible taint route: `PanelTemplates_SetTab`
writes `selectedTab`, and `PanelTemplates_SetNumTabs` writes `numTabs`.
`CollectionsJournal_UpdateSelectedTab` reads that state and shows ToyBox;
`ToyBox_OnShow` calls `ToyBox_UpdateButtons`, which populates each button's
`itemID`. `ToySpellButton_OnClick` later passes that field to protected `UseToy`.
The user's screenshot names MogFocus but provides no full taint log, so this is
a source-supported risk route, not a proven trace of that exact click.

The 0.3.0 integration removes those addon writes/calls and the automatic native
parent-array insertion. The only native tab operations left are visual:
`PanelTemplates_SelectTab` / `DeselectTab` change textures, font anchors and
button enable state without assigning tab-selection fields. Deselecting the
previous native tab visually also leaves it clickable while MogFocus is open.
`TitledPanelMixin:SetTitle` changes only its FontString. Native page callbacks,
toy buttons and their actions are untouched. State and rollback live in the
addon namespace, with an opaque overlay preventing clicks through to the page.

Sources: `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua` and `.xml`,
`Blizzard_SharedXML/PortraitFrame.lua`, `Blizzard_Collections/Mainline/Blizzard_Collections.lua`,
`Blizzard_ToyBox.lua` and `.xml`. Regression tests guard the state-writer calls,
registry and native-page visibility. They do not emulate the game's taint engine;
successful toy use must still be confirmed after restarting/reloading the client.
