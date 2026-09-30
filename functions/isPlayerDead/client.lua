---@return boolean
function Functions.isPlayerDead()
    if (DeathSystem == "sky_ambulancejob") then
        return exports["sky_ambulancejob"]:isDead()
    end

    if (DeathSystem == "wasabi_ambulance") then
        return exports["wasabi_ambulance"]:isPlayerDead()
    end

    if (DeathSystem == "wasabi_ambulance_v2") then
        return exports["wasabi_ambulance_v2"]:isPlayerDead()
    end

    if (DeathSystem == "osp_ambulance") then
        local bodyDamage = LocalPlayer.state.BodyDamage or {}

        return bodyDamage.isDead == true or bodyDamage.inLastStand == true
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