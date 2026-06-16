---@param player CharacterIdentifier | PlayerId
---@return PlayerGang | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGang(player)
    local playerData = Functions.getPlayerData(player)
    if (not playerData) then return nil end

    if (GangSystem == "pug") then
        local playerRef = Functions.getPlayerId(playerData) or (playerData.PlayerData and playerData.PlayerData.citizenid)
        if (not playerRef) then return nil end

        local gang, additionalData = exports["pug-gangs"]:GetPlayerGang(playerRef)

        return Formatting.formatPlayerGang(gang, additionalData)
    end

    if (Framework == "QB") then return Formatting.formatPlayerGang(playerData.PlayerData.gang) end

    return nil
end

---@param playerId PlayerId @ Player server ID
Functions.callback.register(ResName .. ":GetPugPlayerGang", function(playerId)
    return Functions.getGang(playerId)
end)

return Functions.getGang