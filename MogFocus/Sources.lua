local _, M = ...
local R = { cache = {} }
M.Sources = R
local instanceNames = { [741] = "Molten Core", [742] = "Blackwing Lair", [745] = "Karazhan", [746] = "Gruul's Lair", [747] = "Magtheridon's Lair" }
local function routeKey(route)
    return table.concat({ route.raid or route.location or "", route.boss or "", route.method or "",
        tostring(route.tokenID or ""), route.difficulty or route.size or "" }, ":")
end

function R:Clear() self.cache = {} end

function R:ForSource(info, expansionID)
    local routes = {}
    local localRows = M.SourceData.items[info.itemID]
    if localRows then
        for _, row in ipairs(localRows) do
            if row.expansionID == expansionID then
                local route = M.Copy(row)
                route.raid = M.Call(_G, "EJ_GetInstanceInfo", row.instanceID) or instanceNames[row.instanceID]
                route.boss = row.encounterID and M.Call(_G, "EJ_GetEncounterInfo", row.encounterID)
                route.reference = M.SourceData.reference
                route.verified = true
                routes[#routes + 1] = route
            end
        end
    end
    -- As in Blizzard CollectionsUtil: only boss-drop sources have journal drops.
    -- Local curated data wins for legacy tokens and relocated original drops.
    if #routes == 0 and info.sourceType == TRANSMOG_SOURCE_BOSS_DROP then
        local drops = M.Call(C_TransmogCollection, "GetAppearanceSourceDrops", info.sourceID)
        for _, drop in ipairs(drops or {}) do
            if drop.instance and drop.encounter then
                routes[#routes + 1] = {
                    raid = drop.instanceType == INSTANCE_TYPE_RAID and drop.instance or nil,
                    location = drop.instance, boss = drop.encounter, method = "DIRECT",
                    difficulty = table.concat(drop.difficulties or {}, ", "), verified = true,
                    reference = "SOURCE_API",
                }
            end
        end
    end
    return routes
end

function R:Resolve(piece, expansionID, primaryOnly)
    local key = tostring(piece.sourceID) .. ":" .. tostring(expansionID) .. ":" .. tostring(primaryOnly)
    if self.cache[key] then return self.cache[key] end
    local routes = self:ForSource(piece.info, expansionID)
    if not primaryOnly then
        local alternatives = M.Call(C_TransmogCollection, "GetAppearanceSources", piece.visualID, piece.info.categoryID)
        for _, info in ipairs(alternatives or {}) do
            if info.sourceID ~= piece.sourceID and info.isValidSourceForPlayer == true then
                for _, route in ipairs(self:ForSource(info, expansionID)) do
                    route.alternative = true
                    routes[#routes + 1] = route
                end
            end
        end
    end
    local unique, result = {}, {}
    for _, route in ipairs(routes) do
        local signature = routeKey(route)
        if not unique[signature] then
            unique[signature] = true
            result[#result + 1] = route
        end
    end
    if #result == 0 then result[1] = { method = "UNKNOWN", verified = false } end
    self.cache[key] = result
    return result
end

function R:Text(route)
    if not route.verified then return M.L("UNKNOWN") end
    local parts = { route.raid or route.location or M.L("OTHER") }
    if route.boss then parts[#parts + 1] = route.boss end
    parts[#parts + 1] = M.L(route.method)
    if route.tokenID then
        local token = M.Call(C_Item, "GetItemInfo", route.tokenID)
        if not token then M.Collection:RequestItem(route.tokenID) end
        parts[#parts + 1] = M.L("TOKEN_PATH", route.boss or parts[1], token or M.L("ITEM_ID", route.tokenID), M.L(route.vendorKey))
    end
    if route.size then parts[#parts + 1] = M.L(route.size) end
    if route.difficulty and route.difficulty ~= "" then parts[#parts + 1] = route.difficulty end
    return table.concat(parts, " · ")
end

function R:Group(sets)
    local groups, pending = {}, 0
    for _, set in ipairs(sets) do
        if set.status ~= "ready" then pending = pending + 1
        else
            for _, piece in ipairs(set.pieces) do
                if not piece.collected then
                    for _, route in ipairs(self:Resolve(piece, set.info.expansionID)) do
                        local key = route.raid or (route.verified and route.location) or "UNKNOWN"
                        local group = groups[key] or { key = key, rows = {}, count = 0 }
                        groups[key] = group
                        local row = group.rows[piece.visualID]
                        if not row then
                            row = { piece = piece, sets = {}, routes = {}, routeKeys = {} }
                            group.rows[piece.visualID] = row
                            group.count = group.count + 1
                        end
                        row.sets[set.info.setID] = set.info.name
                        local signature = routeKey(route)
                        if not row.routeKeys[signature] then
                            row.routeKeys[signature] = true
                            row.routes[#row.routes + 1] = route
                        end
                    end
                end
            end
        end
    end
    local list = {}
    for _, group in pairs(groups) do list[#list + 1] = group end
    table.sort(list, function(a, b) return a.key < b.key end)
    return list, pending
end

function R:OpenJournal(route)
    if not route.instanceID or not route.verified then return end
    if InCombatLockdown() then M:Print(M.L("COMBAT")); return end
    local loaded = C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
    if loaded and EncounterJournal_OpenJournal then
        EncounterJournal_OpenJournal(nil, route.instanceID, route.encounterID)
    end
end
