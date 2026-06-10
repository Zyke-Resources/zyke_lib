---@class PlayerGangGrade
---@field level integer
---@field name string

---@class PlayerGang
---@field name string
---@field label string
---@field grade PlayerGangGrade

---@param rawGang table
---@return PlayerGang | nil
function Formatting.formatPlayerGang(rawGang)
    if (Framework == "QB") then
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