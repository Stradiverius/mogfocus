-- Realistic asynchronous dressing outcomes; no actual 3D rendering is simulated.
local count = 0
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn) fn(); count = count + 1; print("PASS preview: " .. name) end
local function drain()
    local n = 0
    while #mockTimers > 0 do
        n = n + 1; assert(n < 60, "Unbounded preview retry")
        table.remove(mockTimers, 1)()
    end
end
local function fixture(id, sources)
    local info = { setID = id, name = "Set " .. id, expansionID = 0, classMask = 1, collected = false, description = "Mythic" }
    mockSets[id] = { info = info, primary = {} }
    for index, source in ipairs(sources) do
        mockSets[id].primary[#mockSets[id].primary + 1] = { appearanceID = source, collected = index == 1 }
        mockSources[source] = { sourceID = source, itemID = source + 9000, visualID = source + 1000, invType = index, sourceType = 1 }
    end
    return info
end
local function reset()
    if M.Preview.window then M.Preview.window:Hide() end
    if M.UI.frame then M.UI.frame:Hide() end
    mockTimers, mockSets, mockSources = {}, {}, {}
    mockTryOnError, mockTryOnNil, mockTryOnReasons = nil, nil, nil
    mockUnitReady, mockGeoReady, mockSetUnitFailure, mockModelFileID, mockCombat = true, true, false, nil, false
    M.Collection:Invalidate(); M.Collection.catalog, M.Collection.scanList, M.Collection.requested = {}, nil, {}
    M.Store:Open({}, mockGUID)
    M.UI.expansion, M.UI.filters, M.UI.view, M.UI.selected = 0, {}, "sets", nil
    local note = M.UI:Text(UIParent, "")
    return M.Preview:Create(UIParent, note)
end

test("complete exact variant includes collected parts despite missing-only filter", function()
    local model = reset(); fixture(101, { 501, 502, 503 })
    M.Store.settings.missingOnly = true
    M.Preview:Select(model, 101)
    eq(model.mogPreview.status, "ready"); eq(model.unit, "player"); eq(model.nativeForm, true)
    assert(model.worn[501] and model.worn[502] and model.worn[503] and not model.worn[9501])
    eq(model.undressCalls, 1); eq(model.tryOnCalls, 3)
    M.Preview:Select(model, 101); eq(model.tryOnCalls, 3)
    eq(model.portraitZoom, 0); eq(#M.Store.profile.targets, 0)
end)

test("DataPending retries only missing dress operations and keeps successful pieces", function()
    local model = reset(); fixture(101, { 501, 502, 503 })
    mockTryOnReasons = { [502] = Enum.ItemTryOnReason.DataPending, [503] = Enum.ItemTryOnReason.DataPending }
    M.Preview:Select(model, 101)
    eq(model.mogPreview.status, "loading"); assert(model.worn[501] and not model.worn[502]); eq(#mockTimers, 1)
    mockTryOnReasons = nil; drain()
    eq(model.mogPreview.status, "ready"); assert(model.worn[502] and model.worn[503])
    eq(model.undressCalls, 1); eq(model.sourceCalls[501], 1); eq(model.sourceCalls[502], 2)
end)

test("delayed character and model file readiness do not prematurely undress", function()
    local model = reset(); fixture(101, { 501, 502 })
    mockUnitReady = false; mockModelFileID = 0
    M.Preview:Select(model, 101); eq(model.tryOnCalls, nil); eq(model.undressCalls, nil)
    mockUnitReady = true; model.modelFileID = 12345; drain()
    eq(model.mogPreview.status, "ready"); eq(model.setUnitCalls, 1)
end)

test("geometry readiness is checked after dressing, never used to block first TryOn", function()
    local model = reset(); fixture(101, { 501, 502 }); mockGeoReady = false
    M.Preview:Select(model, 101)
    eq(model.mogPreview.status, "loading"); assert(model.worn[501] and model.worn[502])
    mockGeoReady = true; drain(); eq(model.mogPreview.status, "ready"); eq(model.undressCalls, 1)
end)

test("unavailable data has bounded retries and explicit manual recovery", function()
    local model = reset(); fixture(101, { 501, 502 }); mockTryOnNil = true
    M.Preview:Select(model, 101); drain()
    eq(model.mogPreview.status, "unavailable"); eq(model.mogPreview.attempts, 9)
    eq(model.alpha, 0); eq(model.mogPreview.note:GetText(), M.L("PREVIEW_RETRY_HINT"))
    mockTryOnNil = false; M.Preview:Retry(model); eq(model.mogPreview.status, "ready")
end)

test("API exceptions release the application guard and can recover", function()
    local model = reset(); fixture(101, { 501, 502 }); mockTryOnError = true
    M.Preview:Select(model, 101); eq(model.mogPreview.running, nil); assert(M.Preview.lastError)
    mockTryOnError = false; drain(); eq(model.mogPreview.status, "ready")
end)

test("late model load restores lost appearances without an undress loop", function()
    local model = reset(); fixture(101, { 501, 502 }); M.Preview:Select(model, 101)
    model.worn[502] = nil; model.scripts.OnModelLoaded(model); drain()
    eq(model.mogPreview.status, "ready"); assert(model.worn[502]); eq(model.sourceCalls[501], 1)
    eq(model.undressCalls, 1)
    model.scripts.OnModelLoaded(model); eq(#mockTimers, 0)
end)

test("stale callbacks cannot dress a previously selected set", function()
    local model = reset(); fixture(101, { 501, 502 }); fixture(102, { 601, 602 })
    mockTryOnReasons = { [502] = Enum.ItemTryOnReason.DataPending }
    M.Preview:Select(model, 101); M.Preview:Select(model, 102); drain()
    assert(model.worn[601] and model.worn[602] and not model.worn[501] and not model.worn[502])
    eq(model.mogPreview.id, 102); eq(model.mogPreview.status, "ready")
end)

test("hiding cancels pending work; reopening and model changes restore the set", function()
    local model = reset(); fixture(101, { 501, 502 }); mockSetUnitFailure = true
    M.Preview:Select(model, 101); model:Hide(); drain(); eq(model.tryOnCalls, nil)
    mockSetUnitFailure = false; model:Show(); eq(model.mogPreview.status, "ready")
    local before = model.setUnitCalls
    M.Preview:UnitChanged(); eq(model.setUnitCalls, before + 1); assert(model.worn[501])
    -- WoW IsShown remains true when an ancestor is hidden; only IsVisible
    -- answers whether this model can actually be seen.
    local parent = CreateFrame("Frame", nil, UIParent)
    local child = M.Preview:Create(parent)
    M.Preview:Select(child, 101); local dressed = child.setUnitCalls
    parent:Hide(); assert(child:IsShown() and not child:IsVisible())
    M.Preview:UnitChanged(); drain(); eq(child.setUnitCalls, dressed)
    assert(child.mogPreview.suspended)
    parent:Show(); child.scripts.OnShow(child); eq(child.setUnitCalls, dressed + 1)
end)

test("wrong-race or unequippable parts are reported as partial, never complete", function()
    local model = reset(); fixture(101, { 501, 502, 503 })
    mockTryOnReasons = { [502] = Enum.ItemTryOnReason.WrongRace, [503] = Enum.ItemTryOnReason.NotEquippable }
    M.Preview:Select(model, 101)
    eq(model.mogPreview.status, "partial"); eq(model.mogPreview.worn, 1); eq(model.mogPreview.total, 3)
    eq(model.mogPreview.note:GetText(), M.L("PREVIEW_PARTIAL", 1, 3)); eq(#mockTimers, 0)
end)

test("preview does not depend on complete source metadata or collection counts", function()
    local model = reset(); fixture(101, { 501, 502 }); mockSources[502] = nil
    eq(M.Collection:Read(101).status, "loading")
    M.Preview:Select(model, 101); eq(model.mogPreview.status, "ready"); assert(model.worn[502])
end)

test("catalog click opens a reusable player window without tracking or changing focus", function()
    reset(); fixture(101, { 501, 502 }); fixture(102, { 601, 602 })
    M.UI:Toggle(); M.UI.view = "catalog"; M.Collection:BeginCatalog(); M.UI:Render()
    local callback = M.UI.catalog.rows[1].scripts.OnClick
    callback()
    local f = M.Preview.window
    assert(f:IsShown() and f.model.worn[501] and f.model.worn[502]); eq(f.setID, 101)
    eq(M.UI.view, "catalog"); eq(#M.Store.profile.targets, 0); eq(M.Store.profile.focus, 0)
    f.track.scripts.OnClick(); assert(M.Store:Contains(101)); eq(#M.Store.profile.targets, 1)
    M.UI.catalog.rows[2].scripts.OnClick(); eq(M.Preview.window, f); eq(f.setID, 102)
    assert(f.model.worn[601] and not f.model.worn[501]); eq(#M.Store.profile.targets, 1)
    f.model.scripts.OnMouseWheel(f.model, 2); assert(f.model.portraitZoom > 0)
    f.reset.scripts.OnClick(); eq(f.model.portraitZoom, 0)
    f.close.scripts.OnClick(); assert(not f:IsShown() and M.UI.frame:IsShown())
    local frames = #mockFrames
    M.Preview:Open(101); eq(M.Preview.window, f); eq(#mockFrames, frames)
    local entries = 0; for _, name in ipairs(UISpecialFrames) do if name == "MogFocusPreviewFrame" then entries = entries + 1 end end
    eq(entries, 1)
    mockCombat = true; M.Preview:Open(102); eq(f.setID, 101); mockCombat = false
    for _, language in ipairs({ "cs", "en" }) do
        for _, skin in ipairs({ "Warcraft", "Obsidian", "Arcane" }) do
            M.Options:Changed("language", language); M.Options:Changed("skin", skin)
            eq(f.reset.caption:GetText(), M.L("RESET_VIEW"))
            for _, font in ipairs({ f.title, f.meta, f.character, f.note, f.track.caption }) do
                assert(font:GetFontObject().fontPath:find("DejaVuSans", 1, true))
            end
        end
    end
    f:Hide()
end)
print(count .. " preview regressions completed (mock environment, not a WoW client)")
