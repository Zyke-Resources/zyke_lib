---@param gangName string
---@return Gang | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGangData(gangName)
    local gang
    if (GangSystem == "pug") then
        local gangId = tonumber(gangName)
        if (not gangId) then return nil end

        local rawGang = exports["pug-gangs"]:GetGangById(gangId)
        if (not rawGang) then return nil end

        return {
            name = tostring(rawGang.id),
            label = rawGang.name or tostring(rawGang.id),
            grades = {},
            bossRanks = {},
        }
    elseif (Framework == "QB") then
        gang = QB.Shared.Gangs[gangName]
    end

    if (not gang) then return nil end

    return Formatting.formatGang(gang)
end

---@param playerId PlayerId @ Player server ID
---@param gangName string @ Gang name
---@return Gang | nil gang
Functions.callback.register(ResName .. ":GetGangData", function(playerId, gangName)
    return Functions.getGangData(gangName)
end)

return Functions.getGangData