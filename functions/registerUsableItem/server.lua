-- Might have to add CreateThread because of delay in searching for framework?

---@param item string
---@param func function
function Functions.registerUsableItem(item, func)
    local _, itemName = Functions.getItem(item)
    item = itemName or item

    if (Framework == "ESX") then
        ---@param plyId PlayerId
        ---@param usedItem string | table
        ---@param itemData? table
        ESX.RegisterUsableItem(item, function(plyId, usedItem, itemData)
            if (Inventory == "QS" or Inventory == "TGIANN") then itemData = usedItem end

            func(plyId, itemData and Formatting.formatItem(itemData))
        end)
    elseif (Framework == "QB") then
        ---@param plyId PlayerId
        ---@param itemData? table
        QB.Functions.CreateUseableItem(item, function(plyId, itemData)
            func(plyId, itemData and Formatting.formatItem(itemData))
        end)
    end
end

return Functions.registerUsableItem