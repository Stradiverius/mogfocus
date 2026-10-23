local count = 0
local function test(name, fn)
    fn(); count = count + 1; print("PASS " .. name)
end
local function eq(actual, expected) assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected)) end
local function reset()
    M.Store:Open({}, "Player-A")
    M.Collection.cache, M.Collection.expected, M.Collection.transitions, M.Collection.requested = {}, {}, {}, {}
    M.Collection.newParts = {}
    M.Collection.catalog, M.Collection.scanList, M.Collection.scanIndex = {}, nil, 0
    M.Sources:Clear()
    mockSets, mockSources, mockDrops, mockAlternatives = {}, {}, {}, {}
end
local function fixture(id, complete)
    local info = { setID = id, name = "Real API-shaped set", description = id == 10 and "Normal" or "Heroic", expansionID = 0,
        classMask = 1, collected = complete or false, label = "Tier" }
    mockSets[id] = { info = info, primary = { { appearanceID = 100, collected = complete or false }, { appearanceID = 101, collected = true } } }
    mockSources[100] = { sourceID = 100, itemID = 16800, visualID = 1, invType = 1, categoryID = 1, sourceType = 1, isValidSourceForPlayer = true }
    mockSources[101] = { sourceID = 101, itemID = 16795, visualID = 2, invType = 5, categoryID = 5, sourceType = 1, isValidSourceForPlayer = true }
    return info
end

test("GUID profiles, defaults and independent variants", function()
    reset()
    local db = M.Store.db
    eq(M.Store.settings.language, "cs"); eq(M.Store.settings.sound, false); eq(M.Store.settings.skin, "Warcraft")
    M.Store:Add(fixture(10)); M.Store:Add(fixture(11))
    eq(M.Store:Add(mockSets[10].info), false); eq(#M.Store.profile.targets, 2)
    M.Store.profile.pinned, M.Store.profile.focus = 11, 1
    M.Store:Move(11, -1); eq(M.Store.profile.targets[1], 11)
    M.Store:Open(db, "Player-B"); eq(#M.Store.profile.targets, 0); eq(M.Store.profile.focus, 0)
    M.Store.settings.skin = "Arcane"
    M.Store:Open(db, "Player-A"); eq(#M.Store.profile.targets, 2); eq(M.Store.profile.pinned, 11); eq(M.Store.profile.focus, 1)
    eq(M.Store.settings.skin, "Arcane")
    M.Store:Remove(11); eq(#M.Store.profile.targets, 1); eq(M.Store.profile.pinned, nil)
end)

test("additive migrations and future-schema preservation", function()
    local db = { schema = 1, extra = "keep", settings = { language = "en" }, characters = {
        A = { selectedSets = { 10, 10, "11", -5 }, focus = 1, custom = 7 },
    } }
    assert(M.Store:Open(db, "A")); eq(db.extra, "keep"); eq(M.Store.profile.custom, 7)
    eq(#M.Store.profile.targets, 2); eq(db.characters.A.selectedSets[3], "11"); eq(db.settings.language, "en")
    assert(M.Store:Open(db, "A")); eq(#M.Store.profile.targets, 2)
    local future = { schema = 99, payload = { 1, 2 } }
    local opened, err = M.Store:Open(future, "A")
    eq(opened, nil); eq(err, "NEWER_SCHEMA"); eq(future.schema, 99); eq(future.profiles, nil)
end)

test("SavedVariables-shaped serialization and reload preserve goals and preferences", function()
    reset(); M.Store:Add(fixture(10)); M.Store:Add(fixture(11))
    M.Store.profile.focus, M.Store.profile.pinned, M.Store.settings.language = 1, 11, "en"
    local function serialize(value)
        if type(value) == "string" then return string.format("%q", value) end
        if type(value) ~= "table" then return tostring(value) end
        local fields = {}
        for key, child in pairs(value) do fields[#fields + 1] = "[" .. serialize(key) .. "]=" .. serialize(child) end
        return "{" .. table.concat(fields, ",") .. "}"
    end
    local reloaded = assert(loadstring("return " .. serialize(M.Store.db)))()
    assert(M.Store:Open(reloaded, "Player-A"))
    eq(#M.Store.profile.targets, 2); eq(M.Store.profile.pinned, 11); eq(M.Store.profile.focus, 1)
    eq(M.Store.settings.language, "en"); eq(M.Store.profile.meta[11].expansionID, 0)
end)

test("primary source IDs versus visual IDs; deduplicated appearance counts", function()
    reset(); fixture(10)
    mockSources[102] = { sourceID = 102, itemID = 999, visualID = 2, invType = 5 }
    table.insert(mockSets[10].primary, { appearanceID = 102, collected = true })
    local set = M.Collection:Read(10)
    eq(set.status, "ready"); eq(set.total, 2); eq(set.collected, 1); eq(set.complete, false)
    eq(set.pieces[1].sourceID, 100); eq(set.pieces[1].visualID, 1)
end)

test("nil, empty, malformed and partial API responses never become zero progress", function()
    reset(); fixture(10)
    local function pending()
        M.Collection:Invalidate(); local set = M.Collection:Read(10)
        assert(set.status ~= "ready"); eq(set.total, nil); eq(set.complete, nil)
    end
    mockSets[10].primary = nil; pending()
    mockSets[10].primary = {}; pending()
    fixture(10); mockSources[100] = nil; pending()
    fixture(10); mockSets[10].primary[1].collected = nil; pending()
    fixture(10); M.Collection:Invalidate(); eq(M.Collection:Read(10).total, 2)
    table.remove(mockSets[10].primary, 1); pending()
    mockSets[10] = nil; pending()
end)

test("inconsistent complete flags cannot generate a false completion", function()
    reset(); fixture(10)
    mockSets[10].primary[1].collected = true
    eq(M.Collection:Read(10).status, "loading")
    M.Collection:Invalidate(); mockSets[10].info.collected = true
    eq(M.Collection:Read(10).complete, true)
end)

test("selected-only summaries, empty selections and unavailable IDs", function()
    reset(); M.Store:Add(fixture(10)); M.Store:Add(fixture(11, true))
    eq(M.Collection:Summary({}).percent, nil); eq(M.Collection:Summary({}).done, false)
    local summary = M.Collection:Summary(M.Collection:Selected(0))
    eq(summary.total, 2); eq(summary.complete, 1); eq(summary.percent, 75)
    M.Collection:Invalidate(); mockSets[10] = nil
    summary = M.Collection:Summary(M.Collection:Selected(0))
    eq(summary.percent, nil); eq(summary.pending, 1); eq(M.Store.profile.targets[1], 10)
    M.Store.profile.focus = 0; M.Collection:Selected(1); eq(M.Store.profile.focus, 0)
end)

test("completion notification baseline, transitions, reload and deduplication", function()
    reset(); fixture(10, true)
    local notifications = 0
    local function observe() M.Collection:Observe(M.Collection:Read(10), function() notifications = notifications + 1 end) end
    observe(); observe(); eq(notifications, 0)
    fixture(10); M.Collection:Invalidate(); observe()
    mockSources[100] = nil; M.Collection:Invalidate(); observe(); eq(notifications, 0)
    fixture(10, true); M.Collection:Invalidate(); observe(); observe(); eq(notifications, 1)
    M.Collection.transitions = {}; observe(); eq(notifications, 1)
    fixture(10); M.Collection:Invalidate(); observe()
    fixture(10, true); M.Collection:Invalidate(); observe(); eq(notifications, 1)
    eq(M.Collection.newParts[1] > GetTime(), true)
end)

test("raid grouping deduplicates across sets and alternative sources", function()
    reset(); M.Store:Add(fixture(10)); M.Store:Add(fixture(11))
    mockSources[103] = { sourceID = 103, itemID = 29071, visualID = 1, sourceType = 1, isValidSourceForPlayer = true }
    -- Use a second API route in the same raid, plus another raid alternative.
    mockAlternatives[1] = { { sourceID = 104, itemID = 999, visualID = 1, sourceType = 1, isValidSourceForPlayer = true } }
    mockDrops[104] = { { instance = "Molten Core", encounter = "Other boss", instanceType = 2, difficulties = { "Normal" } },
        { instance = "Other Raid", encounter = "Other boss", instanceType = 2, difficulties = {} } }
    local groups = M.Sources:Group(M.Collection:Selected(0))
    eq(#groups, 2); eq(groups[1].count, 1); eq(groups[2].count, 1)
    eq(#groups[1].rows[1].routes, 2); eq(#groups[2].rows[1].routes, 1)
    eq(groups[1].rows[1].sets[10], mockSets[10].info.name); eq(groups[1].rows[1].sets[11], mockSets[11].info.name)
end)

test("verified current Tier 4 token chain and localized labels", function()
    reset()
    local routes = M.Sources:ForSource({ sourceID = 500, itemID = 29071 }, 1)
    eq(#routes, 1); eq(routes[1].tokenID, 29754); eq(routes[1].instanceID, 747); eq(routes[1].encounterID, 1566)
    eq(routes[1].method, "TOKEN"); assert(M.Sources:Text(routes[1]):find("Shattrath City", 1, true))
    eq(#M.Sources:ForSource({ sourceID = 500, itemID = 29071 }, 0), 0)
    eq(M.SourceData.items[16955][1].instanceID, 742) -- Original Onyxia helm now Nefarian.
end)

test("catalog admits raid primaries, separates variant IDs and excludes PvP/unknown", function()
    reset(); fixture(10); fixture(11)
    mockSets[12] = { info = { setID = 12, name = "PvP", expansionID = 0, classMask = 1, collected = false },
        primary = { { appearanceID = 199, collected = false } } }
    mockSources[199] = { sourceID = 199, itemID = 99999, visualID = 99, invType = 1, sourceType = 9 }
    while M.Collection:ScanCatalogBatch() do end
    assert(M.Collection.catalog[10]); assert(M.Collection.catalog[11]); eq(M.Collection.catalog[12], nil)
end)

test("full TOC startup and UI wiring in both languages and all skins (mock only)", function()
    reset(); MogFocusDB = {}; M.ready = false; M:Initialize(); assert(M.ready)
    eq(#M.Store.profile.targets, 0)
    M.UI:Toggle(); assert(M.UI.frame:IsShown())
    M.Store:Add(fixture(10)); M.Store:Add(fixture(11)); M:Refresh(true)
    for _, language in ipairs({ "cs", "en" }) do
        M.Options:Changed("language", language)
        for _, skin in ipairs({ "Warcraft", "Obsidian", "Arcane" }) do
            M.Options:Changed("skin", skin)
            for _, sort in ipairs({ "custom", "progress", "raid" }) do
                M.Store.settings.sort = sort; M.UI.view = "sets"; M.UI:Render()
            end
            M.UI.view = "catalog"; while M.Collection:ScanCatalogBatch() do end; M.UI:Render()
            M.UI:FilterMenu("CLASS"); M.UI:FilterMenu("RAID"); M.UI:FilterMenu("VARIANT")
            M.UI.view = "where"; M.UI.expanded["Molten Core"] = true; M.UI:Render()
            M.Options:Changelog(); eq(M.Store.db.readVersion, M.version)
        end
    end
    M.Options:Open(); eq(mockCategory, 77)
    mockCombat = true; M.UI:Toggle(); assert(M.UI.frame:IsShown()); mockCombat = false
    WardrobeCollectionFrame = CreateFrame("Frame", nil, UIParent)
    M.Integration:Wardrobe(); assert(M.Integration.wardrobe)
    assert(M.Integration.minimap); M.Integration.minimap.scripts.OnEnter(M.Integration.minimap)
    M:Debug(); SlashCmdList.MOGFOCUS("options")
end)

test("event coalescing, bounded pending retries and hidden-window cancellation", function()
    local eventFrame
    for _, frame in ipairs(mockFrames) do if frame.events.PLAYER_LOGIN then eventFrame = frame end end
    assert(eventFrame)
    mockTimers = {}
    eventFrame.scripts.OnEvent(eventFrame, "TRANSMOG_COLLECTION_SOURCE_ADDED", 100)
    eventFrame.scripts.OnEvent(eventFrame, "TRANSMOG_COLLECTION_UPDATED")
    eq(#mockTimers, 1)
    local callback = table.remove(mockTimers, 1); callback()
    mockTimers = {}
    mockSets[10].primary = nil
    M:Refresh(true); eq(#mockTimers, 1)
    for _ = 1, 4 do
        local retry = table.remove(mockTimers, 1); assert(retry); retry()
    end
    eq(#mockTimers, 0); eq(M.Collection:Read(10).status, "loading")
    M:Refresh(true); eq(#mockTimers, 1)
    M.UI.frame:Hide()
    table.remove(mockTimers, 1)(); eq(#mockTimers, 0)
    eventFrame.scripts.OnEvent(eventFrame, "ITEM_DATA_LOAD_RESULT", 99999, true)
    eq(#mockTimers, 0)
end)

print(string.format("%d behavior tests completed (mock environment; not in-game testing)", count))
