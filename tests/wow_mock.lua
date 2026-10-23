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
