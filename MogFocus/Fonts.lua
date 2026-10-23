local _, M = ...
local F = { objects = {} }
M.Fonts = F

local colors = { tabNormal = { 1, .82, 0 }, tabDisabled = { .5, .5, .5 } }
for role, spec in pairs({ text = { 11, false }, button = { 12, false }, title = { 14, true }, menu = { 12, false },
    tabNormal = { 12, false }, tabSelected = { 12, false }, tabDisabled = { 12, false } }) do
    local font = CreateFont("MogFocusFont_" .. role)
    local path = "Interface\\AddOns\\MogFocus\\Fonts\\DejaVuSans" .. (spec[2] and "-Bold" or "") .. ".ttf"
    assert(font:SetFont(path, spec[1], ""), "MogFocus: bundled font could not load: " .. path)
    font:SetTextColor(unpack(colors[role] or { 1, 1, 1 }))
    font:SetShadowColor(0, 0, 0, .8); font:SetShadowOffset(0, -1)
    F.objects[role] = font
end

function F:Apply(region, role)
    role = role or region.mogFontRole or "text"
    region.mogFontRole = role
    region:SetFontObject(self.objects[role] or self.objects.text)
end

-- Private tooltip only: never change global GameTooltip or game FontObjects.
function F:Tooltip()
    if not M.Tooltip then
        M.Tooltip = CreateFrame("GameTooltip", "MogFocusTooltip", UIParent, "GameTooltipTemplate")
        if TooltipDataProcessor then
            TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip)
                if tooltip == M.Tooltip then self:TooltipFonts(tooltip) end
            end)
        end
    end
    return M.Tooltip
end

function F:TooltipFonts(tooltip)
    for index = 1, tooltip:NumLines() do
        for _, side in ipairs({ "Left", "Right" }) do
            local region = _G[tooltip:GetName() .. "Text" .. side .. index]
            if region then self:Apply(region) end
        end
    end
end

function F:Menu(description)
    description:AddInitializer(function(button)
        if button.fontString then self:Apply(button.fontString, "menu") end
    end)
    return description
end
