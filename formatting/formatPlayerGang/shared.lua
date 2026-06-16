---@class PlayerGangGrade
---@field level integer
---@field name string

---@class PlayerGang
---@field name string
---@field label string
---@field grade PlayerGangGrade

---@param rawGang table | nil @ Raw gang data
---@param additionalData? table @ Provider-specific additional gang data
---@return PlayerGang | nil playerGang
function Formatting.formatPlayerGang(rawGang, additionalData)
    if (GangSystem == "pug") then
        if (not rawGang or not rawGang.id) then return nil end

        additionalData = additionalData or {}

        return {
            name = tostring(rawGang.id),
            label = rawGang.name or rawGang.label or tostring(rawGang.id),
            grade = {
                level = tonumber(additionalData.rank_level or additionalData.rankLevel or additionalData.level) or 0,
                name = additionalData.rank_key or additionalData.rankKey or additionalData.rank or "member",
            }
        }
    elseif (Framework == "QB") then
        local formattedGang = {
            name = rawGang.name,
            label = rawGang.label,
            grade = {
                level = rawGang.grade.level,
                name = rawGang.grade.name,
            }
        }

        return formattedGang
    end

    return nil
end

return Formatting.formatPlayerGang