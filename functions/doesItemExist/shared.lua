---@param itemName string
---@return boolean
function Functions.doesItemExist(itemName)
    local _, normalizedName = Functions.getItem(itemName)

    return normalizedName ~= nil
end

return Functions.doesItemExist