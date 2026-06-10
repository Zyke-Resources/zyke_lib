---@param player CharacterIdentifier | PlayerId
---@return PlayerGang | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGang(player)
    local player = Functions.getPlayerData(player)
    if (not player) then return nil end

    if (Framework == "QB") then return Formatting.formatPlayerGang(player.PlayerData.gang) end

    return nil
end

return Functions.getGang