local _, M = ...
local U = { expanded = {}, view = "sets", filters = {} }
M.UI = U

function U:Panel(parent, name)
    return M.Skins:Register(CreateFrame("Frame", name, parent, "BackdropTemplate"), "panel")
end

function U:Text(parent, text, title)
    local font = parent:CreateFontString(nil, "OVERLAY")
    M.Fonts:Apply(font, title and "title" or "text")
    font:SetJustifyH("LEFT"); font:SetJustifyV("TOP"); font:SetText(text or "")
    M.Skins:Register(font, title and "title" or "text")
    return font
end

function U:Button(parent, text, width, action)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 120, 26)
    button.caption = self:Text(button, text)
    button.caption:SetPoint("LEFT", 7, 0); button.caption:SetPoint("RIGHT", -7, 0)
    button.caption:SetJustifyH("CENTER"); button.caption:SetJustifyV("MIDDLE")
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    button:SetScript("OnClick", function() if action then action() end end)
    M.Skins:Register(button, "button")
    return button
end

function U:Check(parent, key, action)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check.caption = self:Text(check, M.L(key))
    check.caption:SetPoint("LEFT", check, "RIGHT", 3, 0)
    check.caption:SetJustifyV("MIDDLE")
    check:SetScript("OnClick", function(self) action(self:GetChecked() == true) end)
    return check
end

function U:Scroll(parent, width, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetSize(width, height)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(width - 4, 1)
    scroll:SetScrollChild(content)
    local list = { frame = scroll, content = content, rows = {}, count = 0, y = 0, width = width - 4 }
    function list:Clear()
        for _, row in ipairs(self.rows) do row:Hide() end
        self.count, self.y = 0, 0
    end
    function list:Finish()
        self.content:SetHeight(math.max(1, self.y))
        self.frame:SetVerticalScroll(math.min(self.frame:GetVerticalScroll(), math.max(0, self.y - self.frame:GetHeight())))
    end
    return list
end

function U:Row(list, height)
    list.count = list.count + 1
    local row = list.rows[list.count]
    if not row then
        row = CreateFrame("Button", nil, list.content, "BackdropTemplate")
        row.title = self:Text(row, "", true)
        row.body = self:Text(row, "")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(30, 30); row.icon:SetPoint("TOPLEFT", 8, -8)
        row.bar = CreateFrame("StatusBar", nil, row)
        row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        row.bar:SetHeight(5); row.bar:SetPoint("BOTTOMLEFT", 8, 7); row.bar:SetPoint("BOTTOMRIGHT", -8, 7)
        row.actions = {}
        row:SetScript("OnHide", function()
            if row.flash then row.flash:Stop(); row.icon:SetAlpha(1) end
        end)
        list.rows[list.count] = row
    end
    row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -list.y); row:SetSize(list.width, height)
    row.title:ClearAllPoints(); row.title:SetPoint("TOPLEFT", 10, -9); row.title:SetWidth(list.width - 20)
    M.Fonts:Apply(row.title, "button")
    row.body:ClearAllPoints(); row.body:SetPoint("TOPLEFT", 10, -31); row.body:SetWidth(list.width - 20)
    row.body:SetText(""); row.title:SetText(""); row.icon:Hide(); row.bar:Hide()
    for _, b in ipairs(row.actions) do b:Hide() end
    row:SetScript("OnClick", nil); row:SetScript("OnEnter", nil); row:SetScript("OnLeave", nil)
    row.selected = false; row:Show()
    M.Skins:Register(row, "card")
    list.y = list.y + height + 6
    return row
end

function U:Action(row, index, text, width, action)
    local button = row.actions[index]
    if not button then button = self:Button(row, text, width); row.actions[index] = button end
    button.caption:SetText(text); button:SetWidth(width); button:Show()
    button:ClearAllPoints()
    button:SetScript("OnClick", action)
    return button
end

function U:Choose(anchor, choices, action)
    if self.picker then self.picker:Hide() end
    if not self.picker then
        local picker = self:Panel(UIParent)
        picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetSize(310, 350)
        picker:EnableMouse(true); picker:SetClampedToScreen(true)
        picker.list = self:Scroll(picker, 274, 302); picker.list.frame:SetPoint("TOPLEFT", 8, -38)
        picker.close = self:Button(picker, M.L("CLOSE"), 100, function() picker:Hide() end)
        picker.close:SetPoint("TOPRIGHT", -8, -6)
        self.picker = picker
    end
    local picker = self.picker
    picker.close.caption:SetText(M.L("CLOSE"))
    picker:ClearAllPoints(); picker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    picker.list:Clear()
    for _, choice in ipairs(choices) do
        local entry = choice
        local row = self:Row(picker.list, 32)
        row.title:SetText(entry.label)
        row:SetScript("OnClick", function() picker:Hide(); action(entry.value) end)
    end
    picker.list:Finish(); picker:Show()
end

function U:ExpansionChoices()
    local choices = {}
    for _, id in ipairs(M.ExpansionIDs()) do choices[#choices + 1] = { value = id, label = M.Expansion(id) } end
    return choices
end

function U:Create(parent)
    if self.ready then return true end
    if self.building then return false end
    self.building = true
    local ok = M:TrySetup("UI", self.Build, self, parent)
    self.building = nil
    if not ok then
        self.ready, self.layingOut = nil, nil
        if self.frame then self.frame:Hide() end
    end
    return ok
end

function U:Build(parent)
    -- Failed attempts stay hidden. Anonymous roots can be rebuilt safely;
    -- the existence of a partially constructed frame never means readiness.
    local f = self:Panel(parent)
    f:Hide()
    f:SetAllPoints(parent); f:EnableMouse(true)
    self.frame = f
    f.title = self:Text(f, "MogFocus", true); f.title:SetPoint("TOPLEFT", 18, -16)
    f.character = self:Text(f, ""); f.character:SetPoint("TOPLEFT", 18, -44)
    f.close = self:Button(f, M.L("CLOSE"), 85, function() HideUIPanel(CollectionsJournal) end); f.close:SetPoint("TOPRIGHT", -12, -10)
    f.options = self:Button(f, M.L("OPTIONS"), 120, function() M.Options:Open() end); f.options:SetPoint("RIGHT", f.close, "LEFT", -6, 0)
    f.optionsIcon = f.options:CreateTexture(nil, "ARTWORK"); f.optionsIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
    f.optionsIcon:SetSize(16, 16); f.optionsIcon:SetPoint("LEFT", 5, 0)
    f.version = self:Button(f, M.L("VERSION", M.version), 175, function() M.Options:Changelog() end)
    f.version:SetPoint("RIGHT", f.options, "LEFT", -6, 0)
    f.focus = self:Button(f, "", 330, function()
        self:Choose(f.focus, self:ExpansionChoices(), function(id)
            M.Store.profile.focus = id; self.expansion = id; self.selected = nil
            self.filters.RAID, self.filters.VARIANT, self.catalogPage = nil, nil, 1; self:Render()
        end)
    end); f.focus:SetPoint("TOPRIGHT", -12, -43)
    f.tabs = {}
    for index, spec in ipairs({ { "sets", "MY_SETS" }, { "where", "WHERE" }, { "catalog", "CATALOG" } }) do
        local view, key = spec[1], spec[2]
        local b = self:Button(f, M.L(key), 160, function()
            self.view = view; self:Render()
            if view == "catalog" then M:StartCatalog() end
        end)
        b:SetPoint("TOPLEFT", 18 + (index - 1) * 166, -80); f.tabs[view] = { button = b, key = key }
    end
    f.expansion = self:Button(f, "", 300, function()
        self:Choose(f.expansion, self:ExpansionChoices(), function(id)
            self.expansion = id; self.selected = nil
            self.filters.RAID, self.filters.VARIANT, self.catalogPage = nil, nil, 1; self:Render()
        end)
    end); f.expansion:SetPoint("TOPLEFT", 18, -116)
    f.makeFocus = self:Button(f, M.L("SET_FOCUS"), 265, function() M.Store.profile.focus = self.expansion; self:Render() end)
    f.makeFocus:SetPoint("LEFT", f.expansion, "RIGHT", 6, 0)
    f.refresh = self:Button(f, M.L("REFRESH"), 100, function()
        M.Collection.requested = {}; M.Collection.scanList = nil; M:Refresh(true)
        if self.view == "catalog" then M:StartCatalog() end
    end); f.refresh:SetPoint("TOPRIGHT", -12, -116)
    f.status = self:Text(f, ""); f.status:SetPoint("TOPLEFT", 20, -151); f.status:SetWidth(1130)
    f.note = self:Text(f, ""); f.note:SetPoint("TOPLEFT", 20, -177); f.note:SetWidth(1130)
    self.left = self:Scroll(f, 320, 470); self.left.frame:SetPoint("TOPLEFT", 18, -215)
    self.detail = self:Panel(f); self.detail:SetPoint("TOPLEFT", 366, -210); self.detail:SetSize(800, 510)
    self.detail.title = self:Text(self.detail, "", true); self.detail.title:SetPoint("TOPLEFT", 12, -12); self.detail.title:SetWidth(770)
    self.detail.meta = self:Text(self.detail, ""); self.detail.meta:SetPoint("TOPLEFT", 12, -39); self.detail.meta:SetWidth(770)
    self.detail.missing = self:Check(self.detail, "MISSING_ONLY", function(value) M.Store.settings.missingOnly = value; self:Render() end)
    self.detail.missing:SetPoint("TOPLEFT", 10, -61)
    self.parts = self:Scroll(self.detail, 535, 400); self.parts.frame:SetPoint("TOPLEFT", 10, -100)
    self.model = CreateFrame("DressUpModel", nil, self.detail)
    self.model:SetSize(205, 260); self.model:SetPoint("TOPRIGHT", -12, -84)
    self.model:EnableMouse(true); self.model:EnableMouseWheel(true)
    self.model:SetAutoDress(false); self.model:SetKeepModelOnHide(false)
    self.model:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then self.model.dragX = GetCursorPosition() end
    end)
    self.model:SetScript("OnMouseUp", function() self.model.dragX = nil end)
    self.model:SetScript("OnHide", function() self.model.dragX = nil end)
    self.model:SetScript("OnUpdate", function(model)
        if not model.dragX then return end
        if not IsMouseButtonDown("LeftButton") then model.dragX = nil; return end
        local x = GetCursorPosition()
        self.rotation = (self.rotation or 0) + (x - model.dragX) * .012
        model:SetRotation(self.rotation, false); model.dragX = x
    end)
    self.model:SetScript("OnModelLoaded", function() self:ApplyPreview() end)
    self.zoom = .2
    self.model:SetScript("OnMouseWheel", function(model, delta)
        self.zoom = math.max(0, math.min(1, self.zoom + delta * .06)); model:SetPortraitZoom(self.zoom)
    end)
    self.modelNote = self:Text(self.detail, M.L("PREVIEW")); self.modelNote:SetPoint("TOPRIGHT", -12, -350); self.modelNote:SetWidth(205)
    self.detail.actions = {}
    for i, spec in ipairs({ { "PIN", function()
        local p = M.Store.profile
        if p.pinned == self.selected then p.pinned = nil else p.pinned = self.selected end
        self:Render()
    end },
        { "UP", function() M.Store:Move(self.selected, -1); self:Render() end },
        { "DOWN", function() M.Store:Move(self.selected, 1); self:Render() end },
        { "REMOVE", function() M.Store:Remove(self.selected); self.selected = nil; M:Refresh() end } }) do
        local b = self:Button(self.detail, M.L(spec[1]), 205, spec[2]); b:SetPoint("TOPRIGHT", -12, -386 - (i - 1) * 29)
        self.detail.actions[i] = b
    end
    self.where = self:Scroll(f, 1110, 490); self.where.frame:SetPoint("TOPLEFT", 18, -215)
    self.catalog = self:Scroll(f, 1110, 426); self.catalog.frame:SetPoint("TOPLEFT", 18, -280)
    f.search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    M.Fonts:Apply(f.search, "button")
    f.search:SetSize(390, 25); f.search:SetPoint("TOPLEFT", 24, -210); f.search:SetAutoFocus(false)
    f.search:SetScript("OnTextChanged", function() self.catalogPage = 1; if self.view == "catalog" then self:RenderCatalog() end end)
    f.search:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    f.catalogFilters = {}
    for index, key in ipairs({ "CLASS", "RAID", "VARIANT" }) do
        local filter = key
        local b = self:Button(f, M.L(key), index == 1 and 180 or 270, function() self:FilterMenu(filter) end)
        b:SetPoint("TOPLEFT", 18 + (index == 1 and 0 or index == 2 and 190 or 470), -245)
        f.catalogFilters[filter] = b
    end
    f.previousPage = self:Button(f, M.L("PREVIOUS"), 105, function()
        self.catalogPage = math.max(1, (self.catalogPage or 1) - 1); self.catalog.frame:SetVerticalScroll(0); self:RenderCatalog()
    end); f.previousPage:SetPoint("TOPLEFT", 770, -245)
    f.nextPage = self:Button(f, M.L("NEXT_PAGE"), 90, function()
        self.catalogPage = (self.catalogPage or 1) + 1; self.catalog.frame:SetVerticalScroll(0); self:RenderCatalog()
    end); f.nextPage:SetPoint("TOPLEFT", 880, -245)
    f.page = self:Text(f, ""); f.page:SetPoint("TOPLEFT", 980, -252); f.page:SetWidth(180)
    f.next = self:Button(f, M.L("NEXT_BUTTON"), 190, function()
        local ids = M.ExpansionIDs()
        for i, id in ipairs(ids) do
            if id == self.expansion and ids[i + 1] then
                M.Store.profile.focus = ids[i + 1]; self.expansion = ids[i + 1]; self.selected = nil; self:Render(); break
            end
        end
    end); f.next:SetPoint("BOTTOMLEFT", 18, 18)
    f:SetScript("OnShow", function() if M.ready then M:Refresh(true) end end)
    f:SetScript("OnHide", function()
        if self.picker then self.picker:Hide() end
        self.modelSet, self.previewSources = nil, nil
    end)
    f:SetScript("OnSizeChanged", function() self:Layout() end)
    self.ready = true
    self:Layout()
end

function U:Toggle()
    M.Integration:Open()
end

-- Fit the actual Collections content rectangle; keep fonts at readable native
-- sizes instead of shrinking the former standalone 1180px window.
function U:Layout()
    if not self.ready or self.layingOut then return end
    self.layingOut = true
    local f = self.frame
    local width, height = f:GetWidth(), f:GetHeight()
    if width < 200 then width = CollectionsJournal:GetWidth() - 16 end
    if height < 200 then height = CollectionsJournal:GetHeight() - 68 end
    self.layoutWidth, self.layoutHeight = width, height
    local function place(widget, x, y, w, h)
        widget:ClearAllPoints(); widget:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
        if w then widget:SetWidth(w) end
        if h then widget:SetHeight(h) end
    end
    local function scroll(list, parent, x, y, w, h)
        list.frame:ClearAllPoints(); list.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
        list.frame:SetSize(w, math.max(70, h)); list.width = w - 4; list.content:SetWidth(list.width)
    end
    f.title:Hide(); f.close:Hide()
    place(f.character, 8, 12, width - 286)
    place(f.focus, width - 270, 5, 262, 29)
    for index, view in ipairs({ "sets", "where", "catalog" }) do place(f.tabs[view].button, 8 + (index - 1) * 118, 40, 112) end
    place(f.options, width - 118, 40, 110)
    place(f.version, width - 278, 40, 154)
    place(f.expansion, 8, 76, math.min(240, width * .35))
    place(f.makeFocus, math.min(240, width * .35) + 22, 76, width - math.min(240, width * .35) - 136)
    place(f.refresh, width - 104, 76, 96)
    place(f.status, 8, 110, width - 16)
    place(f.note, 8, 148, width - 16)
    place(f.next, width - 198, 144, 190)
    local leftWidth, bodyY = math.floor(width * .30), 184
    local bodyHeight = height - bodyY - 8
    scroll(self.left, f, 8, bodyY, leftWidth - 18, bodyHeight)
    local detailX = leftWidth + 20
    self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", f, "TOPLEFT", detailX, -bodyY)
    local detailWidth = width - detailX - 8
    self.detail:SetSize(detailWidth, bodyHeight)
    self.detail.title:SetWidth(detailWidth - 20); self.detail.meta:SetWidth(detailWidth - 20)
    self.previewWidth = math.max(126, math.min(185, math.floor(detailWidth * .31)))
    self.partsWidth = detailWidth - self.previewWidth - 42
    scroll(self.parts, self.detail, 8, 100, self.partsWidth, bodyHeight - 110)
    self.model:SetWidth(self.previewWidth)
    self.modelNote:SetWidth(self.previewWidth)
    for index, button in ipairs(self.detail.actions) do
        button:ClearAllPoints(); button:SetPoint("TOPRIGHT", self.detail, "TOPRIGHT", -8, -(bodyHeight - 108 + (index - 1) * 26))
        button:SetSize(self.previewWidth, 24)
    end
    scroll(self.where, f, 8, bodyY, width - 36, bodyHeight)
    place(f.search, 14, 184, math.min(280, width * .41), 25)
    local filterWidth = (width - 32) / 3
    for index, key in ipairs({ "CLASS", "RAID", "VARIANT" }) do place(f.catalogFilters[key], 8 + (index - 1) * (filterWidth + 8), 218, filterWidth, 30) end
    local pagerX = math.min(280, width * .41) + 24
    place(f.previousPage, pagerX, 184, 100)
    place(f.nextPage, pagerX + 106, 184, 70)
    place(f.page, pagerX + 184, 191, width - pagerX - 192)
    scroll(self.catalog, f, 8, 258, width - 36, height - 266)
    self.layingOut = nil
    self:Render()
end

function U:Render()
    if not self.ready or not self.frame:IsShown() then return end
    local f, p = self.frame, M.Store.profile
    self.expansion = self.expansion or p.focus
    f.character:SetText((UnitFullName("player") or UnitName("player")) .. " · " .. (GetRealmName() or ""))
    f.focus.caption:SetText(M.L("FOCUS") .. ": " .. M.Expansion(p.focus))
    f.expansion.caption:SetText(M.L("BROWSE") .. ": " .. M.Expansion(self.expansion))
    f.makeFocus.caption:SetText(M.L("SET_FOCUS")); f.makeFocus:SetEnabled(p.focus ~= self.expansion)
    f.options.caption:SetText("  " .. M.L("OPTIONS")); f.close.caption:SetText(M.L("CLOSE")); f.refresh.caption:SetText(M.L("REFRESH"))
    f.version.caption:SetText(M.L("VERSION", M.version) .. (M.Store.db.readVersion ~= M.version and " *" or ""))
    f.next.caption:SetText(M.L("NEXT_BUTTON"))
    for view, tab in pairs(f.tabs) do tab.button.caption:SetText(M.L(tab.key)); tab.button.selected = self.view == view end
    local sets = M.Collection:Selected(self.expansion)
    local summary = M.Collection:Summary(sets)
    local status = M.L("SUMMARY", summary.complete, summary.total)
    if summary.percent then status = status .. " · " .. M.L("PERCENT", summary.percent) end
    if summary.pending > 0 then status = status .. " · " .. M.L("SUMMARY_PENDING", summary.pending) end
    f.status:SetText(status)
    f.note:SetText(summary.done and M.L("NEXT") or M.L("FILTER_NOTE"))
    local hasNext = _G["EXPANSION_NAME" .. (self.expansion + 1)] ~= nil
    f.next:SetShown(summary.done and self.view ~= "catalog" and hasNext)
    f.note:SetWidth((self.layoutWidth or f:GetWidth()) - (f.next:IsShown() and 214 or 16))
    self.left.frame:SetShown(self.view == "sets"); self.detail:SetShown(self.view == "sets")
    self.where.frame:SetShown(self.view == "where"); self.catalog.frame:SetShown(self.view == "catalog")
    f.search:SetShown(self.view == "catalog")
    for _, b in pairs(f.catalogFilters) do b:SetShown(self.view == "catalog") end
    f.previousPage:SetShown(self.view == "catalog"); f.nextPage:SetShown(self.view == "catalog"); f.page:SetShown(self.view == "catalog")
    if self.view == "sets" then self:RenderSets(sets)
    elseif self.view == "where" then self:RenderWhere(sets)
    else self:RenderCatalog() end
    M.Skins:Refresh()
end

function U:SetName(set)
    return set.info and set.info.name or M.L("SET_ID", set.id)
end

function U:Progress(set)
    if set.status ~= "ready" then return M.L(set.status == "loading" and "LOADING" or "UNAVAILABLE") .. " · " .. M.L("PENDING") end
    return (set.complete and "|cff77ee88✓ " .. M.L("COMPLETE") .. "|r · " or "") .. M.L("PIECES", set.collected, set.total)
        .. (set.total - set.collected == 1 and " · " .. M.L("LAST") or "")
end

function U:RenderSets(sets)
    local visible = {}
    for _, set in ipairs(sets) do
        if not (M.Store.settings.hideComplete and set.complete) then visible[#visible + 1] = set end
    end
    local sort = M.Store.settings.sort
    local raidNames = {}
    if sort == "raid" then
        for _, set in ipairs(visible) do
            local names = {}
            for _, piece in ipairs(set.pieces) do
                for _, route in ipairs(M.Sources:Resolve(piece, set.info and set.info.expansionID, true)) do
                    if route.raid then names[route.raid] = true end
                end
            end
            local list = {}; for name in pairs(names) do list[#list + 1] = name end
            table.sort(list); raidNames[set.id] = table.concat(list, ", ")
        end
    end
    table.sort(visible, function(a, b)
        if a.id == b.id then return false end
        if a.id == M.Store.profile.pinned then return true end
        if b.id == M.Store.profile.pinned then return false end
        if sort == "progress" then
            local pa = a.total and a.collected / a.total or -1
            local pb = b.total and b.collected / b.total or -1
            if pa ~= pb then return pa > pb end
        elseif sort == "raid" and raidNames[a.id] ~= raidNames[b.id] then return raidNames[a.id] < raidNames[b.id] end
        for _, id in ipairs(M.Store.profile.targets) do
            if id == a.id then return true end
            if id == b.id then return false end
        end
        return a.id < b.id
    end)
    self.left:Clear()
    if #visible == 0 then
        local row = self:Row(self.left, 125); row.title:SetText(M.L("EMPTY"))
        local add = self:Action(row, 1, M.L("FIRST"), math.min(230, self.left.width - 20), function() self.view = "catalog"; self:Render(); M:StartCatalog() end)
        add:SetPoint("BOTTOMLEFT", 10, 12)
    end
    local selected
    for _, set in ipairs(visible) do
        local entry = set
        if not self.selected then self.selected = set.id end
        if set.id == self.selected then selected = set end
        local row = self:Row(self.left, M.Store.settings.compact and 78 or 105)
        row.selected = self.selected == set.id
        row.title:SetText((set.id == M.Store.profile.pinned and "★ " or "") .. self:SetName(set))
        row.body:SetPoint("TOPLEFT", 10, -math.max(31, row.title:GetStringHeight() + 14))
        row.body:SetText((set.info and (M.Expansion(set.info.expansionID) .. " · " .. (set.info.description or set.info.label or "")) or "") .. "\n" .. self:Progress(set))
        local height = math.max(row:GetHeight(), row.title:GetStringHeight() + row.body:GetStringHeight() + 30)
        self.left.y = self.left.y + height - row:GetHeight(); row:SetHeight(height)
        if set.status == "ready" then
            row.bar:SetMinMaxValues(0, set.total); row.bar:SetValue(set.collected)
            row.bar:SetStatusBarColor(unpack(M.Skins:Style().accent)); row.bar:Show()
        end
        row:SetScript("OnClick", function() self.selected = entry.id; self:Render() end)
    end
    self.left:Finish()
    if not selected and visible[1] then self.selected = visible[1].id; selected = visible[1] end
    if not selected then self.selected = nil end
    self:RenderDetail(selected)
end

function U:PieceRow(list, piece, expansionID, extra, routes)
    routes = routes or M.Sources:Resolve(piece, expansionID)
    local lines = {}
    for _, route in ipairs(routes) do
        lines[#lines + 1] = (route.alternative and M.L("ALTERNATIVE") .. ": " or "") .. M.Sources:Text(route)
    end
    if #routes > 1 then lines[#lines + 1] = M.L("ALTERNATIVES") end
    local itemName = M.Call(C_Item, "GetItemInfo", piece.itemID) or piece.info.name
    if not itemName then M.Collection:RequestItem(piece.itemID) end
    local _, _, _, equipLoc, icon = C_Item.GetItemInfoInstant(piece.itemID)
    local slot = equipLoc and _G[equipLoc] or tostring(piece.info.invType or "?")
    local body = M.L("SLOT", slot) .. " · " .. M.L(piece.collected and "COLLECTED" or "MISSING")
    if extra then body = body .. "\n" .. extra end
    body = body .. "\n" .. table.concat(lines, "\n")
    local row = self:Row(list, 110)
    row.icon:SetTexture(icon or M.Call(C_TransmogCollection, "GetSourceIcon", piece.sourceID) or 134400)
    row.icon:SetDesaturated(not piece.collected); row.icon:Show()
    row.title:ClearAllPoints(); row.title:SetPoint("TOPLEFT", 46, -10); row.title:SetWidth(list.width - 58)
    local isNew = M.Collection.newParts[piece.visualID] and M.Collection.newParts[piece.visualID] > GetTime()
    row.title:SetText((piece.collected and "✓ " or "• ") .. (itemName or M.L("ITEM_ID", piece.itemID)) .. (isNew and " · " .. M.L("NEW_PART") or ""))
    row.body:SetPoint("TOPLEFT", 10, -math.max(43, row.title:GetStringHeight() + 16)); row.body:SetText(body)
    local h = math.max(96, row.title:GetStringHeight() + row.body:GetStringHeight() + 40)
    local journal
    for _, route in ipairs(routes) do if route.instanceID and route.verified then journal = route; break end end
    if journal then
        h = h + 29
        local b = self:Action(row, 1, M.L("JOURNAL"), math.min(245, list.width - 20), function() M.Sources:OpenJournal(journal) end)
        b:ClearAllPoints(); b:SetPoint("BOTTOMLEFT", 8, 7)
    end
    list.y = list.y + h - row:GetHeight(); row:SetHeight(h)
    if isNew and not M.Store.settings.reduceMotion then
        if not row.flash then
            row.flash = row.icon:CreateAnimationGroup()
            local alpha = row.flash:CreateAnimation("Alpha"); alpha:SetFromAlpha(.35); alpha:SetToAlpha(1); alpha:SetDuration(.6)
            row.flash:SetLooping("BOUNCE")
        end
        row.flash:Play()
        C_Timer.After(4, function() if row.flash then row.flash:Stop(); row.icon:SetAlpha(1) end end)
    elseif row.flash then row.flash:Stop(); row.icon:SetAlpha(1) end
    row:SetScript("OnEnter", function()
        local GameTooltip = M.Fonts:Tooltip()
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        local source = M.Call(C_TransmogCollection, "GetAppearanceSourceInfo", piece.sourceID)
        if source and source.itemLink then GameTooltip:SetHyperlink(source.itemLink)
        else GameTooltip:SetItemByID(piece.itemID) end
        GameTooltip:AddLine(M.L("SOURCE_ID", piece.sourceID), .7, .7, .7)
        for _, route in ipairs(routes) do
            if route.reference then GameTooltip:AddLine(M.L("REFERENCE", route.reference == "SOURCE_API" and M.L("SOURCE_API") or route.reference), .7, .7, .7, true) end
        end
        GameTooltip:Show()
        M.Fonts:TooltipFonts(GameTooltip)
    end)
    row:SetScript("OnLeave", function() M.Fonts:Tooltip():Hide() end)
    return row
end

function U:RefreshText()
    if self.picker then self.picker.close.caption:SetText(M.L("CLOSE")) end
end

function U:RenderDetail(set)
    local d = self.detail
    self.parts:Clear()
    d.missing.caption:SetText(M.L("MISSING_ONLY")); d.missing:SetChecked(M.Store.settings.missingOnly)
    self.modelNote:SetText(M.L("PREVIEW"))
    for _, b in ipairs(d.actions) do b:SetShown(set ~= nil) end
    if not set then
        d.title:SetText(M.L("CHOOSE")); d.meta:SetText(""); self.model:Hide(); self.modelSet = nil
        self.previewSources = nil; self.modelNote:Hide(); d.missing:Hide(); self.parts:Finish(); return
    end
    d.missing:Show(); self.modelNote:Show()
    d.title:SetText(self:SetName(set))
    local meta = set.info and (M.Expansion(set.info.expansionID) .. " · " .. (set.info.label or "") .. " · " .. (set.info.description or "")) or M.L("UNAVAILABLE")
    d.meta:SetText(meta .. " · " .. self:Progress(set))
    local metaY = 12 + d.title:GetStringHeight() + 8
    d.meta:ClearAllPoints(); d.meta:SetPoint("TOPLEFT", 12, -metaY)
    local missingY = metaY + d.meta:GetStringHeight() + 5
    d.missing:ClearAllPoints(); d.missing:SetPoint("TOPLEFT", 10, -missingY)
    local partsY = math.max(100, missingY + 34)
    self.parts.frame:ClearAllPoints(); self.parts.frame:SetPoint("TOPLEFT", 10, -partsY)
    self.parts.frame:SetHeight(math.max(80, d:GetHeight() - partsY - 8))
    local previewY = math.max(80, metaY + d.meta:GetStringHeight() + 8)
    local actionsY = d:GetHeight() - 108
    local noteY = actionsY - math.max(34, self.modelNote:GetStringHeight()) - 6
    self.model:ClearAllPoints(); self.model:SetPoint("TOPRIGHT", d, "TOPRIGHT", -8, -previewY)
    self.model:SetHeight(math.max(1, noteY - previewY - 6))
    self.modelNote:ClearAllPoints(); self.modelNote:SetPoint("TOPRIGHT", d, "TOPRIGHT", -8, -noteY)
    d.actions[1].caption:SetText(M.L(M.Store.profile.pinned == set.id and "UNPIN" or "PIN"))
    d.actions[2].caption:SetText(M.L("UP")); d.actions[3].caption:SetText(M.L("DOWN")); d.actions[4].caption:SetText(M.L("REMOVE"))
    d.actions[2]:SetEnabled(M.Store.settings.sort == "custom"); d.actions[3]:SetEnabled(M.Store.settings.sort == "custom")
    if set.status ~= "ready" then
        local row = self:Row(self.parts, 70); row.title:SetText(M.L(set.status == "loading" and "LOADING" or "UNAVAILABLE"))
        self.model:Hide(); self.modelSet, self.previewSources = nil, nil
    else
        for _, piece in ipairs(set.pieces) do
            if not M.Store.settings.missingOnly or not piece.collected then self:PieceRow(self.parts, piece, set.info.expansionID) end
        end
        if self.parts.count == 0 then local row = self:Row(self.parts, 70); row.title:SetText(M.L("NO_MISSING")) end
        self.model:Show()
        if self.modelSet ~= set.id then
            self.modelSet = set.id
            self.previewSources = {}
            for _, piece in ipairs(set.pieces) do self.previewSources[#self.previewSources + 1] = piece.sourceID end
            local success = self.model:SetUnit("player", false)
            if success == false then self.modelNote:SetText(M.L("PREVIEW_UNAVAILABLE"))
            elseif self.model:IsGeoReady() then self:ApplyPreview()
            else self.modelNote:SetText(M.L("LOADING")) end
        end
    end
    self.parts:Finish()
end

function U:ApplyPreview()
    if self.applyingPreview or not self.previewSources or not self.model:IsShown() then return end
    self.applyingPreview = true
    self.model:Undress(); self.model:SetPortraitZoom(self.zoom); self.model:SetRotation(self.rotation or 0, false)
    for _, sourceID in ipairs(self.previewSources) do self.model:TryOn(sourceID) end
    self.applyingPreview = nil
    self.modelNote:SetText(M.L("PREVIEW"))
end

function U:RenderWhere(sets)
    self.where:Clear()
    local groups, pending = M.Sources:Group(sets)
    for _, group in ipairs(groups) do
        local entry = group
        local row = self:Row(self.where, 65)
        row.title:SetText((self.expanded[group.key] and "− " or "+ ") .. (group.key == "UNKNOWN" and M.L("UNKNOWN") or group.key))
        row.body:SetText(M.L("RAID_COUNT", group.count) .. " · " .. M.L("ALTERNATIVES"))
        row:SetScript("OnClick", function() self.expanded[entry.key] = not self.expanded[entry.key]; self:Render() end)
        if self.expanded[group.key] then
            local ids = {}; for id in pairs(group.rows) do ids[#ids + 1] = id end; table.sort(ids)
            for _, id in ipairs(ids) do
                local item = group.rows[id]
                local names = {}; for _, name in pairs(item.sets) do names[#names + 1] = name end; table.sort(names)
                self:PieceRow(self.where, item.piece, nil, table.concat(names, ", "), item.routes)
            end
        end
    end
    if #groups == 0 or pending > 0 then
        local row = self:Row(self.where, 85)
        row.title:SetText(M.L(pending > 0 and "PENDING_SOURCES" or "NO_MISSING"))
    end
    self.where:Finish()
end

function U:ClassChoices()
    local choices = { { label = M.L("ALL"), value = 0 } }
    for id = 1, (GetNumClasses and GetNumClasses() or 13) do
        local info = M.Call(C_CreatureInfo, "GetClassInfo", id)
        if info then choices[#choices + 1] = { value = id, label = info.className } end
    end
    return choices
end

function U:FilterMenu(key)
    local choices = { { label = M.L("ALL"), value = false } }
    if key == "CLASS" then choices = self:ClassChoices()
    else
        local seen = {}
        for _, entry in pairs(M.Collection.catalog) do
            if entry.info.expansionID == self.expansion then
                if key == "RAID" then for raid in pairs(entry.raids) do seen[raid] = true end
                elseif entry.info.description then seen[entry.info.description] = true end
            end
        end
        local values = {}; for value in pairs(seen) do values[#values + 1] = value end; table.sort(values)
        for _, value in ipairs(values) do choices[#choices + 1] = { value = value, label = value } end
    end
    self:Choose(self.frame.catalogFilters[key], choices, function(value) self.filters[key] = value; self.catalogPage = 1; self:RenderCatalog() end)
end

function U:RenderCatalog()
    if not self.ready or not self.frame:IsShown() or self.view ~= "catalog" then return end
    self.catalog:Clear()
    if self.filters.CLASS == nil then self.filters.CLASS = select(3, UnitClass("player")) or 0 end
    local f, collection = self.frame, M.Collection
    f.note:SetText(M.L("CATALOG_NOTE"))
    f.status:SetText(collection.catalogAvailable and M.L("CATALOG_SCAN", collection.scanIndex, collection.scanList and #collection.scanList or 0) or M.L("LOADING"))
    for key, b in pairs(f.catalogFilters) do
        local value = self.filters[key]
        if key == "CLASS" then local info = M.Call(C_CreatureInfo, "GetClassInfo", value or 0); value = info and info.className end
        b.caption:SetText(M.L(key) .. ": " .. (value or M.L("ALL")))
    end
    local search = string.lower(f.search:GetText() or "")
    if f.search:GetText() == "" then
        if not f.search.hint then f.search.hint = self:Text(f.search, ""); f.search.hint:SetPoint("LEFT", 4, 0) end
        f.search.hint:SetText(M.L("SEARCH")); f.search.hint:Show()
    elseif f.search.hint then f.search.hint:Hide() end
    local entries = {}
    for _, entry in pairs(collection.catalog) do
        local info, classID = entry.info, self.filters.CLASS
        local classMatch = collection:MatchesClass(info, classID)
        local text = info.name .. " " .. (info.label or "") .. " " .. (info.description or "")
        for raid in pairs(entry.raids) do text = text .. " " .. raid end
        if info.expansionID == self.expansion and classMatch and (not self.filters.RAID or entry.raids[self.filters.RAID])
            and (not self.filters.VARIANT or info.description == self.filters.VARIANT)
            and string.find(string.lower(text), search, 1, true) then entries[#entries + 1] = entry end
    end
    table.sort(entries, function(a, b)
        if a.info.name ~= b.info.name then return a.info.name < b.info.name end
        return a.info.setID < b.info.setID
    end)
    local pages = math.max(1, math.ceil(#entries / 50))
    self.catalogPage = math.max(1, math.min(self.catalogPage or 1, pages))
    f.previousPage.caption:SetText(M.L("PREVIOUS")); f.previousPage:SetEnabled(self.catalogPage > 1)
    f.nextPage.caption:SetText(M.L("NEXT_PAGE")); f.nextPage:SetEnabled(self.catalogPage < pages)
    f.page:SetText(M.L("PAGE", self.catalogPage, pages))
    -- Bound the number of native frames even when the account knows thousands of sets.
    for index = (self.catalogPage - 1) * 50 + 1, math.min(#entries, self.catalogPage * 50) do
        local entry = entries[index]
        local info = entry.info
        local row = self:Row(self.catalog, 85)
        row.title:SetWidth(self.catalog.width - 138); row.title:SetText(info.name .. " · " .. (info.description or "") .. " · #" .. info.setID)
        local raids = {}; for raid in pairs(entry.raids) do raids[#raids + 1] = raid end; table.sort(raids)
        row.body:SetWidth(self.catalog.width - 138); row.body:SetText((info.label or "") .. " · " .. (#raids > 0 and table.concat(raids, ", ") or M.L("UNKNOWN")) .. "\n" .. M.L("EXPANSION") .. ": " .. M.Expansion(info.expansionID))
        row.body:SetPoint("TOPLEFT", 10, -math.max(31, row.title:GetStringHeight() + 14))
        local height = math.max(85, row.title:GetStringHeight() + row.body:GetStringHeight() + 27)
        self.catalog.y = self.catalog.y + height - row:GetHeight(); row:SetHeight(height)
        local selected = M.Store:Contains(info.setID)
        local add = self:Action(row, 1, M.L(selected and "REMOVE" or "ADD"), 114, function()
            if M.Store:Contains(info.setID) then M.Store:Remove(info.setID) else M.Store:Add(info) end
            M:Refresh()
        end); add:ClearAllPoints(); add:SetPoint("RIGHT", -14, 0)
    end
    if #entries == 0 then local row = self:Row(self.catalog, 75); row.title:SetText(M.L(collection.catalogAvailable and "NO_MATCH" or "LOADING")) end
    self.catalog:Finish()
end
