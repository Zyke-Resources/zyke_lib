-- The inventory owns the condition of an item it decays itself, so a resource keeps its own decay off that item
---@param item string
---@return boolean hasDecay
function Functions.hasInventoryDecay(item)
    local _, itemName = Functions.getItem(item)
    itemName = itemName or item

    local definition = Items[itemName]
    if (not definition) then return false end

    if (Inventory == "OX") then return (tonumber(definition.degrade) or 0) > 0 end
    if (Inventory == "QS") then return (tonumber(definition.decay) or 0) > 0 end
    if (Inventory == "TGIANN") then return (tonumber(exports["tgiann-inventory"]:GetItemDecayTime(itemName)) or 0) > 0 end

    return false
end

return Functions.hasInventoryDecay