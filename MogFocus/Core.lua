local addon, M = ...
local events = CreateFrame("Frame")
local refreshing, catalogTimer

function M:Debug()
    local version, build, _, interface = GetBuildInfo()
    self:Print(self.L("VERSION", self.version) .. " · " .. self.L("DIAGNOSTIC", version, build, tostring(interface)))
    for _, spec in ipairs({ { "C_TransmogSets", "GetAllSets" }, { "C_TransmogSets", "GetSetInfo" },
        { "C_TransmogSets", "GetSetPrimaryAppearances" }, { "C_TransmogSets", "GetVariantSets" },
        { "C_TransmogCollection", "GetSourceInfo" }, { "C_TransmogCollection", "GetAppearanceSources" },
        { "C_TransmogCollection", "GetAppearanceSourceDrops" }, { "Settings", "RegisterCanvasLayoutCategory" } }) do
        local available = _G[spec[1]] and type(_G[spec[1]][spec[2]]) == "function"
        self:Print(spec[1] .. "." .. spec[2] .. ": " .. self.L(available and "YES" or "NO"))
    end
    if self.lastAPIError then self:Print(self.lastAPIError .. ": " .. self.L("UNAVAILABLE")) end
end

function M:Notify(set)
    self.noticeSetName = set.info.name
    self:Print(self.L("NOTIFY", set.info.name))
    if not self.notice then
        self.notice = self.UI:Panel(UIParent); self.notice:SetSize(520, 65); self.notice:SetPoint("TOP", 0, -130)
        self.notice:SetFrameStrata("HIGH"); self.notice.text = self.UI:Text(self.notice, "", true)
        self.notice.text:SetPoint("TOPLEFT", 16, -12); self.notice.text:SetWidth(488)
    end
    self.notice.text:SetText(self.L("NOTIFY", set.info.name)); self.notice:Show()
    self.noticeGeneration = (self.noticeGeneration or 0) + 1
    local generation = self.noticeGeneration
    C_Timer.After(5, function() if generation == self.noticeGeneration then self.notice:Hide() end end)
    if self.Store.settings.sound then PlaySound(SOUNDKIT.UI_EPICLOOT_TOAST) end
end

function M:Refresh(invalidate, isRetry)
    if not self.ready then return end
    if not isRetry then
        self.loadingAttempts = 0; self.loadingRetry = nil
        self.loadingGeneration = (self.loadingGeneration or 0) + 1
    end
    if invalidate then self.Collection:Invalidate() end
    local pending = false
    for _, set in ipairs(self.Collection:Selected()) do
        if set.status ~= "ready" then pending = true end
        self.Collection:Observe(set, function(result) self:Notify(result) end)
    end
    self.UI:Render()
    if pending and self.UI.frame and self.UI.frame:IsShown() and not self.loadingRetry and (self.loadingAttempts or 0) < 4 then
        self.loadingAttempts = (self.loadingAttempts or 0) + 1
        self.loadingRetry = true
        local generation = self.loadingGeneration
        C_Timer.After(.5 * 2 ^ (self.loadingAttempts - 1), function()
            if generation ~= self.loadingGeneration then return end
            self.loadingRetry = nil
            if self.UI.frame and self.UI.frame:IsShown() then self:Refresh(true, true) end
        end)
    end
end

function M:QueueRefresh()
    if refreshing then return end
    refreshing = true
    C_Timer.After(.25, function() refreshing = false; self:Refresh(true) end)
end

function M:StartCatalog()
    if catalogTimer then return end
    self.Collection:BeginCatalog()
    catalogTimer = C_Timer.NewTicker(.06, function()
        if not self.UI.frame or not self.UI.frame:IsShown() or self.UI.view ~= "catalog" then
            catalogTimer:Cancel(); catalogTimer = nil; return
        end
        local more = self.Collection:ScanCatalogBatch()
        if not more or GetTime() - (self.lastCatalogRender or 0) >= .4 then
            self.lastCatalogRender = GetTime(); self.UI:RenderCatalog()
        end
        if not more then catalogTimer:Cancel(); catalogTimer = nil end
    end)
end

function M:Initialize()
    if self.ready then return end
    local db, err = self.Store:Open(MogFocusDB, UnitGUID("player"))
    if not db then self.blocked = err; self:Print(self.L(err)); return end
    MogFocusDB = db
    if not C_TransmogSets or not C_TransmogSets.GetSetPrimaryAppearances or not C_TransmogCollection or not C_TransmogCollection.GetSourceInfo then
        self.blocked = "API_MISSING"; self:Print(self.L(self.blocked)); return
    end
    self.ready = true
    if not InCombatLockdown() then self.Options:Register(); self.Integration:Update() end
    self:Refresh(true)
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
for _, event in ipairs({ "TRANSMOG_COLLECTION_UPDATED", "TRANSMOG_COLLECTION_SOURCE_ADDED", "TRANSMOG_COLLECTION_SOURCE_REMOVED",
    "TRANSMOG_COLLECTION_ITEM_UPDATE", "TRANSMOG_SOURCE_COLLECTABILITY_UPDATE", "ITEM_DATA_LOAD_RESULT", "UNIT_MODEL_CHANGED" }) do events:RegisterEvent(event) end

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addon and IsLoggedIn() then M:Initialize() end
        if arg1 == "Blizzard_Collections" and M.ready then M.Integration:Wardrobe() end
    elseif event == "PLAYER_LOGIN" then M:Initialize()
    elseif event == "PLAYER_REGEN_ENABLED" then if M.ready then M.Options:Register(); M.Integration:Update() end
    elseif M.ready then
        if event == "UNIT_MODEL_CHANGED" and arg1 ~= "player" then return end
        if event == "UNIT_MODEL_CHANGED" then M.UI.modelSet = nil end
        if event == "ITEM_DATA_LOAD_RESULT" and not M.Collection.requested[arg1] then return end
        -- A catalog with pending source responses gets another bounded, visible-only pass.
        if event ~= "UNIT_MODEL_CHANGED" and event ~= "ITEM_DATA_LOAD_RESULT" then M.Collection.scanList = nil end
        M:QueueRefresh()
        if M.UI.view == "catalog" and M.UI.frame and M.UI.frame:IsShown() then M:StartCatalog() end
    end
end)

SLASH_MOGFOCUS1 = "/mogfocus"
SlashCmdList.MOGFOCUS = function(message)
    local command = string.lower((message or ""):match("^%s*(.-)%s*$"))
    if command == "debug" then M:Debug()
    elseif command == "options" then M.Options:Open()
    else M.UI:Toggle() end
end
