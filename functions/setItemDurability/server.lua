-- qs-inventory and the QB inventories keep the 0-100 condition in quality, the others in durability
local qualityInventories = {QS = true, DEFAULT = true}

---@param item Item
---@param metadata table<string, any>
---@return number? minutes @ Minutes an ox_inventory item takes to decay from full, nil when it does not decay
local function getOxDegrade(item, metadata)
    local degrade = tonumber(metadata.degrade)

    if (not degrade) then
        local _, itemName = Functions.getItem(item.name)

        degrade = itemName and tonumber(Items[itemName]?.degrade)
    end

    return degrade and degrade > 0 and degrade or nil
end

-- TGIANN keeps a decaying item's condition as a timestamp it ages itself, and has no export to set it by percent
---@param item Item
---@return boolean decays
local function isTgiannDecaying(item)
    if (not item.info?.durability) then return false end

    return (tonumber(exports["tgiann-inventory"]:GetItemDecayTime(item.name)) or 0) > 0
end

---@param plyId PlayerId
---@param slot integer
---@param durability number
---@return boolean written @ False when the slot is empty or the inventory can not set this item's condition
function Functions.setItemDurability(plyId, slot, durability)
    if (not slot) then return false end

    local item = Functions.getInventorySlot(plyId, slot)
    if (not item) then return false end
    if (Inventory == "TGIANN" and isTgiannDecaying(item)) then return false end

    local metadata = {}
    if (item.metadata) then
        for k, v in pairs(item.metadata) do
            metadata[k] = v
        end
    end

    local percent = math.max(0, math.min(100, tonumber(durability) or 100))
    local degrade = Inventory == "OX" and getOxDegrade(item, metadata)

    if (qualityInventories[Inventory]) then
        metadata.quality = percent
        metadata.durability = nil
    elseif (degrade) then
        -- A decaying item keeps the time it runs out, so it goes on draining from the new condition
        metadata.durability = percent > 0 and math.floor(os.time() + degrade * 60 * percent / 100) or 0
        metadata.degrade = degrade
    else
        metadata.durability = percent
    end

    local result = Functions.setItemMetadata(plyId, slot, metadata)
    if (result == false) then return false end

    return true
end

return Functions.setItemDurability