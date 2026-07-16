---@class HasItemFetch
---@field name string? @Depending on input
---@field item string? @Dependning on input
---@field amount string

---@param player Character | CharacterIdentifier | PlayerId
---@param item HasItemFetch[] | HasItemFetch | {name: string, amount: integer} | string
---@param amount integer
---@diagnostic disable-next-line: duplicate-set-field
function Functions.hasItem(player, item, amount)
    local items, included = Formatting.formatItemInput(item, amount)

    if (Inventory == "TGIANN") then
        local plyId = Functions.getPlayerId(player)
        local requiredItems = {}

        for i = 1, #items do
            local itemData = items[i]
            requiredItems[itemData.name] = (requiredItems[itemData.name] or 0) + itemData.amount
        end

        return exports["tgiann-inventory"]:HasItem(plyId, requiredItems)
    end

    local playerItems = Functions.getPlayerItems(player, included)

    -- Iterate our items we are checking for
    -- Remove the amount as they are found in our inventory
    -- If the items end up empty, return true
    for i = #items, 1, -1 do
        for _, plyItem in pairs(playerItems) do
            if (items[i].name == plyItem.name) then
                items[i].amount -= plyItem.amount

                if (items[i].amount <= 0) then
                    table.remove(items, i)
                    break
                end
            end
        end
    end

    return #items == 0
end

return Functions.hasItem