---@param player Character | CharacterIdentifier | PlayerId
---@param item string
---@param amount integer
---@param metadata table | nil @Unused?
---@return boolean
function Functions.removeItem(player, item, amount, metadata)
    local player = Functions.getPlayerData(player)
    if (not player) then return false end

    local toRemove = Formatting.formatItemInput(item, amount)

    if (Framework == "ESX") then
        for i = 1, #toRemove do
            player.removeInventoryItem(toRemove[i].name, toRemove[i].amount, metadata)
        end

        return true
    elseif (Framework == "QB") then
        -- If you are using QB, the default inventory doesn't handle multi-removal of unique items properly
        -- This may be fixed in later versions, but is a risk for older ones
        -- Check if the item is unique, and remove one at a time
        -- If it's not unique, just remove them normally

        for i = 1, #toRemove do
            local success = true
            local isUnique = Functions.isItemUnique(toRemove[i].name)

            if (isUnique) then
                for _ = 1, toRemove[i].amount do
                    local _success = player.Functions.RemoveItem(toRemove[i].name, 1)
                    if (not _success) then success = false end
                end
            else
                local _success = player.Functions.RemoveItem(toRemove[i].name, toRemove[i].amount)
                if (not _success) then success = false end
            end

            if (not success) then
                local identifier = Functions.getIdentifier(player)
                error(("CRITICAL ERROR! Attempting to remove %s from %s failed!"):format(toRemove[i], identifier))
            end
        end

        return true
    end

    return true
end

return Functions.removeItem