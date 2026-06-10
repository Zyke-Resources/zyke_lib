---@param gangName string
---@return Gang | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGangData(gangName)
    local gang
    if (Framework == "QB") then
        gang = QB.Shared.Gangs[gangName]
    end

    if (not gang) then return nil end

    return Formatting.formatGang(gang)
end

---@param gangName string @ Gang name
---@return Gang | nil gang
Functions.callback.register(ResName .. ":GetGangData", function(_, gangName)
    return Functions.getGangData(gangName)
end)

return Functions.getGangData