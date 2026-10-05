---@param player Character
---@param item string
---@param amount integer
---@param metadata table<string, any> | nil
function Functions.addItem(player, item, amount, metadata)
    local player = Functions.getPlayerData(player)
    if (not player) then return end

    local items = Formatting.formatItemInput(item, amount, metadata)

    for i = 1, #items do
        if (Inventory == "CODEM") then
            exports["codem-inventory"]:AddItem(Functions.getPlayerId(player), items[i].name, items[i].amount, nil, items[i].metadata)
        elseif (Inventory == "ONE") then
            exports["one_inventory"]:AddItem(Functions.getPlayerId(player), items[i].name, items[i].amount, items[i].metadata)
        elseif (Inventory == "QS") then
            exports['qs-inventory']:AddItem(Functions.getPlayerId(player), items[i].name, items[i].amount, nil, items[i].metadata)
        elseif (Framework == "ESX") then
            player.addInventoryItem(items[i].name, items[i].amount, items[i].metadata)
        elseif (Framework == "QB") then
            player.Functions.AddItem(items[i].name, items[i].amount, nil, items[i].metadata)
        end
    end

    return true
end

return Functions.addItem