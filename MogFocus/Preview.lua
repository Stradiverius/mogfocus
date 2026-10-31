local _, M = ...
local P = { models = setmetatable({}, { __mode = "k" }), delays = { .1, .2, .4, .6, 1, 1.5, 2, 3 } }
M.Preview = P

function P:Status(model, key, ...)
    local s = model.mogPreview
    s.message, s.args = key, { ... }
    local short = { PREVIEW_LOADING = "LOADING", PREVIEW_RETRY_HINT = "PREVIEW_UNAVAILABLE", PREVIEW_CONTROLS = "PREVIEW_DRAG", PREVIEW_PARTIAL = "PREVIEW_PARTIAL_SHORT" }
    if s.note then s.note:SetText(M.L(s.compact and short[key] or key, ...)) end
end

function P:Queue(model)
    local s = model.mogPreview
    if s.queued or not model:IsVisible() or not s.id then return end
    local delay = self.delays[math.max(1, s.attempts)]
    if not delay then
        s.status = "unavailable"; self:Status(model, "PREVIEW_RETRY_HINT")
        return
    end
    s.queued = true
    local generation = s.generation
    C_Timer.After(delay, function()
        if generation ~= s.generation then return end
        s.queued = nil
        if model:IsVisible() and s.id and s.status == "loading" then self:Step(model) end
    end)
end

function P:Stop(model)
    local s = model.mogPreview
    s.generation = s.generation + 1
    s.queued, s.dragX, s.suspended = nil, nil, true
end

function P:Create(parent, note)
    local model = CreateFrame("DressUpModel", nil, parent)
    local s = { generation = 0, attempts = 0, note = note, yaw = 0, zoom = 0, status = "idle" }
    model.mogPreview = s; self.models[model] = true
    model:SetAutoDress(false); model:SetKeepModelOnHide(true)
    model:SetUseTransmogChoices(false); model:SetObeyHideInTransmogFlag(false)
    model:EnableMouse(true); model:EnableMouseWheel(true)
    model:SetLight(true, { omnidirectional = false, point = CreateVector3D(-1, 0, 0),
        ambientIntensity = .8, ambientColor = CreateColor(.8, .8, .85), diffuseIntensity = .7, diffuseColor = CreateColor(1, 1, 1) })
    model:SetScript("OnModelLoaded", function()
        -- This can fire during SetUnit/TryOn. Never Undress recursively here.
        if not s.id or s.running or not model:IsVisible() then return end
        if s.status ~= "loading" and self:CheckOutfit(model) then s.status, s.attempts = "loading", 0 end
        if s.status == "loading" then self:Queue(model) end
    end)
    model:SetScript("OnShow", function() if s.id and (s.suspended or s.status == "loading") then self:Select(model, s.id, true) end end)
    model:SetScript("OnHide", function() self:Stop(model) end)
    model:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then s.dragX = GetCursorPosition() end end)
    model:SetScript("OnMouseUp", function() s.dragX = nil end)
    model:SetScript("OnUpdate", function()
        if not s.dragX then return end
        if not IsMouseButtonDown("LeftButton") then s.dragX = nil; return end
        local x = GetCursorPosition()
        s.yaw = s.yaw + (x - s.dragX) * .012 / model:GetEffectiveScale()
        model:SetRotation(s.yaw, false); s.dragX = x
    end)
    model:SetScript("OnMouseWheel", function(_, delta)
        s.zoom = math.max(0, math.min(1, s.zoom + delta * .06)); model:SetPortraitZoom(s.zoom)
    end)
    return model
end

function P:CheckOutfit(model)
    local s, present = model.mogPreview, {}
    local outfit = model:GetItemTransmogInfoList()
    if type(outfit) ~= "table" then return false end
    for _, info in pairs(outfit) do
        if info.appearanceID then present[info.appearanceID] = true end
        if info.secondaryAppearanceID then present[info.secondaryAppearanceID] = true end
    end
    local missing = false
    for id in pairs(s.applied or {}) do
        if not present[id] then s.applied[id] = nil; missing = true end
    end
    return missing
end

function P:Select(model, id, force)
    local s = model.mogPreview
    if s.id == id and not force and not s.suspended then return end
    s.generation = s.generation + 1
    s.id, s.applied, s.rejected, s.attempts, s.status = id, {}, {}, 0, "loading"
    s.unitSet, s.cleared, s.queued, s.suspended, s.signature = nil, nil, nil, nil, nil
    model:SetAlpha(0)
    self:Status(model, "PREVIEW_LOADING")
    if id and model:IsVisible() then self:Step(model) end
end

function P:Step(model)
    local s = model.mogPreview
    if s.running or not s.id or not model:IsVisible() then return end
    s.running = true; s.attempts = s.attempts + 1
    local ok, pending = pcall(self.Dress, self, model)
    s.running = nil -- An API exception must never latch the preview shut.
    if not ok then self.lastError = tostring(pending); pending = true end
    if pending then self:Queue(model)
    elseif self.window and self.window:IsShown() and self.window.model == model then
        M.Collection.cache[s.id] = nil; self:RenderWindow()
    end
end

function P:Dress(model)
    local s = model.mogPreview
    if not s.unitSet then
        local native = true
        if PlayerUtil and PlayerUtil.ShouldUseNativeFormInModelScene then native = PlayerUtil.ShouldUseNativeFormInModelScene() end
        if not model:SetUnit("player", false, native) then return true end
        s.unitSet = true
    end
    -- IsGeoReady describes equipped geometry. It must not prevent the first TryOn.
    if not IsUnitModelReadyForUI("player") or (model:GetModelFileID() or 0) == 0 then return true end
    local appearances = M.Call(C_TransmogSets, "GetSetPrimaryAppearances", s.id)
    if type(appearances) ~= "table" or #appearances == 0 then return true end
    local sources, seen = {}, {}
    for _, appearance in ipairs(appearances) do
        local id = appearance.appearanceID
        if type(id) ~= "number" or id <= 0 then return true end
        if not seen[id] then sources[#sources + 1] = id; seen[id] = true end
    end
    table.sort(sources)
    local signature = table.concat(sources, ":")
    if signature ~= s.signature then s.signature, s.cleared, s.applied, s.rejected = signature, nil, {}, {} end
    if not s.cleared then
        model:Undress(); model:SetPortraitZoom(s.zoom); model:SetRotation(s.yaw, false)
        s.cleared = true
    end
    self:CheckOutfit(model)
    local pending, worn, rejected = false, 0, 0
    local reasons = Enum.ItemTryOnReason
    for _, sourceID in ipairs(sources) do
        if not s.applied[sourceID] and not s.rejected[sourceID] then
            local reason = model:TryOn(sourceID) -- Exact modified appearance ID, including uncollected parts.
            if reason == reasons.Success then s.applied[sourceID] = true
            elseif reason == reasons.WrongRace or reason == reasons.NotEquippable then s.rejected[sourceID] = true
            else
                pending = true -- DataPending, nil, or an unknown response is not success.
                local info = M.Call(C_TransmogCollection, "GetSourceInfo", sourceID)
                if info and info.itemID then M.Collection:RequestItem(info.itemID) end
            end
        end
        if s.applied[sourceID] then worn = worn + 1 end
        if s.rejected[sourceID] then rejected = rejected + 1 end
    end
    s.worn, s.total = worn, #sources
    model:SetAlpha(worn > 0 and 1 or 0)
    if pending or not model:IsGeoReady() then
        self:Status(model, "PREVIEW_LOADING"); return true
    elseif rejected > 0 then
        s.status = "partial"; self:Status(model, "PREVIEW_PARTIAL", worn, #sources)
    else
        s.status = "ready"; self:Status(model, "PREVIEW_CONTROLS")
    end
    return false
end

function P:Retry(model)
    local s = model.mogPreview
    if s.id then self:Select(model, s.id, true) end
end

function P:ResetCamera(model)
    local s = model.mogPreview
    s.yaw, s.zoom = 0, 0
    model:SetRotation(0, false); model:SetPortraitZoom(0)
end

function P:UnitChanged()
    for model in pairs(self.models) do
        if model.mogPreview.id then
            if model:IsVisible() then self:Retry(model) else model.mogPreview.suspended = true end
        end
    end
end

function P:Refresh()
    for model in pairs(self.models) do
        local s = model.mogPreview
        if model:IsVisible() and s.note and s.message then self:Status(model, s.message, unpack(s.args or {})) end
    end
    if self.window and self.window:IsShown() then self:RenderWindow() end
end

function P:CreateWindow()
    if self.window then return self.window end
    local U = M.UI
    local f = U:Panel(UIParent, "MogFocusPreviewFrame", "window")
    f:Hide(); f:SetSize(820, 620); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true); f:EnableMouse(true); f:SetMovable(true)
    f.header = U:Panel(f, nil, "heroPanel"); f.header:SetPoint("TOPLEFT", 10, -10); f.header:SetPoint("TOPRIGHT", -10, -10); f.header:SetHeight(88)
    f.header:EnableMouse(true); f.header:RegisterForDrag("LeftButton")
    f.header:SetScript("OnDragStart", function() f:StartMoving() end)
    f.header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    f.title = U:Text(f.header, "", "hero"); f.title:SetPoint("TOPLEFT", 20, -13); f.title:SetWidth(646); f.title:SetMaxLines(2)
    f.meta = U:Text(f.header, "", "muted"); f.meta:SetPoint("BOTTOMLEFT", 20, 12); f.meta:SetWidth(665); f.meta:SetMaxLines(1)
    f.close = U:Button(f.header, "×", 32, function() f:Hide() end); f.close:SetPoint("TOPRIGHT", -12, -12); f.close:SetHeight(30)
    f.stage = U:Panel(f, nil, "stage"); f.stage:SetPoint("TOPLEFT", 12, -110); f.stage:SetSize(430, 446)
    f.character = U:Text(f.stage, "", "kicker"); f.character:SetPoint("TOPLEFT", 18, -14); f.character:SetWidth(394)
    f.note = U:Text(f.stage, "", "muted"); f.note:SetPoint("BOTTOMLEFT", 16, 15); f.note:SetWidth(398); f.note:SetJustifyH("CENTER")
    f.model = self:Create(f.stage, f.note); f.model:SetPoint("TOPLEFT", 10, -42); f.model:SetPoint("BOTTOMRIGHT", -10, 78)
    f.reset = U:Button(f.stage, "", 116, function() self:ResetCamera(f.model) end); f.reset:SetPoint("BOTTOM", 0, 43)
    f.partsTitle = U:Text(f, "", true); f.partsTitle:SetPoint("TOPLEFT", 460, -114); f.partsTitle:SetWidth(330)
    f.progress = U:Text(f, "", "muted"); f.progress:SetPoint("TOPLEFT", 460, -140); f.progress:SetWidth(330)
    f.parts = U:Scroll(f, 330, 380); f.parts.frame:SetPoint("TOPLEFT", 460, -174)
    f.track = U:Button(f, "", 310, function()
        if f.setID then M.Integration:SetTracked(f.setID, not M.Store:Contains(f.setID)); self:RenderWindow() end
    end); f.track.primary = true; f.track:SetPoint("BOTTOMRIGHT", -14, 16); f.track:SetHeight(36)
    f.retry = U:Button(f, "", 190, function() self:Retry(f.model) end); f.retry:SetPoint("BOTTOMLEFT", 14, 16); f.retry:SetHeight(36)
    f:SetScript("OnHide", function() self:Stop(f.model); f:StopMovingOrSizing() end)
    self.window = f
    UISpecialFrames[#UISpecialFrames + 1] = "MogFocusPreviewFrame"
    return f
end

function P:Open(id)
    if not M.ready then return end
    if InCombatLockdown() then M:Print(M.L("COMBAT")); return end
    if not M.Call(C_TransmogSets, "GetSetInfo", id) then M:Print(M.L("UNAVAILABLE")); return end
    local f = self:CreateWindow()
    f.setID = id
    f:SetScale(math.min(1, (UIParent:GetWidth() - 32) / 820, (UIParent:GetHeight() - 32) / 620))
    f:Show(); self:RenderWindow(); self:Select(f.model, id, true)
end

function P:RenderWindow()
    local f, U = self.window, M.UI
    local set = M.Collection:Read(f.setID)
    f.title:SetText(U:SetName(set))
    local info = set.info
    f.meta:SetText(info and (M.Expansion(info.expansionID) .. " · " .. (info.label or "") .. " · " .. (info.description or "")) or M.L("UNAVAILABLE"))
    f.character:SetText(M.L("ON_CHARACTER", UnitName("player") or ""))
    f.partsTitle:SetText(M.L("SET_PARTS")); f.progress:SetText(U:Progress(set))
    f.reset.caption:SetText(M.L("RESET_VIEW")); f.retry.caption:SetText(M.L("RETRY_PREVIEW"))
    f.track.caption:SetText(M.L(M.Store:Contains(f.setID) and "REMOVE_FROM" or "ADD_TO"))
    f.parts:Clear()
    for _, piece in ipairs(set.pieces) do U:PieceRow(f.parts, piece, info and info.expansionID) end
    if #set.pieces == 0 then
        local row = U:Row(f.parts, 82); row.title:SetText(M.L(set.status == "loading" and "LOADING" or "UNAVAILABLE"))
    end
    f.parts:Finish(); M.Skins:Refresh()
end
