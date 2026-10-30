Functions.stash = {}

local oneStashes = {}

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
    elseif (Inventory == "ONE") then
        oneStashes[id] = {
            id = id,
            label = label,
            slots = slots,
            maxWeight = weight,
        }
    end
end

if (Inventory == "ONE") then
    ---@param _ PlayerId
    ---@param id string
    ---@return table? stash
    Functions.callback.register(ResName .. ":GetOneStash", function(_, id)
        return oneStashes[id]
    end)
end

---@param id string @ Unique stash identifier
---@param plyId integer @ Server ID of the player to open the stash for
---@diagnostic disable-next-line: duplicate-set-field
function Functions.stash.open(id, plyId)
    if (Inventory == "OX") then
        return exports["ox_inventory"]:forceOpenInventory(plyId, "stash", id)
    elseif (Inventory == "ONE") then
        return exports["one_inventory"]:OpenInventory(plyId, "stash", oneStashes[id] or {id = id})
    end
end

---@param id string @ Unique stash identifier
---@return table? @ Stash data table, or nil if not found
function Functions.stash.get(id)
    if (Inventory == "OX") then
        return exports["ox_inventory"]:GetInventory(id)
    elseif (Inventory == "ONE") then
        return exports["one_inventory"]:GetInventory("stash:" .. id)
    end

    return nil
end

---@param id string @ Unique stash identifier
---@return boolean success @ Whether the stash was cleared, or the active inventory has no persistent stash cleanup
---@return any? err @ Error returned by the inventory export, if one was raised
function Functions.stash.clear(id)
    if (type(id) ~= "string" or id == "") then return false, "invalidStash" end

    local ok, result

    if (Inventory == "OX") then
        ok, result = pcall(function()
            return exports["ox_inventory"]:ClearInventory(id)
        end)
    elseif (Inventory == "ONE") then
        return exports["one_inventory"]:ClearInventory("stash:" .. id)
    elseif (Inventory == "QS") then
        ok, result = pcall(function()
            return exports["qs-inventory"]:ClearOtherInventory("stash", id)
        end)
    elseif (Inventory == "TGIANN") then
        ok, result = pcall(function()
            return exports["tgiann-inventory"]:DeleteInventory("stash", id)
        end)
    elseif (Inventory == "CODEM") then
        ok, result = pcall(function()
            return exports["codem-inventory"]:UpdateStash(id, {})
        end)
    elseif (Inventory == "C8RE") then
        ok, result = pcall(function()
            return exports["core_inventory"]:clearInventory(id)
        end)
    elseif (Framework == "QB" and GetResourceState("qb-inventory") == "started") then
        ok, result = pcall(function()
            -- qb-inventory's ClearStash only updates stashes that exist in its
            -- in-memory Inventories table, so seed that table before clearing
            exports["qb-inventory"]:CreateInventory(id, {})
            return exports["qb-inventory"]:ClearStash(id)
        end)
    else
        return true
    end

    if (not ok) then return false, result end

    return result ~= false, result
end

-- Stash items by exact slot work on the inventories whose stashes register and open above
---@return boolean supported
function Functions.stash.supportsItems()
    return Inventory == "OX" or Inventory == "ONE"
end

---@param id string @ Unique stash identifier
---@return Item[] items @ Occupied slots only, empty when the inventory has no stash items
function Functions.stash.getItems(id)
    local rawItems

    if (Inventory == "OX") then
        rawItems = exports["ox_inventory"]:GetInventoryItems(id)
    elseif (Inventory == "ONE") then
        rawItems = exports["one_inventory"]:GetInventoryItems("stash:" .. id)
    end

    local items = {}
    for _, rawItem in pairs(rawItems or {}) do
        local item = Formatting.formatItem(rawItem)
        if (item and item.slot) then items[#items + 1] = item end
    end

    return items
end

---@param id string @ Unique stash identifier
---@param slot integer
---@return Item? item
function Functions.stash.getSlot(id, slot)
    if (Inventory == "OX") then
        return Formatting.formatItem(exports["ox_inventory"]:GetSlot(id, slot))
    elseif (Inventory == "ONE") then
        return Formatting.formatItem(exports["one_inventory"]:GetSlot("stash:" .. id, slot))
    end

    return nil
end

-- Fill check included, false when the items don't fit
---@param id string @ Unique stash identifier
---@param name string
---@param count integer
---@param metadata? table
---@return boolean added
function Functions.stash.addItem(id, name, count, metadata)
    local added = false

    if (Inventory == "OX") then
        added = exports["ox_inventory"]:AddItem(id, name, count, metadata)
    elseif (Inventory == "ONE") then
        added = exports["one_inventory"]:AddItem("stash:" .. id, name, count, metadata)
    end

    return added == true
end

-- With a slot, removes only when that slot holds the item and enough of it, since ox_inventory takes the rest from
-- other slots otherwise
---@param id string @ Unique stash identifier
---@param name string
---@param count integer
---@param slot? integer
---@return boolean removed
function Functions.stash.removeItem(id, name, count, slot)
    if (not Functions.stash.supportsItems()) then return false end

    if (slot) then
        local item = Functions.stash.getSlot(id, slot)
        if (not item or item.name ~= name or item.amount < count) then return false end
    end

    local removed = false

    if (Inventory == "OX") then
        removed = exports["ox_inventory"]:RemoveItem(id, name, count, nil, slot)
    elseif (Inventory == "ONE") then
        removed = exports["one_inventory"]:RemoveItem("stash:" .. id, name, count, nil, slot)
    end

    return removed == true
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