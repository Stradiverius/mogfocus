local _, M = ...
local T = { widgets = setmetatable({}, { __mode = "k" }) }
M.Skins = T
T.styles = {
    Warcraft = { bg = "Interface\\DialogFrame\\UI-DialogBox-Background", edge = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        panel = { .12, .10, .07, .98 }, card = { .18, .15, .10, 1 }, border = { .65, .49, .24, 1 }, text = { 1, .95, .82 }, accent = { 1, .78, .28 }, font = "GameFontNormal" },
    Obsidian = { bg = "Interface\\Buttons\\WHITE8X8", edge = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        panel = { .055, .065, .075, .99 }, card = { .12, .135, .15, 1 }, border = { .28, .30, .33, 1 }, text = { .93, .94, .96 }, accent = { .6, .75, .9 }, font = "GameFontHighlight" },
    Arcane = { bg = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edge = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
        panel = { .08, .05, .23, .99 }, card = { .16, .10, .30, 1 }, border = { .62, .59, .85, 1 }, text = { .90, .91, 1 }, accent = { .68, .70, 1 }, font = "GameFontNormal" },
}

function T:Style()
    local style = M.Copy(self.styles[M.Store.settings.skin] or self.styles.Warcraft)
    if M.Store.settings.skin == "Obsidian" then
        local _, class = UnitClass("player")
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then style.accent = { color.r, color.g, color.b } end
    end
    return style
end

function T:Register(widget, role)
    self.widgets[widget] = role
    self:Apply(widget, role)
    return widget
end

function T:Apply(widget, role)
    local s = self:Style()
    if role == "text" or role == "title" then
        local color = role == "title" and s.accent or s.text
        widget:SetTextColor(unpack(color))
        return
    end
    widget:SetBackdrop({ bgFile = s.bg, edgeFile = s.edge, tile = true, tileSize = 64,
        edgeSize = s.edgeSize, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    widget:SetBackdropColor(unpack(role == "panel" and s.panel or s.card))
    widget:SetBackdropBorderColor(unpack(widget.selected and s.accent or s.border))
    if widget.caption then
        widget.caption:SetFontObject(_G[s.font])
        widget.caption:SetTextColor(unpack(s.text))
    end
    if not widget.trim then
        widget.trim = widget:CreateTexture(nil, "ARTWORK")
        widget.trim:SetPoint("TOPLEFT", 6, -4)
        widget.trim:SetPoint("TOPRIGHT", -6, -4)
        widget.trim:SetHeight(2)
    end
    widget.trim:SetColorTexture(unpack(s.accent))
    widget.trim:SetAlpha(M.Store.settings.skin == "Arcane" and .55 or .12)
end

function T:Refresh()
    for widget, role in pairs(self.widgets) do self:Apply(widget, role) end
end
