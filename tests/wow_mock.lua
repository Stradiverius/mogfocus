-- Small, strict frame/API stand-in for exercising event and UI wiring only.
-- It does not emulate WoW rendering, taint, collection semantics or combat security.
local Frame = {}
local function noop() end
for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetFrameStrata", "SetFrameLevel", "SetClampedToScreen", "EnableMouse",
    "SetMovable", "RegisterForDrag", "RegisterForClicks", "StartMoving", "StopMovingOrSizing", "SetScale", "SetFontObject",
    "SetTextColor", "SetJustifyH", "SetJustifyV", "SetHighlightTexture", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor",
    "SetColorTexture", "SetTexture", "SetDesaturated", "SetStatusBarTexture", "SetMinMaxValues", "SetValue", "SetStatusBarColor",
    "SetAutoFocus", "ClearFocus", "EnableMouseWheel", "SetAutoDress", "SetKeepModelOnHide", "SetUnit", "Undress", "TryOn",
    "SetPortraitZoom", "SetRotation", "SetDuration", "SetFromAlpha", "SetToAlpha", "SetLooping", "SetAllPoints", "SetItemByID", "SetHyperlink", "AddLine", "SetOwner" }) do Frame[method] = noop end
function Frame:IsGeoReady() return true end
function Frame:SetSize(w, h) self.width, self.height = w, h end
function Frame:SetWidth(w) self.width = w end
function Frame:SetHeight(h) self.height = h end
function Frame:GetWidth() return self.width or 100 end
function Frame:GetHeight() return self.height or 30 end
function Frame:GetFrameLevel() return 1 end
function Frame:GetEffectiveScale() return 1 end
function Frame:GetCenter() return 100, 100 end
function Frame:SetFacing(v) self.facing = v end
function Frame:GetFacing() return self.facing or 0 end
function Frame:SetText(t) self.text = t end
function Frame:GetText() return self.text or "" end
function Frame:GetStringHeight() return math.max(14, math.ceil(#self:GetText() / math.max(1, (self.width or 300) / 7)) * 14) end
function Frame:SetAlpha(a) self.alpha = a end
function Frame:SetChecked(value) self.checked = value end
function Frame:GetChecked() return self.checked end
function Frame:SetEnabled(value) self.enabled = value end
function Frame:SetScrollChild(child) self.child = child end
function Frame:SetVerticalScroll(value) self.scroll = value end
function Frame:GetVerticalScroll() return self.scroll or 0 end
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:HookScript(name, fn) self.scripts[name] = fn end
function Frame:RegisterEvent(event) self.events[event] = true end
function Frame:IsShown() return not self.hidden and (not self.parent or self.parent:IsShown()) end
function Frame:Show()
    local changed = self.hidden
    self.hidden = false
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Frame:Hide()
    local changed = not self.hidden
    self.hidden = true
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Frame:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Frame:Play() self.playing = true end
function Frame:Stop() self.playing = false end
function Frame:CreateAnimation() return CreateFrame("Animation") end
function Frame:CreateAnimationGroup() return CreateFrame("AnimationGroup") end
function Frame:CreateTexture() return CreateFrame("Texture", nil, self) end
function Frame:CreateFontString() return CreateFrame("FontString", nil, self) end
mockFrames = {}
function CreateFrame(kind, name, parent)
    local frame = setmetatable({ kind = kind, name = name, parent = parent, scripts = {}, events = {} }, { __index = Frame })
    mockFrames[#mockFrames + 1] = frame
    if name then _G[name] = frame end
    return frame
end
UIParent = CreateFrame("Frame"); UIParent:SetSize(1920, 1080)
Minimap = CreateFrame("Frame", nil, UIParent); Minimap:SetSize(160, 160)
GameTooltip = CreateFrame("GameTooltip")
GameFontNormal, GameFontNormalLarge, GameFontHighlight, GameFontHighlightSmall = {}, {}, {}, {}
UISpecialFrames, SlashCmdList, RAID_CLASS_COLORS = {}, {}, { WARRIOR = { r = .7, g = .5, b = .3 } }
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) mockLastMessage = message end }
EXPANSION_NAME0, EXPANSION_NAME1, EXPANSION_NAME2 = "Classic", "The Burning Crusade", "Wrath of the Lich King"
INVTYPE_HEAD, INVTYPE_CHEST = "Head", "Chest"
TRANSMOG_SOURCE_BOSS_DROP, INSTANCE_TYPE_RAID = 1, 2
SOUNDKIT = { UI_EPICLOOT_TOAST = 1 }
mockTime, mockCombat, mockLoggedIn, mockGUID = 100, false, false, "Player-1-A"
function GetTime() return mockTime end
function UnitGUID() return mockGUID end
function UnitClass() return "Warrior", "WARRIOR", 1 end
function UnitName() return "Test" end
function UnitFullName() return "Test", "Realm" end
function GetRealmName() return "Realm" end
function IsLoggedIn() return mockLoggedIn end
function InCombatLockdown() return mockCombat end
function GetBuildInfo() return "12.1.5", "70529", "Oct 23 2026", 120105 end
function GetNumClasses() return 2 end
function GetCursorPosition() return 150, 150 end
function IsMouseButtonDown() return false end
function PlaySound() mockSound = true end
function EJ_GetInstanceInfo(id) return ({ [741] = "Molten Core", [742] = "Blackwing Lair", [745] = "Karazhan", [746] = "Gruul's Lair", [747] = "Magtheridon's Lair" })[id] end
function EJ_GetEncounterInfo(id) return "Encounter " .. id end
function EncounterJournal_OpenJournal(...) mockJournal = { ... } end
C_CreatureInfo = { GetClassInfo = function(id) if id > 0 and id <= 2 then return { className = "Class " .. id } end end }
Settings = {
    RegisterCanvasLayoutCategory = function() return { GetID = function() return 77 end } end,
    RegisterAddOnCategory = noop, OpenToCategory = function(id) mockCategory = id end,
}
C_AddOns = { LoadAddOn = function() return true end }
mockTimers = {}
C_Timer = {
    After = function(_, fn) mockTimers[#mockTimers + 1] = fn end,
    NewTicker = function(_, fn) return { Cancel = noop, callback = fn } end,
}
C_Item = {
    GetItemInfo = function(id) return "Item " .. id end,
    GetItemInfoInstant = function(id) return id, "Armor", "Plate", "INVTYPE_HEAD", 123 end,
    RequestLoadItemDataByID = function(id) mockRequestedItem = id end,
}
mockSets, mockSources, mockDrops, mockAlternatives = {}, {}, {}, {}
C_TransmogSets = {
    GetSetInfo = function(id) return mockSets[id] and mockSets[id].info end,
    GetSetPrimaryAppearances = function(id) return mockSets[id] and mockSets[id].primary end,
    GetAllSets = function() local list = {}; for _, set in pairs(mockSets) do list[#list + 1] = set.info end; return list end,
    GetVariantSets = function() return {} end,
}
C_TransmogCollection = {
    GetSourceInfo = function(id) return mockSources[id] end,
    GetAppearanceSources = function(id) return mockAlternatives[id] end,
    GetAppearanceSourceDrops = function(id) return mockDrops[id] end,
    GetSourceIcon = function() return 123 end,
}

-- Current Collections / Blizzard_Menu contracts, modeled for integration tests.
function Frame:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = { ... } end
function Frame:ClearAllPoints() self.points = {} end
function Frame:GetPoint(index) return unpack((self.points or {})[index or 1] or {}) end
function Frame:SetAllPoints(parent) self.allPoints = parent end
local function anchoredSize(self, vertical)
    if self.allPoints then return vertical and self.allPoints:GetHeight() or self.allPoints:GetWidth() end
    local a, b = (self.points or {})[1], (self.points or {})[2]
    if a and b and a[1] == "TOPLEFT" and b[1] == "BOTTOMRIGHT" and a[2] == b[2] then
        if vertical then return a[2]:GetHeight() + a[5] - b[5] end
        return a[2]:GetWidth() + b[4] - a[4]
    end
    return vertical and (self.height or 30) or (self.width or 100)
end
function Frame:GetWidth() return anchoredSize(self, false) end
function Frame:GetHeight() return anchoredSize(self, true) end
function Frame:GetName() return self.name end
function Frame:SetID(id) self.id = id end
function Frame:GetID() return self.id or 0 end
function Frame:SetFont(path, size) self.fontPath, self.fontSize = path, size; return true end
function Frame:SetFontObject(font) self.fontObject = font end
function Frame:GetFontObject() return self.fontObject end
function Frame:SetNormalFontObject(font) self.normalFont = font end
function Frame:SetHighlightFontObject(font) self.highlightFont = font end
function Frame:SetDisabledFontObject(font) self.disabledFont = font end
function Frame:SetShadowColor() end
function Frame:SetShadowOffset() end
function Frame:GetFontString() return self.Text end
function Frame:SetTitle(title) self.windowTitle = title end
function Frame:NumLines() return self.lineCount or 0 end
function Frame:ClearLines() self.lineCount = 0 end
function Frame:AddLine(text)
    self.lineCount = (self.lineCount or 0) + 1
    local line = CreateFrame("FontString", self.name and (self.name .. "TextLeft" .. self.lineCount), self)
    line:SetText(text)
end
function Frame:HookScript(name, fn)
    local before = self.scripts[name]
    self.scripts[name] = function(...) if before then before(...) end; fn(...) end
end
function CreateFont(name) return CreateFrame("Font", name) end
local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent)
    if template == "CollectionsJournalTab" then frame.Text = createFrame("FontString", nil, frame) end
    return frame
end
function Frame:SetText(text) self.text = text; if self.Text then self.Text:SetText(text) end end
function hooksecurefunc(name, callback)
    local original = _G[name]
    _G[name] = function(...) local result = { original(...) }; callback(...); return unpack(result) end
end
EventRegistry = { callbacks = {} }
function EventRegistry:RegisterCallback(event, fn, owner)
    self.callbacks[event] = self.callbacks[event] or {}
    table.insert(self.callbacks[event], { fn = fn, owner = owner })
end
function EventRegistry:TriggerEvent(event, ...)
    for _, entry in ipairs(self.callbacks[event] or {}) do entry.fn(entry.owner, ...) end
end
local function tabAt(j, id) return j.Tabs and j.Tabs[id] or _G[j:GetName() .. "Tab" .. id] end
function PanelTemplates_AnchorTabs(j)
    for id = 2, j.numTabs do local t = tabAt(j, id); t:ClearAllPoints(); t:SetPoint("TOPLEFT", tabAt(j, id - 1), "TOPRIGHT", 3, 0) end
end
function PanelTemplates_SetNumTabs(j, n) j.numTabs = n; PanelTemplates_AnchorTabs(j) end
function PanelTemplates_UpdateTabs(j)
    for id = 1, j.numTabs do
        local tab = tabAt(j, id); tab.selected = id == j.selectedTab
        tab:SetDisabledFontObject(GameFontHighlightSmall)
    end
end
function PanelTemplates_ResizeTabsToFit(j, w) j.tabWidthBudget = w end
function PanelTemplates_TabResize(tab) tab:SetWidth(90) end
function PanelTemplates_GetSelectedTab(j) return j.selectedTab end
function PanelTemplates_SetTab(j, id) j.selectedTab = id; PanelTemplates_UpdateTabs(j) end
function SetCVar(key, value) mockCVars = mockCVars or {}; mockCVars[key] = value end
function CollectionsJournal_SetTab(j, id)
    PanelTemplates_SetTab(j, id)
    for index, page in ipairs(j.pages) do page:SetShown(index == id) end
    EventRegistry:TriggerEvent("CollectionsJournal.TabSet", j, id)
end
function ShowUIPanel(frame) frame:Show() end
function HideUIPanel(frame) frame:Hide() end
function CreateMockCollections(extraTabs)
    local j = CreateFrame("Frame", "CollectionsJournal", UIParent); j:SetSize(703, 606); j:Hide()
    j.pages = {}
    for id = 1, 6 + (extraTabs or 0) do
        local tab = CreateFrame("Button", "CollectionsJournalTab" .. id, j, "CollectionsJournalTab"); tab:SetID(id)
        j.pages[id] = CreateFrame("Frame", nil, j)
    end
    j.WardrobeTab, j.WarbandScenesTab = _G.CollectionsJournalTab5, _G.CollectionsJournalTab6
    WardrobeCollectionFrame = j.pages[5]
    j.numTabs, j.selectedTab = 6 + (extraTabs or 0), 5
    return j
end
C_AddOns.LoadAddOn = function(name)
    if name == "Blizzard_Collections" and not CollectionsJournal then CreateMockCollections(1) end
    return true
end
local MenuDescription = {}
function MenuDescription:CreateButton(label, action)
    local child = setmetatable({ label = label, action = action, children = {}, kind = "button", initializers = {} }, { __index = MenuDescription })
    self.children[#self.children + 1] = child; return child
end
function MenuDescription:CreateTitle(label) local entry = self:CreateButton(label); entry.kind = "title"; return entry end
function MenuDescription:CreateDivider() local entry = self:CreateButton(""); entry.kind = "divider"; return entry end
function MenuDescription:AddInitializer(fn) table.insert(self.initializers, fn) end
function NewMockMenu() return setmetatable({ children = {}, initializers = {} }, { __index = MenuDescription }) end
Menu = { callbacks = {}, registrationCount = 0 }
function Menu.ModifyMenu(tag, callback) Menu.callbacks[tag] = callback; Menu.registrationCount = Menu.registrationCount + 1 end
C_TransmogSets.GetBaseSets = C_TransmogSets.GetAllSets
