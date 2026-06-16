---@return PlayerGang | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGang()
    if (GangSystem == "pug") then
        return Functions.callback.request(ResName .. ":GetPugPlayerGang", nil)
    end

    local player = Functions.getPlayerData()
    if (not player or not player.gang) then return nil end

    if (Framework == "QB") then return Formatting.formatPlayerGang(player.gang) end

    return nil
end

return Functions.getGang