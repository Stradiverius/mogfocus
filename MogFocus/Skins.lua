local _, M = ...
local T = { widgets = setmetatable({}, { __mode = "k" }) }
M.Skins = T
local WHITE = "Interface\\Buttons\\WHITE8X8"
T.styles = {
    Warcraft = { panel = { .035, .049, .075, 1 }, card = { .065, .085, .12, 1 }, header = { .14, .16, .19, 1 },
        border = { .32, .27, .18, 1 }, text = { .94, .93, .88 }, muted = { .64, .68, .73 }, accent = { .92, .71, .36 }, selected = { .14, .13, .10, 1 } },
    Obsidian = { panel = { .028, .032, .043, 1 }, card = { .07, .08, .10, 1 }, header = { .12, .14, .18, 1 },
        border = { .22, .25, .30, 1 }, text = { .93, .95, .98 }, muted = { .58, .63, .70 }, accent = { .55, .74, .92 }, selected = { .12, .16, .21, 1 } },
    Arcane = { panel = { .045, .028, .085, 1 }, card = { .09, .065, .15, 1 }, header = { .19, .11, .28, 1 },
        border = { .33, .22, .46, 1 }, text = { .95, .92, 1 }, muted = { .68, .61, .80 }, accent = { .73, .55, 1 }, selected = { .19, .11, .27, 1 } },
}

function T:Style()
    local style = M.Copy(self.styles[M.Store.settings.skin] or self.styles.Warcraft)
    if M.Store.settings.skin == "Obsidian" then
        local _, class = UnitClass("player")
        local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then style.accent = { c.r, c.g, c.b } end
    end
    return style
end

function T:Gradient(texture, color, alpha, orientation)
    texture:SetTexture(WHITE)
    texture:SetGradient(orientation or "HORIZONTAL", CreateColor(color[1], color[2], color[3], alpha), CreateColor(color[1], color[2], color[3], 0))
end

function T:Register(widget, role)
    self.widgets[widget] = role
    self:Apply(widget, role)
    return widget
end

function T:Apply(widget, role)
    local s = self:Style()
    if role == "text" or role == "title" or role == "hero" or role == "muted" or role == "kicker" then
        M.Fonts:Apply(widget)
        local c = (role == "hero" or role == "kicker") and s.accent or role == "muted" and s.muted or s.text
        widget:SetTextColor(unpack(c))
        return
    end
    local prominent = role == "heroPanel" or role == "window" or role == "stage"
    local selected = widget.selected or widget.primary
    widget:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, tile = false, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    widget:SetBackdropColor(unpack(selected and s.selected or (role == "panel" or role == "window" or role == "stage") and s.panel or s.card))
    widget:SetBackdropBorderColor(unpack(selected and s.accent or s.border))
    if not widget.wash then
        widget.wash = widget:CreateTexture(nil, "BORDER", nil, -5)
        widget.wash:SetPoint("TOPLEFT", 1, -1); widget.wash:SetPoint("TOPRIGHT", -1, -1)
        widget.trim = widget:CreateTexture(nil, "BORDER", nil, -4)
        widget.trim:SetHeight(2); widget.trim:SetPoint("TOPLEFT", 1, -1); widget.trim:SetPoint("TOPRIGHT", -1, -1)
        widget.selectionMark = widget:CreateTexture(nil, "BORDER", nil, -3)
        widget.selectionMark:SetWidth(3); widget.selectionMark:SetPoint("TOPLEFT", 1, -1); widget.selectionMark:SetPoint("BOTTOMLEFT", 1, 1)
    end
    widget.wash:SetHeight(prominent and math.min(90, widget:GetHeight()) or math.min(32, widget:GetHeight()))
    self:Gradient(widget.wash, prominent and s.accent or s.header, prominent and .13 or .32, "VERTICAL")
    self:Gradient(widget.trim, s.accent, prominent and .9 or selected and .65 or .12)
    widget.selectionMark:SetColorTexture(unpack(s.accent)); widget.selectionMark:SetShown(widget.selected == true)
    if widget.caption then
        M.Fonts:Apply(widget.caption, "button")
        widget.caption:SetTextColor(unpack(selected and s.accent or s.text))
    end
    if widget.GetHighlightTexture and widget:GetHighlightTexture() then
        widget:GetHighlightTexture():SetVertexColor(s.accent[1], s.accent[2], s.accent[3], .12)
    end
    if prominent then
        if not widget.corners then
            widget.corners = {}
            for _, point in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
                local x, y = point:find("LEFT") and 5 or -5, point:find("TOP") and -5 or 5
                for _, size in ipairs({ { 20, 1 }, { 1, 20 } }) do
                    local line = widget:CreateTexture(nil, "OVERLAY")
                    line:SetSize(size[1], size[2]); line:SetPoint(point, x, y)
                    widget.corners[#widget.corners + 1] = line
                end
            end
        end
        for _, line in ipairs(widget.corners) do line:SetColorTexture(s.accent[1], s.accent[2], s.accent[3], .55) end
    end
    if role == "stage" then
        if not widget.halo then
            widget.halo = widget:CreateTexture(nil, "BORDER", nil, -6)
            widget.halo:SetAtlas("GarrMission-AbilityHighlight"); widget.halo:SetDesaturated(true)
            widget.halo:SetPoint("CENTER", 0, 20); widget.halo:SetBlendMode("ADD")
        end
        local size = math.max(40, math.min(widget:GetWidth(), widget:GetHeight()) - 26)
        widget.halo:SetSize(size, size); widget.halo:SetVertexColor(s.accent[1], s.accent[2], s.accent[3], .15)
    end
end

function T:Refresh()
    for widget, role in pairs(self.widgets) do self:Apply(widget, role) end
end
