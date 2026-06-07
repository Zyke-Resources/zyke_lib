---@param plyId PlayerId
---@param item string
---@param amount integer
---@param slot integer
function Functions.removeFromSlot(plyId, item, amount, slot)
    local _, itemName = Functions.getItem(item)
    item = itemName or item

    if (Inventory == "OX") then
        exports["ox_inventory"]:RemoveItem(plyId, item, amount, nil, slot)
        return
    elseif (Inventory == "TGIANN") then
        exports["tgiann-inventory"]:RemoveItem(plyId, item, amount, slot)
        return
    elseif (Inventory == "QS") then
        exports["qs-inventory"]:RemoveItem(plyId, item, amount, slot)
        return
    elseif (Inventory == "C8RE") then
        local itemId = exports["core_inventory"]:getItemBySlot(plyId, slot).id

        exports["core_inventory"]:removeItemExact("content-" .. Z.getIdentifier(plyId), itemId, amount)
        return
    elseif (Inventory == "CODEM") then
        return exports["codem-inventory"]:RemoveItem(plyId, item, amount, slot)
    end

    local player = Functions.getPlayerData(plyId)
    if (not player) then return false, Functions.debug.internal("Player not found (CRITICAL!)") end

    if (Framework == "QB") then
        local inv = player.PlayerData.items

        for i, itemData in pairs(inv) do
            if (itemData.slot == slot) then
                itemData.amount = itemData.amount - amount

                if (itemData.amount <= 0) then
                    inv[i] = nil
                end

                break
            end
        end

        player.Functions.SetPlayerData("items", inv)

        return
    end

    error("Your inventory does not support this function.")
end

return Functions.removeFromSlot