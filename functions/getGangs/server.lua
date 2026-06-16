-- Returns a raw table of the gangs

---@return table @Raw table of gangs
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGangs()
    if (GangSystem == "pug") then return {} end
    if (Framework == "QB") then return QB.Shared.Gangs or {} end

    return {}
end

return Functions.getGangs