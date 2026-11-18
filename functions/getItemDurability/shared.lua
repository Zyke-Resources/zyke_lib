-- qs-inventory and the QB inventories keep the 0-100 condition in quality, setItemDurability writes it there as well
local qualityInventories = {QS = true, DEFAULT = true}

---@param item Item | table | nil
---@return number
function Functions.getItemDurability(item)
    local metadata = item and (item.metadata or item.info)
    if (not metadata) then return 100 end

    local durability = metadata.durability
    if (durability == nil or (qualityInventories[Inventory] and metadata.quality ~= nil)) then durability = metadata.quality end

    durability = tonumber(durability) or 100

    -- ox_inventory keeps the time a decaying item runs out in durability, with its minutes in degrade or on the item definition
    if (durability > 100) then
        local degrade = tonumber(metadata.degrade)

        if (not degrade and item.name) then
            local _, itemName = Functions.getItem(item.name)

            degrade = itemName and tonumber(Items[itemName]?.degrade)
        end

        if (degrade and degrade > 0) then
            local now = IsDuplicityVersion() and os.time() or GetCloudTimeAsInt()

            durability = (durability - now) / (60 * degrade) * 100
        end
    end

    return math.max(0, math.min(100, durability))
end

return Functions.getItemDurability