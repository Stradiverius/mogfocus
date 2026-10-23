-- Each scenario runs in a fresh Lua 5.1 VM, with the actual TOC load order.
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local eventFrame
for _, frame in ipairs(mockFrames) do if frame.events.PLAYER_LOGIN then eventFrame = frame end end
assert(eventFrame)
local function fire(event, arg) eventFrame.scripts.OnEvent(eventFrame, event, arg) end
local function collections()
    CreateMockCollections(1)
    fire("ADDON_LOADED", "Blizzard_Collections")
end
local function login()
    mockLoggedIn = true
    fire("PLAYER_LOGIN")
end

local empty = mockStartupScenario == "empty_profile" or mockStartupScenario == "missing_font"
local saved = {
    schema = 2, readVersion = "0.2.0", custom = "keep",
    settings = { language = "cs", skin = "Arcane", minimap = true, minimapAngle = 41, sound = false },
    profiles = {
        [mockGUID] = { targets = empty and {} or { 501 }, focus = 0, pinned = empty and nil or 501,
            meta = { [501] = { expansionID = 0 } }, notified = { [502] = true }, custom = "keep" },
        Other = { targets = { 999 }, focus = 1, pinned = 999, notified = { [999] = true } },
    },
}
MogFocusDB = saved
mockSets[501] = { info = { setID = 501, name = "Testovací set", expansionID = 0, classMask = 1, collected = false },
    primary = { { appearanceID = 601, collected = false } } }
mockSources[601] = { sourceID = 601, itemID = 16800, visualID = 701, invType = 1, sourceType = 1 }

local notices = 0
local printMessage = DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage = function(self, message)
    notices = notices + 1; printMessage(self, message)
end
local categories, registrations = 0, 0
local canvas, register = Settings.RegisterCanvasLayoutCategory, Settings.RegisterAddOnCategory
Settings.RegisterCanvasLayoutCategory = function(...)
    categories = categories + 1; return canvas(...)
end
Settings.RegisterAddOnCategory = function(...)
    registrations = registrations + 1; return register(...)
end

if mockStartupScenario == "collections_before_login" then
    collections()
    assert(not M.ready and not M.Integration.tab)
    fire("ADDON_LOADED", "MogFocus")
    login()
elseif mockStartupScenario == "addon_after_login" then
    -- MogFocus itself loads after login, with Collections already present.
    CreateMockCollections(1); mockLoggedIn = true
    fire("ADDON_LOADED", "MogFocus")
elseif mockStartupScenario == "options_failure" then
    local text, failed = M.UI.Text, false
    M.UI.Text = function(self, parent, ...)
        if not failed and parent == M.Options.panel then failed = true; error("Injected option font failure") end
        return text(self, parent, ...)
    end
    collections(); login()
    assert(failed and M.ready and not M.Options.ready and M.Integration.collectionsReady)
    assert(M.setupErrors.Options and not M.Options.building)
    local partial = M.Options.panel
    assert(partial and not partial:IsShown())
    M:Initialize()
    assert(M.Options.ready and M.Options.panel ~= partial and not M.setupErrors.Options)
elseif mockStartupScenario == "settings_registration_failure" then
    local fail = true
    local original = Settings.RegisterAddOnCategory
    Settings.RegisterAddOnCategory = function(...)
        if fail then error("Injected Settings registration failure") end
        return original(...)
    end
    collections(); login()
    assert(M.ready and M.Integration.collectionsReady and M.Options.panelReady and not M.Options.ready)
    local panel, category = M.Options.panel, M.Options.category
    eq(categories, 1); eq(registrations, 0)
    fail = false; M:Initialize()
    eq(M.Options.panel, panel); eq(M.Options.category, category)
elseif mockStartupScenario == "ui_failure" or mockStartupScenario == "layout_failure" then
    if mockStartupScenario == "ui_failure" then
        local text, calls = M.UI.Text, 0
        M.UI.Text = function(self, parent, ...)
            if parent == self.frame then
                calls = calls + 1
                if calls == 3 then error("Injected tracker construction failure") end
            end
            return text(self, parent, ...)
        end
    else
        local layout, fail = M.UI.Layout, true
        M.UI.Layout = function(self)
            if fail then self.layingOut = true; fail = false; error("Injected initial layout failure") end
            return layout(self)
        end
    end
    collections(); login()
    assert(M.ready and M.Options.ready and not M.UI.ready and not M.Integration.collectionsReady)
    assert(not M.UI.building and not M.UI.layingOut and not M.Integration.installing)
    assert(M.setupErrors.UI and M.Integration.minimap)
    local partial, content = M.UI.frame, M.Integration.content
    assert(partial and not partial:IsShown())
    M.UI:Render(); M.UI:RenderCatalog(); M.UI:Layout() -- Partial widgets cannot be rendered.
    ShowUIPanel(CollectionsJournal) -- Normal opening retries; no slash command.
    assert(M.Integration.collectionsReady and M.UI.ready and M.UI.frame ~= partial)
    eq(M.Integration.content, content); assert(not partial:IsShown() and not M.setupErrors.UI)
    HideUIPanel(CollectionsJournal)
elseif mockStartupScenario == "collections_callback_failure" then
    local original, fail = EventRegistry.RegisterCallback, true
    EventRegistry.RegisterCallback = function(self, ...)
        if fail then fail = false; error("Injected callback registration failure") end
        return original(self, ...)
    end
    collections(); login()
    assert(M.UI.ready and not M.Integration.collectionsReady and not M.Integration.eventRegistered)
    assert(M.setupErrors.Collections)
    local tab, frame, count = M.Integration.tab, M.UI.frame, CollectionsJournal.numTabs
    ShowUIPanel(CollectionsJournal)
    assert(M.Integration.collectionsReady and not M.setupErrors.Collections)
    eq(M.Integration.tab, tab); eq(M.UI.frame, frame); eq(CollectionsJournal.numTabs, count)
    HideUIPanel(CollectionsJournal)
elseif mockStartupScenario == "collections_reentry" then
    local create, entered = M.UI.Create, false
    M.UI.Create = function(self, parent)
        if not entered then entered = true; eq(M.Integration:Collections(), false) end
        return create(self, parent)
    end
    collections(); login(); assert(entered)
elseif mockStartupScenario == "menu_failure" then
    local modify, fail = Menu.ModifyMenu, true
    Menu.ModifyMenu = function(...)
        if fail then error("Injected menu registration failure") end
        return modify(...)
    end
    collections(); login()
    assert(M.Integration.collectionsReady and not M.Integration.menuRegistered and M.setupErrors.Menu)
    eq(Menu.registrationCount, 0)
    fail = false; M:Initialize()
    assert(M.Integration.menuRegistered and not M.setupErrors.Menu)
else
    fire("ADDON_LOADED", "MogFocus")
    login()
    assert(M.ready and M.Options.ready and not M.Integration.tab)
    collections()
end

assert(M.ready and M.Fonts.ready and M.Options.ready and M.UI.ready and M.Integration.collectionsReady)
assert(not CollectionsJournal:IsShown()) -- Login never opens a journal by itself.
eq(categories, 1); eq(registrations, 1)
eq(Menu.registrationCount, 1)
eq(#EventRegistry.callbacks["CollectionsJournal.TabSet"], 1)
eq(M.Integration.tab.points[1][2], CollectionsJournal.WarbandScenesTab)
if mockStartupScenario == "missing_font" then
    assert(M.Fonts.fallback and M.Fonts.warned)
    eq(notices, 1)
    for _, font in pairs(M.Fonts.objects) do
        assert(font:GetFont()); eq(font:GetFontObject(), GameFontNormal)
    end
else
    assert(not M.Fonts.fallback)
    for _, font in pairs(M.Fonts.objects) do assert(font:GetFont():find("DejaVuSans", 1, true)) end
end
eq(GameFontNormal.fontPath, nil)

-- Native Collections opening and clicking the tab must show real content.
ShowUIPanel(CollectionsJournal)
CollectionsJournal_SetTab(CollectionsJournal, M.Integration.tab:GetID())
assert(M.UI.frame:IsShown() and M.UI.frame.status:GetText() ~= "" and M.UI.left.count > 0)
if empty then
    eq(M.UI.left.rows[1].title:GetText(), M.L("EMPTY"))
    M.UI.left.rows[1].actions[1].scripts.OnClick()
else
    assert(M.UI.left.rows[1].title:GetText():find("Testovací set", 1, true))
    M.UI.frame.tabs.catalog.button.scripts.OnClick()
end
eq(M.UI.view, "catalog")
assert(M.UI.catalog.rows[1].title:GetText():find("Testovací set", 1, true))
-- Loading the catalog is read-only with respect to manually selected goals.
eq(MogFocusDB, saved); eq(M.Store.db.custom, "keep")
eq(#M.Store.profile.targets, empty and 0 or 1)
if not empty then eq(M.Store.profile.targets[1], 501); eq(M.Store.profile.pinned, 501) end
eq(M.Store.profile.focus, 0); assert(M.Store.profile.notified[502]); eq(M.Store.profile.custom, "keep")
eq(saved.profiles.Other.targets[1], 999); eq(saved.profiles.Other.focus, 1); assert(saved.profiles.Other.notified[999])
eq(M.Store.settings.skin, "Arcane"); eq(M.Store.settings.minimapAngle, 41)
eq(saved.readVersion, "0.2.0")

local frames, tab, noticeCount = #mockFrames, M.Integration.tab, notices
for _ = 1, 3 do
    fire("PLAYER_LOGIN"); fire("ADDON_LOADED", "Blizzard_Collections"); fire("PLAYER_REGEN_ENABLED")
    M.Integration:Collections(); M.Options:Register()
end
eq(#mockFrames, frames); eq(M.Integration.tab, tab); eq(notices, noticeCount)
eq(categories, 1); eq(registrations, 1); eq(Menu.registrationCount, 1)
eq(#EventRegistry.callbacks["CollectionsJournal.TabSet"], 1)
CollectionsJournal_SetTab(CollectionsJournal, 5)
assert(CollectionsJournal.pages[5]:IsShown() and not M.UI.frame:IsShown())
print("PASS isolated startup: " .. mockStartupScenario)
