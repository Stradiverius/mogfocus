-- Regression checks for 0.2.0; native rendering still requires WoW.
local count = 0
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn) fn(); count = count + 1; print("PASS " .. name) end
local function reset()
    M.Store:Open({}, mockGUID)
    M.Collection.cache, M.Collection.expected, M.Collection.transitions = {}, {}, {}
    M.Collection.catalog, M.Collection.scanList, M.Collection.scanIndex = {}, nil, 0
    M.Collection.newParts, M.Collection.requested = {}, {}
    M.Sources:Clear()
    mockSets, mockSources, mockDrops, mockAlternatives = {}, {}, {}, {}
    M.UI.view, M.UI.expansion, M.UI.selected, M.UI.filters = "sets", 0, nil, {}
    C_TransmogSets.GetVariantSets = function() return {} end
    C_TransmogSets.GetBaseSets = C_TransmogSets.GetAllSets
end
local function set(id, expansion, mask)
    local info = { setID = id, name = "Set " .. id, expansionID = expansion or 0, classMask = mask or 1,
        description = "Variant " .. id, collected = false }
    mockSets[id] = { info = info, primary = { { appearanceID = id + 1000, collected = false } } }
    mockSources[id + 1000] = { sourceID = id + 1000, itemID = 16800, visualID = id, invType = 1, categoryID = 1, sourceType = 1 }
    return info
end

test("private fonts survive every skin, language, reused row, Settings and tooltip", function()
    reset(); M.Store:Add(set(201))
    if not M.UI.frame:IsShown() then M.UI:Toggle() end
    for _, language in ipairs({ "cs", "en" }) do
        M.Options:Changed("language", language)
        for _, skin in ipairs({ "Warcraft", "Obsidian", "Arcane" }) do
            M.Options:Changed("skin", skin); M.UI:Render(); M.UI:Render(); M.Options:Changelog()
            for widget, role in pairs(M.Skins.widgets) do
                if role == "title" or role == "text" then
                    assert(widget:GetFontObject().fontPath:find("DejaVuSans", 1, true))
                end
                if widget.caption then assert(widget.caption:GetFontObject().fontPath:find("DejaVuSans", 1, true)) end
            end
            eq(M.UI.frame.search:GetFontObject(), M.Fonts.objects.button)
            local tip = M.Fonts:Tooltip(); tip:ClearLines(); tip:AddLine(M.L("MISSING_ONLY")); M.Fonts:TooltipFonts(tip)
            eq(_G.MogFocusTooltipTextLeft1:GetFontObject(), M.Fonts.objects.text)
        end
    end
    eq(GameFontNormal.fontPath, nil); eq(GameFontHighlightSmall.fontPath, nil)
end)

test("catalog exact ID union, all classes/expansions, variants and hidden visibility", function()
    reset()
    local a, b, c, hidden, collected = set(301, 0, 1), set(302, 1, 2), set(303, 2, 0), set(304, 0, 1), set(305, 1, 2)
    hidden.hiddenUntilCollected = true
    collected.hiddenUntilCollected, collected.collected = true, true
    b.baseSetID, collected.baseSetID = 301, 301
    local all = C_TransmogSets.GetAllSets
    -- Variant 302 is available only through GetVariantSets; include duplicate replies.
    C_TransmogSets.GetAllSets = function() return { a, c, hidden, collected } end
    C_TransmogSets.GetVariantSets = function(id) if id == 301 then return { b, collected, b } end; return {} end
    C_TransmogSets.GetBaseSets = function() return { a, c } end
    local reads, read = 0, C_TransmogCollection.GetSourceInfo
    C_TransmogCollection.GetSourceInfo = function(id) reads = reads + 1; return read(id) end
    M.Collection:BeginCatalog()
    local expected = { [301] = true, [302] = true, [303] = true, [305] = true }
    local n = 0
    for id in pairs(M.Collection.catalog) do assert(expected[id]); n = n + 1 end
    eq(n, 4); eq(reads, 0); eq(#M.Store.profile.targets, 0)
    assert(M.Collection:MatchesClass(b, 2)); eq(M.Collection:MatchesClass(b, 1), false)
    assert(M.Collection:MatchesClass(c, 1)); assert(M.Collection:MatchesClass(b, 0))
    local total, missing = M.Collection:AuditCatalog(); eq(total, 4); eq(#missing, 0)
    while M.Collection:ScanCatalogBatch() do end
    eq(#M.Store.profile.targets, 0); assert(M.Collection.catalog[302]); eq(M.Collection.catalog[304], nil)
    C_TransmogSets.GetAllSets, C_TransmogCollection.GetSourceInfo = all, read
end)

test("catalog includes sets with missing parts before and after optional source enrichment", function()
    reset(); set(401); mockSets[401].primary = nil
    M.Collection:BeginCatalog(); assert(M.Collection.catalog[401]); eq(#M.Store.profile.targets, 0)
    while M.Collection:ScanCatalogBatch() do end
    assert(M.Collection.catalog[401]); eq(M.Collection.catalog[401].sourcesPending, true)
    M.UI.view = "catalog"; M.UI:Render(); assert(M.UI.catalog.count >= 1)
end)

test("Collections dynamic tab, Campsites placement, page restoration and single instance", function()
    reset()
    local j, tab = CollectionsJournal, M.Integration.tab
    assert(tab:GetID() > 7) -- Another addon already owned tab 7 before MogFocus loaded.
    eq(tab.points[1][2], j.WarbandScenesTab)
    eq(CollectionsJournalTab7.points[1][2], tab)
    local frames, registrations = #mockFrames, Menu.registrationCount
    M.Integration:Collections(); M.Integration:Collections()
    eq(#mockFrames, frames); eq(Menu.registrationCount, registrations)
    local lateID = j.numTabs + 1
    local late = CreateFrame("Button", j:GetName() .. "Tab" .. lateID, j, "CollectionsJournalTab"); late:SetID(lateID)
    PanelTemplates_SetNumTabs(j, lateID)
    eq(tab.points[1][2], j.WarbandScenesTab); eq(CollectionsJournalTab7.points[1][2], tab)
    eq(late.points[1][2], CollectionsJournalTab7)
    CollectionsJournal_SetTab(j, tab:GetID()); assert(M.UI.frame:IsShown())
    eq(tab:GetFontString():GetFontObject(), M.Fonts.objects.tabSelected)
    eq(M.UI.frame.parent, M.Integration.content); eq(M.UI.layoutWidth, 687); eq(M.UI.layoutHeight, 538)
    assert(M.UI.detail:GetWidth() < M.UI.layoutWidth); assert(M.UI.parts.width > 100)
    eq(j.windowTitle, "MogFocus"); eq(mockCVars.petJournalTab, j.WardrobeTab:GetID())
    CollectionsJournal_SetTab(j, j.WardrobeTab:GetID())
    eq(tab:GetFontString():GetFontObject(), M.Fonts.objects.tabNormal)
    eq(M.UI.frame:IsShown(), false); assert(j.pages[5]:IsShown())
    CollectionsJournal_SetTab(j, 1); assert(j.pages[1]:IsShown()); eq(M.Integration.content:IsShown(), false)
    M.Integration:Open(); assert(M.UI.frame:IsShown()); eq(j.pages[1]:IsShown(), false)
    mockCombat = true; M.Integration:Open(); assert(M.UI.frame:IsShown()); mockCombat = false
    M.Integration:Open(); eq(j:IsShown(), false)
    M.Integration:Open(); assert(M.UI.frame:IsShown())
    j:SetSize(900, 700); M.UI:Layout(); eq(M.UI.layoutWidth, 884)
    j:SetSize(703, 606); M.UI:Layout()
end)

local function mogMenu(owner)
    local root = NewMockMenu(); root:CreateButton("Blizzard favorite", function() mockOriginal = true end)
    Menu.callbacks.MENU_WARDROBE_SETS_SET(owner, root)
    eq(root.children[1].label, "Blizzard favorite")
    return root
end

test("context menu exact clicked IDs after row reuse, duplicates, remove and profile isolation", function()
    reset(); set(501); set(502)
    M.Store.profile.focus = 1
    local owner = { setID = 501 }
    local menu = mogMenu(owner)
    eq(menu.children[3].label, M.L("ADD_TO"))
    -- Blizzard recycles this owner for another row while an old menu is pending.
    owner.setID = 502; menu.children[3].action()
    assert(M.Store:Contains(501)); eq(M.Store:Contains(502), false)
    eq(M.Store.profile.focus, 1); eq(M.noticeKey, "TRACK_ADDED")
    menu.children[3].action(); eq(#M.Store.profile.targets, 1)
    menu = mogMenu(owner); menu.children[3].action(); assert(M.Store:Contains(502))
    menu = mogMenu(owner); eq(menu.children[3].label, M.L("ALREADY_TRACKED")); eq(menu.children[4].label, M.L("REMOVE_FROM"))
    menu.children[4].action(); eq(M.Store:Contains(502), false); assert(M.Store:Contains(501))
    local db = M.Store.db; M.Store:Open(db, "Other-GUID"); eq(#M.Store.profile.targets, 0)
    M.Store:Open(db, mockGUID); eq(#M.Store.profile.targets, 1)
end)

test("group context menu chooses a single visible variant and uses Czech-capable fonts", function()
    reset(); M.Store.settings.language = "cs"
    local base, variant = set(601), set(602)
    variant.baseSetID = 601
    C_TransmogSets.GetVariantSets = function(id) return id == 601 and { variant } or {} end
    local menu = mogMenu({ setID = 601 })
    eq(#M.Store.profile.targets, 0)
    local submenu = menu.children[3]; eq(#submenu.children, 2)
    local choose = submenu.children[2].children[1]
    eq(choose.label, "Přidat do MogFocus")
    local button = { fontString = CreateFrame("FontString") }
    choose.initializers[1](button); eq(button.fontString:GetFontObject(), M.Fonts.objects.menu)
    choose.action(); eq(#M.Store.profile.targets, 1); eq(M.Store.profile.targets[1], 602)
    eq(M.Store.profile.focus, 0)
    -- Menu generation does not change the original action or Blizzard globals.
    menu.children[1].action(); assert(mockOriginal)
end)

test("0.1.0 upgrade retains ordered goals, settings and notification history", function()
    reset()
    local db = { schema = 2, settings = { language = "cs", skin = "Arcane", sort = "custom", sound = true },
        readVersion = "0.1.0", profiles = { [mockGUID] = { targets = { 11, 10 }, focus = 1, pinned = 11,
            meta = { [11] = { expansionID = 1 }, [10] = { expansionID = 0 } }, notified = { [11] = true } } } }
    assert(M.Store:Open(db, mockGUID))
    M.Collection:BeginCatalog()
    eq(M.Store.profile.targets[1], 11); eq(M.Store.profile.targets[2], 10)
    eq(M.Store.profile.focus, 1); eq(M.Store.profile.pinned, 11); eq(M.Store.settings.skin, "Arcane")
    eq(M.Store.settings.sound, true); eq(M.Store.profile.notified[11], true); eq(db.readVersion, "0.1.0")
end)

print(count .. " update regression tests completed (mock environment; not in-game testing)")
