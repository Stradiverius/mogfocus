local _, M = ...
local O = {}
M.Options = O

function O:Changed(key, value)
    M.Store.settings[key] = value
    if key == "reduceMotion" and value then
        for widget in pairs(M.Skins.widgets) do if widget.flash then widget.flash:Stop() end end
    end
    M.Skins:Refresh(); M.Integration:Update(); self:Refresh(); M.UI:RefreshText(); M.UI:Render()
    if M.notice and M.notice:IsShown() then M.notice.text:SetText(M.L(M.noticeKey, M.noticeValue)) end
    if self.changelog and self.changelog:IsShown() then self:RenderChangelog() end
end

function O:Register()
    if self.panel or not Settings or not Settings.RegisterCanvasLayoutCategory then return end
    local U = M.UI
    local panel = U:Panel(UIParent); panel:Hide()
    self.panel = panel
    self.title = U:Text(panel, "MogFocus", true); self.title:SetPoint("TOPLEFT", 16, -16)
    self.note = U:Text(panel, M.L("ACCOUNT")); self.note:SetPoint("TOPLEFT", 16, -50); self.note:SetWidth(590)
    self.rows = {}
    local selectors = {
        { key = "language", label = "LANGUAGE", choices = function() return { { value = "cs", label = "Čeština" }, { value = "en", label = "English" } } end },
        { key = "skin", label = "SKIN", choices = function() return { { value = "Warcraft", label = "Warcraft" }, { value = "Obsidian", label = "Obsidian" }, { value = "Arcane", label = "Arcane" } } end },
        { key = "sort", label = "SORT", choices = function() return { { value = "custom", label = M.L("CUSTOM") }, { value = "progress", label = M.L("BY_PROGRESS") }, { value = "raid", label = M.L("BY_RAID") } } end },
    }
    for index, spec in ipairs(selectors) do
        local option = spec
        local label = U:Text(panel, M.L(spec.label)); label:SetPoint("TOPLEFT", 20, -88 - (index - 1) * 44)
        local b
        b = U:Button(panel, "", 250, function()
            U:Choose(b, option.choices(), function(value) self:Changed(option.key, value) end)
        end)
        b:SetPoint("TOPLEFT", 310, -78 - (index - 1) * 44)
        self.rows[#self.rows + 1] = { spec = option, label = label, widget = b }
    end
    for index, spec in ipairs({ { "minimap", "MINIMAP" }, { "compact", "COMPACT" }, { "hideComplete", "HIDE_COMPLETE" },
        { "missingOnly", "MISSING_ONLY" }, { "notifications", "NOTIFICATIONS" }, { "sound", "SOUND" }, { "reduceMotion", "REDUCE_MOTION" } }) do
        local key, label = spec[1], spec[2]
        local c = U:Check(panel, label, function(value) self:Changed(key, value) end)
        c:SetPoint("TOPLEFT", 20, -216 - (index - 1) * 31)
        self.rows[#self.rows + 1] = { spec = { key = key, label = label }, widget = c }
    end
    self.changeButton = U:Button(panel, M.L("NEW"), 250, function() self:Changelog() end)
    self.changeButton:SetPoint("TOPLEFT", 20, -454)
    self.help = U:Text(panel, M.L("HELP")); self.help:SetPoint("TOPLEFT", 20, -500); self.help:SetWidth(580)
    self.dataNote = U:Text(panel, M.L("DATA_NOTE")); self.dataNote:SetPoint("TOPLEFT", 20, -530); self.dataNote:SetWidth(580)
    panel:SetScript("OnShow", function() self:Refresh() end)
    self.category = Settings.RegisterCanvasLayoutCategory(panel, "MogFocus")
    Settings.RegisterAddOnCategory(self.category)
end

function O:Refresh()
    if not self.panel then return end
    self.note:SetText(M.L("ACCOUNT")); self.help:SetText(M.L("HELP")); self.dataNote:SetText(M.L("DATA_NOTE"))
    for _, row in ipairs(self.rows) do
        local spec = row.spec
        if spec.choices then
            row.label:SetText(M.L(spec.label))
            for _, choice in ipairs(spec.choices()) do
                if choice.value == M.Store.settings[spec.key] then row.widget.caption:SetText(choice.label) end
            end
        else
            row.widget.caption:SetText(M.L(spec.label)); row.widget:SetChecked(M.Store.settings[spec.key])
        end
    end
    self.changeButton.caption:SetText(M.L("NEW") .. (M.Store.db.readVersion ~= M.version and " *" or ""))
end

function O:Open()
    if not M.ready then M:Print(M.L(M.blocked or "NO_PROFILE")); return end
    if InCombatLockdown() then M:Print(M.L("COMBAT")); return end
    self:Register()
    if self.category then Settings.OpenToCategory(self.category:GetID()) end
end

function O:Changelog()
    if InCombatLockdown() then M:Print(M.L("COMBAT")); return end
    if not self.changelog then
        local U = M.UI
        local frame = U:Panel(UIParent); frame:SetSize(790, 570); frame:SetPoint("CENTER")
        frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetClampedToScreen(true); frame:EnableMouse(true)
        frame:SetScale(math.min(1, (UIParent:GetWidth() - 30) / 790, (UIParent:GetHeight() - 30) / 570))
        frame.title = U:Text(frame, "", true); frame.title:SetPoint("TOPLEFT", 16, -15)
        frame.close = U:Button(frame, M.L("CLOSE"), 100, function() frame:Hide() end); frame.close:SetPoint("TOPRIGHT", -12, -10)
        frame.list = U:Scroll(frame, 740, 495); frame.list.frame:SetPoint("TOPLEFT", 16, -55)
        self.changelog = frame
    end
    M.Store.db.readVersion = M.version
    self:RenderChangelog(); self.changelog:Show(); self:Refresh(); M.UI:Render()
end

function O:RenderChangelog()
    local f, U = self.changelog, M.UI
    if not f then return end
    f.title:SetText("MogFocus · " .. M.L("NEW")); f.close.caption:SetText(M.L("CLOSE"))
    f.list:Clear()
    for _, release in ipairs(M.changelog) do
        local row = U:Row(f.list, 260)
        row.title:SetText(M.L("VERSION", release.version) .. " · " .. release.date)
        row.body:SetText(M.L("CHANGE_FEATURES") .. "\n" .. M.L(release.features) .. "\n\n" .. M.L("CHANGE_CHANGES") .. "\n" .. M.L(release.changes) .. "\n\n" .. M.L("CHANGE_FIXES") .. "\n" .. M.L(release.fixes))
        local height = row.body:GetStringHeight() + 56
        f.list.y = f.list.y + height - row:GetHeight(); row:SetHeight(height)
    end
    f.list:Finish()
end
