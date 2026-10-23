local _, M = ...
local S = {}
M.Store = S
S.defaults = {
    language = "cs", skin = "Warcraft", minimap = true, minimapAngle = 220,
    compact = false, sort = "custom", hideComplete = false, missingOnly = false,
    notifications = true, sound = false, reduceMotion = false,
}

local function fill(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then target[key] = M.Copy(value) end
    end
end

function S:Open(db, guid)
    if not guid then return nil, "NO_PROFILE" end
    db = type(db) == "table" and db or {}
    if type(db.schema) == "number" and db.schema > M.schema then return nil, "NEWER_SCHEMA" end
    -- v1 used characters; merge without deleting the original migration input.
    db.profiles = db.profiles or {}
    if (db.schema or 1) < 2 and type(db.characters) == "table" then
        for key, profile in pairs(db.characters) do
            if not db.profiles[key] then db.profiles[key] = M.Copy(profile) end
        end
    end
    db.settings = db.settings or {}
    fill(db.settings, self.defaults)
    local profile = db.profiles[guid] or {}
    db.profiles[guid] = profile
    if not profile.targets and profile.selectedSets then profile.targets = M.Copy(profile.selectedSets) end
    fill(profile, { targets = {}, meta = {}, focus = 0, notified = {} })
    -- Normalize only the ordered ID list, preserving unknown profile fields.
    local seen, targets = {}, {}
    for _, id in ipairs(profile.targets) do
        id = tonumber(id)
        if id and id > 0 and id == math.floor(id) and not seen[id] then
            seen[id] = true
            targets[#targets + 1] = id
        end
    end
    profile.targets = targets
    if profile.pinned and not seen[profile.pinned] then profile.pinned = nil end
    db.schema = M.schema
    self.db, self.profile, self.settings = db, profile, db.settings
    return db
end

function S:Contains(id)
    for _, value in ipairs(self.profile.targets) do if value == id then return true end end
    return false
end

function S:Add(info)
    if self:Contains(info.setID) then return false end
    self.profile.targets[#self.profile.targets + 1] = info.setID
    self.profile.meta[info.setID] = { expansionID = info.expansionID }
    return true
end

function S:Remove(id)
    for index, value in ipairs(self.profile.targets) do
        if value == id then table.remove(self.profile.targets, index); break end
    end
    if self.profile.pinned == id then self.profile.pinned = nil end
    -- Keep metadata and notification history in case this exact variant is re-added.
end

function S:Move(id, delta)
    local targets = self.profile.targets
    for index, value in ipairs(targets) do
        if value == id then
            local to = math.max(1, math.min(#targets, index + delta))
            targets[index], targets[to] = targets[to], targets[index]
            return
        end
    end
end
