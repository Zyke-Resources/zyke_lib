---@param gangName string
---@return Gang | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGangData(gangName)
    local gang
    if (GangSystem == "pug") then
        local status, gangData = Functions.callback.request(ResName .. ":GetGangData", {
            timeout = 2000,
            retry = 2,
            status = true
        }, gangName)
        if (status.ok ~= true) then return nil end

        return gangData
    elseif (Framework == "QB") then
        gang = QB.Shared.Gangs[gangName]
    end

    if (not gang) then return nil end

    return Formatting.formatGang(gang)
end

return Functions.getGangData