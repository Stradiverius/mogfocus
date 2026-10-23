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
    local role = tab.isDisabled and "tabDisabled" or (PanelTemplates_GetSelectedTab(CollectionsJournal) == tab:GetID() and "tabSelected" or "tabNormal")
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
    PanelTemplates_ResizeTabsToFit(journal, journal:GetWidth() - 24)
end

function I:OnTab(journal, selected)
    if journal ~= CollectionsJournal or not self.tab then return end
    local active = selected == self.tab:GetID()
    local opening = active and not self.content:IsShown()
    if active then
        -- Do not persist an addon-dependent numeric tab ID in Blizzard's CVar.
        SetCVar("petJournalTab", journal.WardrobeTab:GetID())
        journal:SetTitle("MogFocus")
        if opening then
            M.UI.expansion, M.UI.view, M.UI.selected = M.Store.profile.focus, "sets", M.Store.profile.pinned
        end
    end
    self.content:SetShown(active); M.UI.frame:SetShown(active)
    if active then M.UI:Layout(); M:Refresh(true) end
    self:LayoutTab()
end

function I:Collections()
    if not CollectionsJournal then return end
    if InCombatLockdown() then self.pendingCollections = true; return end
    if self.tab then self:LayoutTab(); self:RegisterMenus(); return end
    local journal = CollectionsJournal
    if not journal.WarbandScenesTab then return end
    local last = journal.numTabs or 0
    while tabAt(journal, last + 1) do last = last + 1 end
    local id = last + 1
    local tab = CreateFrame("Button", journal:GetName() .. "Tab" .. id, journal, "CollectionsJournalTab")
    tab:SetID(id); tab:SetText("MogFocus")
    if journal.Tabs then journal.Tabs[id] = tab end
    self.tab = tab
    self.content = CreateFrame("Frame", nil, journal)
    self.content:SetPoint("TOPLEFT", journal, "TOPLEFT", 8, -60)
    self.content:SetPoint("BOTTOMRIGHT", journal, "BOTTOMRIGHT", -8, 8)
    self.content:SetFrameLevel(journal:GetFrameLevel() + 10); self.content:Hide()
    M.UI:Create(self.content)
    PanelTemplates_SetNumTabs(journal, id)
    EventRegistry:RegisterCallback("CollectionsJournal.TabSet", function(_, frame, selected) self:OnTab(frame, selected) end, self)
    journal:HookScript("OnShow", function() self:OnTab(journal, PanelTemplates_GetSelectedTab(journal)) end)
    journal:HookScript("OnSizeChanged", function() self:LayoutTab(); M.UI:Layout() end)
    hooksecurefunc("PanelTemplates_AnchorTabs", function(frame) if frame == journal then self:LayoutTab() end end)
    hooksecurefunc("PanelTemplates_UpdateTabs", function(frame)
        if frame == journal then self:TabFonts() end
    end)
    self.pendingCollections = nil
    self:LayoutTab(); self:RegisterMenus()
    self:OnTab(journal, PanelTemplates_GetSelectedTab(journal))
end

function I:Open()
    if not M.ready then M:Print(M.L(M.blocked or "NO_PROFILE")); return end
    if InCombatLockdown() then M:Print(M.L("COMBAT")); return end
    if not CollectionsJournal then C_AddOns.LoadAddOn("Blizzard_Collections") end
    self:Collections()
    if not self.tab then M:Print(M.L("COLLECTIONS_UNAVAILABLE")); return end
    if CollectionsJournal:IsShown() and M.UI.frame:IsShown() and PanelTemplates_GetSelectedTab(CollectionsJournal) == self.tab:GetID() then
        HideUIPanel(CollectionsJournal)
    else
        ShowUIPanel(CollectionsJournal)
        CollectionsJournal_SetTab(CollectionsJournal, self.tab:GetID())
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
    self.menuRegistered = true
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
    self:Collections(); self:RegisterMenus(); self:Minimap()
    if self.minimap then self.minimap:SetShown(M.Store.settings.minimap) end
end
