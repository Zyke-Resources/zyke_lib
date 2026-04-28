Functions.stash = {}

---@type integer | nil
local qbInvMajor = nil

--- Returns the major version of qb-inventory if it can be determined, otherwise nil.
--- Result is cached after the first lookup.
---@return integer | nil
local function getQbInvMajor()
    if (qbInvMajor == nil) then
        local version = GetResourceMetadata("qb-inventory", "version", 0)
        local major = version and version:match("(%d+)")

        qbInvMajor = major and math.tointeger(major) or nil
    end

    return qbInvMajor
end

---@param id string @ Unique stash identifier
---@param label string @ Display label for the stash
---@param slots integer @ Number of slots
---@param weight integer @ Maximum weight in grams
function Functions.stash.register(id, label, slots, weight)
    if (Inventory == "OX") then
        local stash = Functions.stash.get(id)

        if (not stash) then
            exports["ox_inventory"]:RegisterStash(id, label, slots, weight)
        end
    end
end

---@param id string @ Unique stash identifier
---@param plyId integer @ Server ID of the player to open the stash for
---@diagnostic disable-next-line: duplicate-set-field
function Functions.stash.open(id, plyId)
    if (Inventory == "OX") then
        return exports["ox_inventory"]:forceOpenInventory(plyId, "stash", id)
    end
end

---@param id string @ Unique stash identifier
---@return table? @ Stash data table, or nil if not found
function Functions.stash.get(id)
    if (Inventory == "OX") then
        return exports["ox_inventory"]:GetInventory(id)
    end

    return nil
end

-- Internal handler for qb-inventory v2.x stash opens. The new version dropped the
-- inventory:server:OpenInventory event in favour of an OpenInventory export, so the
-- client routes here when v2.x is detected.
---@param invId string
---@param slots integer?
---@param weight integer?
RegisterNetEvent(ResName .. ":server:openStash", function(invId, slots, weight)
    local plyId = source

    if (Framework ~= "QB") then return end
    if (type(invId) ~= "string") then return end

    local major = getQbInvMajor()
    if (not major or major < 2) then return end

    exports["qb-inventory"]:OpenInventory(plyId, invId, {
        maxweight = tonumber(weight) or 4000,
        slots = tonumber(slots) or 20,
    })
end)

return Functions.stash