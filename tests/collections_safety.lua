-- Structural isolation checks, not an emulator of WoW's secure/taint engine.
local count = 0
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn) fn(); count = count + 1; print("PASS Collections isolation: " .. name) end
local function forbiddenNativeWrites(fn)
    local originals = {}
    for _, name in ipairs({ "PanelTemplates_SetNumTabs", "PanelTemplates_SetTab", "CollectionsJournal_SetTab", "SetCVar" }) do
        originals[name] = _G[name]
        _G[name] = function() error("MogFocus called native state writer: " .. name) end
    end
    local ok, err = pcall(fn)
    for name, original in pairs(originals) do _G[name] = original end
    assert(ok, err)
end

test("private template parent preserves native Tabs array, counts, IDs and CVar", function()
    local j, i = CollectionsJournal, M.Integration
    CollectionsJournal_SetTab(j, 3); ShowUIPanel(j)
    local registry, registered, selected, cvar = j.Tabs, j.numTabs, j.selectedTab, mockCVars.petJournalTab
    local tabs = {}; for index, tab in ipairs(j.Tabs) do tabs[index] = tab end
    forbiddenNativeWrites(function()
        i:Collections(); i.tab.scripts.OnClick(); i:LayoutTab(); M.Options:Changed("skin", "Warcraft")
    end)
    eq(j.Tabs, registry); eq(#j.Tabs, #tabs); eq(j.numTabs, registered); eq(j.selectedTab, selected)
    eq(mockCVars.petJournalTab, cvar); eq(i.tabHost.Tabs[1], i.tab)
    for index, tab in ipairs(tabs) do eq(j.Tabs[index], tab); eq(tab:GetID(), index); assert(tab ~= i.tab) end
    assert(i.active and i.content:IsShown() and i.cover:IsShown())
end)

test("opening over Toys never hides, shows or updates toy pages or buttons", function()
    local j, i = CollectionsJournal, M.Integration
    CollectionsJournal_SetTab(j, 3)
    local toy = j.pages[3]
    toy.itemID = 54452 -- A fixture toy ID; never passed to any item-use API.
    local originalShow, originalHide, originalSet = toy.Show, toy.Hide, toy.SetShown
    toy.Show = function() error("Native ToyBox shown by addon") end
    toy.Hide = function() error("Native ToyBox hidden by addon") end
    toy.SetShown = function() error("Native ToyBox visibility changed by addon") end
    forbiddenNativeWrites(function() i.tab.scripts.OnClick(); M:Refresh(true); M.UI:Render() end)
    toy.Show, toy.Hide, toy.SetShown = originalShow, originalHide, originalSet
    assert(toy:IsShown()); eq(toy.itemID, 54452)
    -- The native active tab is visually enabled, so clicking it works too.
    eq(j.Tabs[3].enabled, true)
    CollectionsJournal_SetTab(j, 3)
    assert(not i.active and not i.content:IsShown() and not i.cover:IsShown())
    assert(toy:IsShown()); eq(toy.itemID, 54452)
end)

test("all native pages remain selectable after the custom page and close/reopen", function()
    local j, i = CollectionsJournal, M.Integration
    for id = 1, 6 do
        CollectionsJournal_SetTab(j, id)
        local cvar = mockCVars.petJournalTab
        forbiddenNativeWrites(function() i:Activate(); i:Open(); i:Open() end)
        eq(j.selectedTab, id); eq(mockCVars.petJournalTab, cvar)
        assert(i.active and M.UI.frame:IsShown())
        CollectionsJournal_SetTab(j, id)
        assert(j.pages[id]:IsShown() and not i.content:IsShown())
        eq(j.windowTitle, "Native " .. id)
    end
end)

test("combat refusal and repeated setup preserve native registry and private tab", function()
    local j, i = CollectionsJournal, M.Integration
    local tab, registry, n = i.tab, j.Tabs, j.numTabs
    CollectionsJournal_SetTab(j, 3)
    mockCombat = true; i:Activate(); assert(not i.active); mockCombat = false
    forbiddenNativeWrites(function()
        for _ = 1, 3 do i:Collections(); i:Activate(); i:Deactivate(true) end
    end)
    eq(i.tab, tab); eq(j.Tabs, registry); eq(j.numTabs, n); eq(#i.tabHost.Tabs, 1)
    eq(j.selectedTab, 3); eq(mockCVars.petJournalTab, 3)
    eq(j.windowTitle, "Native 3"); assert(j.pages[3]:IsShown())
end)
print(count .. " Collections isolation regressions completed (no live taint validation)")
