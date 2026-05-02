---@param item Item | table | nil
---@return number
function Functions.getItemDurability(item)
    local metadata = item and (item.metadata or item.info)
    if (not metadata) then return 100 end

    local durability = metadata.durability
    if (durability == nil) then durability = metadata.quality end

    durability = tonumber(durability) or 100

    return math.max(0, math.min(100, durability))
end

return Functions.getItemDurability