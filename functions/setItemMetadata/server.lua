---@param plyId PlayerId
---@param slot integer
---@param metadata table<string, any>
function Functions.setItemMetadata(plyId, slot, metadata)
    if (Inventory == "OX") then
        return exports["ox_inventory"]:SetMetadata(plyId, slot, metadata)
    elseif (Inventory == "ONE") then
        return exports["one_inventory"]:SetItemMetadata(plyId, slot, metadata)
    elseif (Inventory == "QS") then
        return exports["qs-inventory"]:SetItemMetadata(plyId, slot, metadata)
    elseif (Inventory == "TGIANN") then
        local item = Functions.getInventorySlot(plyId, slot)
        if (not item) then return false end

        return exports["tgiann-inventory"]:SetItemData(plyId, item.name, slot, metadata)
    elseif (Inventory == "CODEM") then
        return exports["codem-inventory"]:SetItemMetadata(plyId, slot, metadata)
    elseif (Inventory == "C8RE") then
        return exports["core_inventory"]:setMetadata(plyId, slot, metadata)
    end

    -- If we are not using ox_inventory, we will have to fetch the inventory, make the modifications ourselves and set the inventory
    if (Framework == "QB") then
        -- We'll have to grab the raw QBCore inventoy and modify it, to make sure all the data is correct
        local player = Functions.getPlayerData(plyId)
        if (not player) then error("Player not found (CRITICAL!)") return false end

        local inv = player.PlayerData.items

        for i, itemData in pairs(inv) do
            if (itemData.slot == slot) then
                itemData.info = metadata

                break
            end
        end

        player.Functions.SetPlayerData("items", inv)

        return
    elseif (Framework == "ESX") then
        -- Note that ESX does not offer such a feature by default
        -- If you are using ESX and any other inventory than ox_inventory, you will have to edit this yourself
        error("ESX does not support setting item metadata, please use ox_inventory or implement your own inventory system")
    end

    error("Your inventory does not support this function.")
end

return Functions.setItemMetadata