-- TGIANN keeps the 0-100 durability in durabilityPercent and sets durability itself, as the decay timestamp
---@param metadata? table<string, any>
---@return table<string, any>? info
local function getTgiannInfo(metadata)
    if (not metadata or metadata.durability == nil) then return metadata end

    local info = {}
    for k, v in pairs(metadata) do
        info[k] = v
    end

    info.durabilityPercent = metadata.durability
    info.durability = nil

    return info
end

---@param player Character | CharacterIdentifier | PlayerId
---@param item string | table @ An item name, or a list of items as formatItemInput takes them
---@param amount integer
---@param metadata table<string, any> | nil
---@return boolean? success
function Functions.addItem(player, item, amount, metadata)
    local player = Functions.getPlayerData(player)
    if (not player) then return end

    local items = Formatting.formatItemInput(item, amount, metadata)

    for i = 1, #items do
        if (Inventory == "TGIANN") then items[i].metadata = getTgiannInfo(items[i].metadata) end

        if (Inventory == "CODEM") then
            exports["codem-inventory"]:AddItem(Functions.getPlayerId(player), items[i].name, items[i].amount, nil, items[i].metadata)
        elseif (Inventory == "ONE") then
            local success = exports["one_inventory"]:AddItem(Functions.getPlayerId(player), items[i].name, items[i].amount, items[i].metadata)
            if (not success) then return false end
        elseif (Inventory == "QS") then
            exports['qs-inventory']:AddItem(Functions.getPlayerId(player), items[i].name, items[i].amount, nil, items[i].metadata)
        elseif (Framework == "ESX") then
            player.addInventoryItem(items[i].name, items[i].amount, items[i].metadata)
        elseif (Framework == "QB") then
            -- False when the inventory refuses it, such as when it is full
            if (not player.Functions.AddItem(items[i].name, items[i].amount, nil, items[i].metadata)) then return false end
        end
    end

    return true
end

return Functions.addItem