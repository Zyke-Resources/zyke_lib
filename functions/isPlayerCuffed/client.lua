---@return boolean cuffed
function Functions.isPlayerCuffed()
    if (IsPedCuffed(PlayerPedId())) then return true end
    if (Framework ~= "QB") then return false end

    -- qb-policejob keeps the cuffs in metadata.ishandcuffed. Only read on QB, as the player data is a copy of the whole table
    local player = Functions.getPlayerData()
    local metadata = player and player.metadata

    return type(metadata) == "table" and metadata.ishandcuffed == true
end

return Functions.isPlayerCuffed