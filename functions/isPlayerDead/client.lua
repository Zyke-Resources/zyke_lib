---@return boolean
function Functions.isPlayerDead()
    if (DeathSystem == "wasabi_ambulance") then
        return exports["wasabi_ambulance"]:isPlayerDead()
    end

    if (DeathSystem == "wasabi_ambulance_v2") then
        return exports["wasabi_ambulance_v2"]:isPlayerDead()
    end

    if (Framework == "ESX") then return IsEntityDead(PlayerPedId()) end
    if (Framework == "QB") then
        local player = Functions.getPlayerData()
        if (not player) then return false end

        return player.metadata.isdead or player.metadata.inlaststand
    end

    return false
end

return Functions.isPlayerDead