local _, M = ...
M.version = "0.2.1"
M.schema = 2
M.targetBuild = "12.1.5.70529"
M.modules = {}

function M.Call(namespace, name, ...)
    local fn = namespace and namespace[name]
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, ...)
    if ok then return result end
    M.lastAPIError = name -- No player data or arguments in diagnostics.
end

function M:Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66MogFocus|r: " .. message) end
end

-- Setup stages can be retried without losing the usable stages or saved data.
function M:TrySetup(stage, fn, ...)
    self.setupErrors = self.setupErrors or {}
    local ok, result = pcall(fn, ...)
    if not ok then
        if self.setupErrors[stage] ~= tostring(result) then self:Print(self.L("INIT_FAILED", stage)) end
        self.setupErrors[stage] = tostring(result)
        return false
    end
    self.setupErrors[stage] = nil
    return true, result
end

function M.Expansion(id)
    return _G["EXPANSION_NAME" .. tostring(id)] or tostring(id)
end

function M.ExpansionIDs()
    local ids = {}
    for id = 0, 30 do
        if _G["EXPANSION_NAME" .. id] then ids[#ids + 1] = id end
    end
    if #ids == 0 then ids = { 0, 1 } end
    return ids
end

function M.Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = M.Copy(v) end
    return out
end
