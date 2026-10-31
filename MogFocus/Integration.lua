local _, M = ...
local I = {}
M.Integration = I

local function tabAt(journal, id)
    return journal.Tabs and journal.Tabs[id] or _G[journal:GetName() .. "Tab" .. id]
end

function I:TabFonts()
    local tab = self.tab
    tab:SetNormalFontObject(M.Fonts.objects.tabNormal)
    tab:SetHighlightFontObject(M.Fonts.objects.tabSelected)
    tab:SetDisabledFontObject(M.Fonts.objects[tab.isDisabled and "tabDisabled" or "tabSelected"])
    local role = tab.isDisabled and "tabDisabled" or (self.active and "tabSelected" or "tabNormal")
    M.Fonts:Apply(tab:GetFontString(), role)
end

function I:LayoutTab()
    if not self.tab or InCombatLockdown() then return end
    local journal, campsites = CollectionsJournal, CollectionsJournal.WarbandScenesTab
    if not campsites then return end
    self.tab:ClearAllPoints()
    self.tab:SetPoint("TOPLEFT", campsites, "TOPRIGHT", 3, 0)
    local previous = self.tab
    -- Keep any other addon/future tabs AFTER MogFocus in their existing ID order.
    for id = campsites:GetID() + 1, journal.numTabs do
        local tab = tabAt(journal, id)
        if tab and tab ~= self.tab then
            tab:ClearAllPoints(); tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", 3, 0); previous = tab
        end
    end
    self:TabFonts()
    PanelTemplates_TabResize(self.tab, 0)
    -- Geometry only: our tab is deliberately outside the native tab registry.
    PanelTemplates_ResizeTabsToFit(journal, journal:GetWidth() - 27 - self.tab:GetWidth())
end

function I:Deactivate(restoreNative)
    self.active = false
    if self.content then self.content:Hide() end
    if self.cover then self.cover:Hide() end
    if M.UI.frame then M.UI.frame:Hide() end
    if not self.tab then return end
    PanelTemplates_DeselectTab(self.tab); self:TabFonts()
    if restoreNative then
        local native = tabAt(CollectionsJournal, PanelTemplates_GetSelectedTab(CollectionsJournal))
        if native and not native.isDisabled then PanelTemplates_SelectTab(native) end
        if self.nativeTitle then CollectionsJournal:SetTitle(self.nativeTitle) end
    end
    self.nativeTitle = nil
end

function I:OnTab(journal)
    if journal ~= CollectionsJournal or not self.collectionsReady or not M.UI.ready then return end
    -- A genuine native click has already updated its own page and title.
    self:Deactivate(false)
    self:LayoutTab()
end

function I:Activate()
    if InCombatLockdown() then M:Print(M.L("COMBAT")); return end
    if not self:Collections() then return end
    local journal = CollectionsJournal
    if not journal:IsShown() then securecallfunction(ShowUIPanel, journal) end
    local opening = not self.active
    if opening then
        self.nativeTitle = journal:GetTitleText():GetText()
        M.UI.expansion, M.UI.view, M.UI.selected = M.Store.profile.focus, "sets", M.Store.profile.pinned
    end
    self.active = true
    -- Select/deselect change only tab visuals and button enable state. They do
    -- not write selectedTab/numTabs/isDisabled or show/update native pages.
    local native = tabAt(journal, PanelTemplates_GetSelectedTab(journal))
    if native and not native.isDisabled then PanelTemplates_DeselectTab(native) end
    PanelTemplates_SelectTab(self.tab); self:TabFonts()
    journal:SetTitle("MogFocus")
    self.cover:Show(); self.content:Show(); M.UI.frame:Show()
    M.UI:Layout(); M:Refresh(true)
end

function I:Collections()
    if not M.ready or not CollectionsJournal then return false end
    if InCombatLockdown() then self.pendingCollections = true; return false end
    if self.installing then return false end
    local journal = CollectionsJournal
    if not journal.WarbandScenesTab then return false end
    if self.collectionsReady and M.UI.ready then
        self:LayoutTab(); M:TrySetup("Menu", self.RegisterMenus, self)
        return true
    end
    self.installing = true
    local ok, complete = M:TrySetup("Collections", self.BuildCollections, self, journal)
    self.installing = nil
    if not ok or not complete then
        self.collectionsReady, self.pendingCollections = nil, true
        if self.content then self.content:Hide() end
        return false
    end
    M:TrySetup("Menu", self.RegisterMenus, self)
    return true
end

function I:BuildCollections(journal)
    -- Install this first: reopening normal Collections can finish failed setup.
    if not self.showHooked then
        journal:HookScript("OnShow", function()
            if not self.collectionsReady then self:Collections() end
            self:LayoutTab()
        end)
        journal:HookScript("OnHide", function() self:Deactivate(true) end)
        self.showHooked = true
    end
    if not self.content then
        self.content = CreateFrame("Frame", nil, journal)
        self.content:Hide()
        self.content:SetPoint("TOPLEFT", journal, "TOPLEFT", 8, -60)
        self.content:SetPoint("BOTTOMRIGHT", journal, "BOTTOMRIGHT", -8, 8)
        self.content:SetFrameLevel(journal:GetFrameLevel() + 20)
    end
    if not self.cover then
        -- Cover native search/progress controls without hiding or refreshing
        -- their pages (ToyBox OnShow writes fields later consumed by UseToy).
        self.cover = M.UI:Panel(journal)
        self.cover:Hide(); self.cover:EnableMouse(true)
        self.cover:SetPoint("TOPLEFT", journal, "TOPLEFT", 62, -28)
        self.cover:SetPoint("BOTTOMRIGHT", journal, "TOPRIGHT", -8, -60)
        self.cover:SetFrameLevel(journal:GetFrameLevel() + 20)
    end
    if not M.UI:Create(self.content) then return false end
    if not self.tab then
        -- PanelTabButtonTemplate has parentArray="Tabs". A private parent is
        -- essential: parenting it to the journal would taint journal.Tabs even
        -- without an explicit assignment. Never register a native numeric ID.
        self.tabHost = CreateFrame("Frame", nil, journal)
        self.tabHost:SetAllPoints(journal)
        local tab = CreateFrame("Button", "MogFocusCollectionsTab", self.tabHost, "PanelTabButtonTemplate")
        self.tab = tab
        tab:Hide(); tab:SetText("MogFocus")
        tab:SetScript("OnClick", function() self:Activate() end)
        PanelTemplates_DeselectTab(tab)
    end
    if not self.eventRegistered then
        EventRegistry:RegisterCallback("CollectionsJournal.TabSet", function(_, frame) self:OnTab(frame) end, self)
        self.eventRegistered = true
    end
    if not self.sizeHooked then
        journal:HookScript("OnSizeChanged", function() self:LayoutTab(); M.UI:Layout() end)
        self.sizeHooked = true
    end
    if not self.anchorHooked then
        hooksecurefunc("PanelTemplates_AnchorTabs", function(frame) if frame == journal then self:LayoutTab() end end)
        self.anchorHooked = true
    end
    self:LayoutTab()
    self.collectionsReady = true
    self.pendingCollections = nil
    self.tab:Show()
    self:Deactivate(false)
    return true
end

function I:Open()
    if IsLoggedIn() then M:Initialize() end
    if not M.ready then M:Print(M.L(M.blocked or "NO_PROFILE")); return end
    if InCombatLockdown() then M:Print(M.L("COMBAT")); return end
    if not CollectionsJournal then C_AddOns.LoadAddOn("Blizzard_Collections") end
    if not self:Collections() then M:Print(M.L("COLLECTIONS_UNAVAILABLE")); return end
    if CollectionsJournal:IsShown() and self.active and M.UI.frame:IsShown() then
        securecallfunction(HideUIPanel, CollectionsJournal)
    else
        self:Activate()
    end
end

function I:SetTracked(id, tracked)
    local info = M.Call(C_TransmogSets, "GetSetInfo", id)
    if not info then M:Print(M.L("UNAVAILABLE")); return end
    if tracked then
        if M.Store:Add(info) then M:Message("TRACK_ADDED", info.name) end
    elseif M.Store:Contains(id) then
        M.Store:Remove(id); M:Message("TRACK_REMOVED", info.name)
    end
    M:Refresh()
end

function I:VariantActions(parent, info)
    local tracked = M.Store:Contains(info.setID)
    if tracked then M.Fonts:Menu(parent:CreateTitle(M.L("ALREADY_TRACKED"))) end
    -- Capture immutable IDs when the menu opens, never a reused row in the action.
    local id, guid = info.setID, UnitGUID("player")
    M.Fonts:Menu(parent:CreateButton(M.L(tracked and "REMOVE_FROM" or "ADD_TO"), function()
        if UnitGUID("player") == guid then self:SetTracked(id, not tracked) end
    end))
end

function I:RegisterMenus()
    if self.menuRegistered or not Menu or not Menu.ModifyMenu then return end
    Menu.ModifyMenu("MENU_WARDROBE_SETS_SET", function(owner, root)
        if not M.ready or not owner or type(owner.setID) ~= "number" then return end
        local variants = M.Collection:Variants(owner.setID)
        if #variants == 0 then return end
        root:CreateDivider()
        if #variants == 1 then self:VariantActions(root, variants[1])
        else
            local submenu = M.Fonts:Menu(root:CreateButton("MogFocus"))
            for _, info in ipairs(variants) do
                local label = (info.description or info.name) .. " · #" .. info.setID
                local variant = M.Fonts:Menu(submenu:CreateButton(label))
                self:VariantActions(variant, info)
            end
        end
    end)
    self.menuRegistered = true
end

function I:Minimap()
    if self.minimap or not Minimap then return end
    local b = CreateFrame("Button", nil, Minimap)
    b:SetSize(32, 32); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel() + 6)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp"); b:RegisterForDrag("LeftButton")
    b.icon = b:CreateTexture(nil, "BACKGROUND"); b.icon:SetTexture("Interface\\Icons\\INV_Helmet_03")
    b.icon:SetSize(21, 21); b.icon:SetPoint("CENTER")
    local border = b:CreateTexture(nil, "OVERLAY"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54); border:SetPoint("TOPLEFT")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:SetScript("OnClick", function(_, button)
        if button == "RightButton" then M.Options:Open() else M.UI:Toggle() end
    end)
    b:SetScript("OnDragStart", function(button)
        button:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            M.Store.settings.minimapAngle = math.deg(math.atan2(y / scale - my, x / scale - mx))
            self:PositionMinimap()
        end)
    end)
    b:SetScript("OnDragStop", function(button) button:SetScript("OnUpdate", nil) end)
    b:SetScript("OnHide", function(button) button:SetScript("OnUpdate", nil) end)
    b:SetScript("OnEnter", function(button)
        local GameTooltip = M.Fonts:Tooltip()
        local summary = M.Collection:Summary(M.Collection:Selected(M.Store.profile.focus))
        GameTooltip:SetOwner(button, "ANCHOR_LEFT"); GameTooltip:ClearLines(); GameTooltip:AddLine("MogFocus")
        GameTooltip:AddLine(M.L("SUMMARY", summary.complete, summary.total), 1, 1, 1)
        if summary.pending > 0 then GameTooltip:AddLine(M.L("SUMMARY_PENDING", summary.pending), 1, 1, 1) end
        GameTooltip:AddLine(M.L("MINIMAP_TIP"), .8, .8, .8, true); GameTooltip:Show(); M.Fonts:TooltipFonts(GameTooltip)
    end)
    b:SetScript("OnLeave", function() M.Fonts:Tooltip():Hide() end)
    self.minimap = b; self:PositionMinimap()
end

function I:PositionMinimap()
    if not self.minimap then return end
    local angle = math.rad(M.Store.settings.minimapAngle or 220)
    local rx, ry = Minimap:GetWidth() / 2 + 8, Minimap:GetHeight() / 2 + 8
    self.minimap:ClearAllPoints(); self.minimap:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * rx, math.sin(angle) * ry)
end

function I:Update()
    self:Collections()
    M:TrySetup("Menu", self.RegisterMenus, self)
    M:TrySetup("Minimap", self.Minimap, self)
    if self.minimap then self.minimap:SetShown(M.Store.settings.minimap) end
end
