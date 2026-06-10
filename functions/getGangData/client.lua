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

return Functions.getGangData