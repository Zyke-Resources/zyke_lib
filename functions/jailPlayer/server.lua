-- Jails an online player through the detected jail script
---@param plyId PlayerId
---@param minutes integer
---@param reason string
---@return boolean jailed
function Functions.jailPlayer(plyId, minutes, reason)
    if (JailSystem == "qb-prison") then
        local player = Functions.getPlayerData(plyId)
        if (not player) then return false end

        -- qb-prison counts minutes and only lets qb-policejob's client event send a player in
        player.Functions.SetMetaData("injail", minutes)
        TriggerClientEvent("police:client:SendToJail", plyId, minutes)

        return true
    end

    if (JailSystem == "rcore_prison") then
        exports["rcore_prison"]:Jail(plyId, minutes, reason)

        return true
    end

    if (JailSystem == "esx_jail") then
        if (not Functions.getPlayerData(plyId)) then return false end

        -- esx_jail counts seconds
        TriggerEvent("esx_jail:sendToJail", plyId, minutes * 60)

        return true
    end

    return false
end

return Functions.jailPlayer