-- Might have to add CreateThread because of delay in searching for framework?

---@param plyId PlayerId
---@param item string
---@param itemData? table
---@return Item | nil
local function resolveItemData(plyId, item, itemData)
    if (itemData) then return Formatting.formatItem(itemData) end

    -- Bandaid for inventories that call usable item handlers without the used item's data, so the handler does not
    -- error. The first matching item in the inventory stands in, which may not be the exact stack that was used
    return Functions.getPlayerItems(plyId, item, {firstOnly = true})
end

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

            func(plyId, resolveItemData(plyId, item, itemData))
        end)
    elseif (Framework == "QB") then
        ---@param plyId PlayerId
        ---@param itemData? table
        QB.Functions.CreateUseableItem(item, function(plyId, itemData)
            func(plyId, resolveItemData(plyId, item, itemData))
        end)
    end
end

return Functions.registerUsableItem