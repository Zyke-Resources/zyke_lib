---@param plyId PlayerId
---@return boolean dead
---@diagnostic disable-next-line: duplicate-set-field
function Functions.isPlayerDead(plyId)
    -- esx_ambulancejob and qbx_medical set isDead true, wasabi_ambulance_v2 isDead above 0, wasabi_ambulance dead to
    -- "dead" or "laststand", osp_ambulance BodyDamage. sky_ambulancejob and p_ambulancejob have no verified server read
    local state = Player(plyId).state
    local isDead = state.isDead
    if (isDead == true or (type(isDead) == "number" and isDead > 0)) then return true end
    if (state.dead) then return true end

    local body = state.BodyDamage
    if (type(body) == "table" and (body.isDead == true or body.inLastStand == true)) then return true end

    if (Framework == "QB") then
        local player = Functions.getPlayerData(plyId)
        local metadata = player and player.PlayerData.metadata

        if (metadata and (metadata.isdead or metadata.inlaststand)) then return true end
    end

    local ped = GetPlayerPed(plyId)

    return ped ~= 0 and GetEntityHealth(ped) <= 0
end

return Functions.isPlayerDead