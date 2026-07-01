---@return PlayerGang | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGang()
    if (GangSystem == "pug") then
        local status, gang = Functions.callback.request(ResName .. ":GetPugPlayerGang", {
            timeout = 2000,
            retry = 2,
            status = true
        })
        if (status.ok ~= true) then return nil end

        return gang
    end

    local player = Functions.getPlayerData()
    if (not player or not player.gang) then return nil end

    if (Framework == "QB") then return Formatting.formatPlayerGang(player.gang) end

    return nil
end

return Functions.getGang