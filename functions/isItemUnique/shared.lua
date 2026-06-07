---@param item string
---@return boolean
function Functions.isItemUnique(item)
    local _, itemName = Functions.getItem(item)
    item = itemName or item

    return Items[item] and (Items[item].unique == true or Items[item].stack == false) or false
end

return Functions.isItemUnique