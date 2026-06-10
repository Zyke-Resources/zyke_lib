---@return PlayerGang | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGang()
    local player = Functions.getPlayerData()
    if (not player or not player.gang) then return nil end

    if (Framework == "QB") then return Formatting.formatPlayerGang(player.gang) end

    return nil
end

return Functions.getGang