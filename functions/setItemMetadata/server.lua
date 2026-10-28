-- Maps Formatting.formatItem's 0-100 durability back to durabilityPercent and keeps TGIANN's decay timestamp in durability
-- A changed image is written to imageurl, the only metadata key TGIANN reads an item image from
---@param item table @ Raw TGIANN slot item
---@param metadata table<string, any>
---@return table<string, any> info
local function getTgiannInfo(item, metadata)
    local current = item.info or {}
    local info = {}
    for k, v in pairs(metadata) do
        info[k] = v
    end

    -- Unchanged when the caller passed TGIANN's own info table back
    if (metadata.durability ~= current.durability) then
        if (metadata.durability ~= Formatting.formatItem(item).metadata.durability) then info.durabilityPercent = metadata.durability end

        info.durability = current.durability
    end

    if (type(metadata.image) == "string" and metadata.imageurl == current.imageurl) then
        info.imageurl = Functions.getInventoryImagePath(item.name, {image = metadata.image})
    end

    return info
end

---@param plyId PlayerId | string @ Player or container inventory identifier
---@param slot integer
---@param metadata table<string, any>
---@return boolean? success
function Functions.setItemMetadata(plyId, slot, metadata)
    if (Inventory == "OX") then
        return exports["ox_inventory"]:SetMetadata(plyId, slot, metadata)
    elseif (Inventory == "ONE") then
        return exports["one_inventory"]:SetItemMetadata(plyId, slot, metadata)
    elseif (Inventory == "QS") then
        return exports["qs-inventory"]:SetItemMetadata(plyId, slot, metadata)
    elseif (Inventory == "TGIANN") then
        local item = exports["tgiann-inventory"]:GetItemBySlot(plyId, slot, nil)
        if (not item or not item.name) then return false end

        return exports["tgiann-inventory"]:SetItemData(plyId, item.name, slot, getTgiannInfo(item, metadata))
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