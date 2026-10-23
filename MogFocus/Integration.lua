local _, M = ...
local I = {}
M.Integration = I

function I:Wardrobe()
    if self.wardrobe or not WardrobeCollectionFrame then return end
    if InCombatLockdown() then self.pendingWardrobe = true; return end
    -- A button beside the Wardrobe tabs. No tab IDs,
    -- protected methods, or Blizzard layouts are replaced. Only visible on this page.
    local b = M.UI:Button(WardrobeCollectionFrame, "MogFocus", 140, function() M.UI:Toggle() end)
    if WardrobeCollectionFrame.SetsTab then
        b:SetPoint("LEFT", WardrobeCollectionFrame.SetsTab, "RIGHT", 12, 0)
    else
        b:SetPoint("TOPLEFT", WardrobeCollectionFrame, "TOPLEFT", 245, -28)
    end
    b:SetFrameLevel(WardrobeCollectionFrame:GetFrameLevel() + 5)
    self.wardrobe, self.pendingWardrobe = b, nil
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
        local summary = M.Collection:Summary(M.Collection:Selected(M.Store.profile.focus))
        GameTooltip:SetOwner(button, "ANCHOR_LEFT"); GameTooltip:AddLine("MogFocus")
        GameTooltip:AddLine(M.L("SUMMARY", summary.complete, summary.total), 1, 1, 1)
        if summary.pending > 0 then GameTooltip:AddLine(M.L("SUMMARY_PENDING", summary.pending), 1, 1, 1) end
        GameTooltip:AddLine(M.L("MINIMAP_TIP"), .8, .8, .8, true); GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.minimap = b; self:PositionMinimap()
end

function I:PositionMinimap()
    if not self.minimap then return end
    local angle = math.rad(M.Store.settings.minimapAngle or 220)
    local rx, ry = Minimap:GetWidth() / 2 + 8, Minimap:GetHeight() / 2 + 8
    self.minimap:ClearAllPoints(); self.minimap:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * rx, math.sin(angle) * ry)
end

function I:Update()
    self:Wardrobe(); self:Minimap()
    if self.minimap then self.minimap:SetShown(M.Store.settings.minimap) end
end
