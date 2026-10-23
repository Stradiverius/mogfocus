local _, M = ...
local C = { cache = {}, expected = {}, requested = {}, transitions = {}, newParts = {}, catalog = {}, scanIndex = 0 }
M.Collection = C

function C:RequestItem(itemID)
    if itemID and not self.requested[itemID] then
        self.requested[itemID] = true
        M.Call(C_Item, "RequestLoadItemDataByID", itemID)
    end
end

function C:Invalidate()
    self.cache = {}
    M.Sources:Clear()
end

function C:Read(id)
    if self.cache[id] then return self.cache[id] end
    local info = M.Call(C_TransmogSets, "GetSetInfo", id)
    local result = { id = id, info = info, pieces = {}, status = "unavailable" }
    if not info then self.cache[id] = result; return result end
    result.status = "loading"
    local appearances = M.Call(C_TransmogSets, "GetSetPrimaryAppearances", id)
    if type(appearances) ~= "table" or #appearances == 0 then self.cache[id] = result; return result end
    local byVisual, valid = {}, true
    for _, primary in ipairs(appearances) do
        local sourceID = primary.appearanceID
        local source = type(sourceID) == "number" and M.Call(C_TransmogCollection, "GetSourceInfo", sourceID)
        if not source or not source.visualID or not source.itemID or type(primary.collected) ~= "boolean" then
            valid = false
        else
            local piece = byVisual[source.visualID]
            if piece then
                piece.collected = piece.collected or primary.collected
            else
                piece = { sourceID = sourceID, visualID = source.visualID, itemID = source.itemID,
                    collected = primary.collected, info = source }
                byVisual[source.visualID] = piece
                result.pieces[#result.pieces + 1] = piece
            end
            -- Item names are requested on demand by visible detail rows, not catalog scans.
        end
    end
    table.sort(result.pieces, function(a, b)
        if a.info.invType == b.info.invType then return a.sourceID < b.sourceID end
        return (a.info.invType or 0) < (b.info.invType or 0)
    end)
    local total, collected = #result.pieces, 0
    for _, piece in ipairs(result.pieces) do if piece.collected then collected = collected + 1 end end
    -- Retain known shape across temporary partial replies; never celebrate a truncated set.
    if self.expected[id] and self.expected[id] ~= #appearances then valid = false end
    if type(info.collected) ~= "boolean" or info.collected ~= (collected == total) then valid = false end
    if valid and total > 0 then
        self.expected[id] = #appearances
        result.status, result.total, result.collected = "ready", total, collected
        result.complete = info.collected and collected == total
    end
    self.cache[id] = result
    return result
end

function C:Observe(set, notify)
    if set.status ~= "ready" then return end
    local before = self.transitions[set.id]
    if before then
        for _, piece in ipairs(set.pieces) do
            if piece.collected and before.parts[piece.visualID] == false then
                self.newParts[piece.visualID] = GetTime() + 6
            end
        end
        if not before.complete and set.complete and not M.Store.profile.notified[set.id] then
            M.Store.profile.notified[set.id] = true
            if M.Store.settings.notifications then notify(set) end
        end
    end
    local parts = {}
    for _, piece in ipairs(set.pieces) do parts[piece.visualID] = piece.collected end
    self.transitions[set.id] = { complete = set.complete, parts = parts }
end

function C:Selected(expansionID)
    local sets = {}
    for _, id in ipairs(M.Store.profile.targets) do
        local set = self:Read(id)
        local meta = M.Store.profile.meta[id]
        local expansion = set.info and set.info.expansionID or meta and meta.expansionID
        if expansion == nil or expansionID == nil or expansion == expansionID then sets[#sets + 1] = set end
    end
    return sets
end

function C:Summary(sets)
    local summary = { total = #sets, complete = 0, pending = 0, collected = 0, appearances = 0 }
    for _, set in ipairs(sets) do
        if set.status ~= "ready" then summary.pending = summary.pending + 1
        else
            summary.collected = summary.collected + set.collected
            summary.appearances = summary.appearances + set.total
            if set.complete then summary.complete = summary.complete + 1 end
        end
    end
    if #sets > 0 and summary.pending == 0 then
        summary.percent = math.floor(100 * summary.collected / math.max(1, summary.appearances))
    end
    summary.done = #sets > 0 and summary.pending == 0 and summary.complete == #sets
    return summary
end

function C:BeginCatalog()
    if self.scanList and #self.scanList > 0 then return end
    local all = M.Call(C_TransmogSets, "GetAllSets") or {}
    self.catalogAvailable = #all > 0
    local seen, seenBases, list = {}, {}, {}
    local function add(info)
        if info and info.setID and not seen[info.setID] then
            seen[info.setID] = true; list[#list + 1] = info
        end
    end
    for _, info in ipairs(all) do
        add(info)
        local base = info.baseSetID or info.setID
        if not seenBases[base] then
            seenBases[base] = true
            for _, variant in ipairs(M.Call(C_TransmogSets, "GetVariantSets", base) or {}) do add(variant) end
        end
    end
    local expansion = M.UI and M.UI.expansion or M.Store.profile.focus
    table.sort(list, function(a, b)
        if (a.expansionID == expansion) ~= (b.expansionID == expansion) then return a.expansionID == expansion end
        return a.setID < b.setID
    end)
    self.catalog = {}
    for _, info in ipairs(list) do
        -- Same hidden-until-collected rule used by Wardrobe variant menus.
        -- Do not apply the CURRENT Blizzard class/search filters to GetAllSets.
        if self:IsCatalogVisible(info) then
            self.catalog[info.setID] = { info = info, raids = {}, sourcesPending = true }
        end
    end
    self.scanList, self.scanIndex = list, 0
end

function C:IsCatalogVisible(info)
    return info and not (info.hiddenUntilCollected and not info.collected)
end

function C:MatchesClass(info, classID)
    if not classID or classID == 0 then return true end
    local mask = info.classMask
    return type(mask) == "number" and (mask == 0 or math.floor(mask / 2 ^ (classID - 1)) % 2 == 1)
end

-- Snapshot real IDs for a group; GetVariantSets omits the base, unlike Blizzard's
-- SetsDataProvider wrapper. Do not mutate the engine-owned tables.
function C:Variants(baseID)
    local seen, result = {}, {}
    local function add(info)
        if self:IsCatalogVisible(info) and info.setID and not seen[info.setID] then
            seen[info.setID] = true; result[#result + 1] = info
        end
    end
    add(M.Call(C_TransmogSets, "GetSetInfo", baseID))
    for _, info in ipairs(M.Call(C_TransmogSets, "GetVariantSets", baseID) or {}) do add(info) end
    table.sort(result, function(a, b) return a.setID < b.setID end)
    return result
end

function C:AuditCatalog()
    self:BeginCatalog()
    local expected, missing, count = {}, {}, 0
    for _, base in ipairs(M.Call(C_TransmogSets, "GetBaseSets") or {}) do
        for _, info in ipairs(self:Variants(base.setID)) do expected[info.setID] = true end
    end
    for id in pairs(expected) do
        count = count + 1
        if not self.catalog[id] then missing[#missing + 1] = id end
    end
    table.sort(missing)
    return count, missing -- Current Blizzard filters; repeat with each class in-game.
end

function C:ScanCatalogBatch()
    self:BeginCatalog()
    for _ = 1, 4 do
        if self.scanIndex >= #self.scanList then return false end
        self.scanIndex = self.scanIndex + 1
        local info = self.scanList[self.scanIndex]
        local entry = self.catalog[info.setID]
        local set, raids = entry and self:Read(info.setID), {}
        if set then
            for _, piece in ipairs(set.pieces) do
                for _, route in ipairs(M.Sources:Resolve(piece, info.expansionID, true)) do
                    if route.verified and route.raid then raids[route.raid] = true end
                end
            end
            entry.raids, entry.sourcesPending = raids, set.status ~= "ready"
        end
    end
    return self.scanIndex < #self.scanList
end
