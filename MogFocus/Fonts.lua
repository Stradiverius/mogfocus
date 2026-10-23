local _, M = ...
local F = { objects = {} }
M.Fonts = F

local colors = { tabNormal = { 1, .82, 0 }, tabDisabled = { .5, .5, .5 } }
local roles = { text = { 11, false }, button = { 12, false }, title = { 14, true }, menu = { 12, false },
    tabNormal = { 12, false }, tabSelected = { 12, false }, tabDisabled = { 12, false } }

function F:Initialize()
    if self.ready then return end
    self.fallback = false
    for role, spec in pairs(roles) do
        local font = self.objects[role] or CreateFont("MogFocusFont_" .. role)
        self.objects[role] = font
        local path = "Interface\\AddOns\\MogFocus\\Fonts\\DejaVuSans" .. (spec[2] and "-Bold" or "") .. ".ttf"
        -- SimpleFont:SetFont returns nothing (unlike FontString:SetFont).
        -- Check the applied font, and keep asset errors from aborting the file.
        local ok = pcall(function()
            font:SetFont(path, spec[1], "")
            local applied, height = font:GetFont()
            assert(type(applied) == "string" and applied:lower():gsub("/", "\\") == path:lower() and height > 0)
        end)
        if not ok then
            -- Inherit into OUR object only; never mutate Blizzard's font.
            font:SetFontObject(GameFontNormal)
            font:SetFontHeight(spec[1])
            self.fallback = true
        end
        font:SetTextColor(unpack(colors[role] or { 1, 1, 1 }))
        font:SetShadowColor(0, 0, 0, .8); font:SetShadowOffset(0, -1)
    end
    self.ready = true
end

function F:Apply(region, role)
    self:Initialize()
    role = role or region.mogFontRole or "text"
    region.mogFontRole = role
    region:SetFontObject(self.objects[role] or self.objects.text)
end

function F:Report()
    if self.fallback and not self.warned then
        self.warned = true
        M:Print(M.L("FONT_FALLBACK"))
    end
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

-- Define every public method before touching font assets.
F:Initialize()
