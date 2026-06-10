---@class GangGrade
---@field name string
---@field label string
---@field boss boolean

---@class Gang
---@field name string
---@field label string
---@field grades GangGrade[]
---@field bossRanks table<string, boolean>

---@param rawGang table
---@return Gang | nil
function Formatting.formatGang(rawGang)
    if (Framework == "QB") then
        ---@type GangGrade[]
        local grades = {}

        ---@type table<string, boolean>
        local bossRanks = {}

        for key, value in pairs(rawGang.grades) do
            if (value.isboss) then
                bossRanks[value.name] = true
            end

            grades[tonumber(key) + 1] = {
                name = value.name,
                label = value.name, -- No label, just set the name
                boss = value.isboss
            }
        end

        ---@type Gang
        return {
            name = rawGang.name,
            label = rawGang.label,
            grades = grades,
            bossRanks = bossRanks
        }
    end

    return nil
end

return Formatting.formatGang