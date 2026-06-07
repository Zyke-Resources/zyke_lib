---@class PlayerJobGrade
---@field level integer
---@field name string

---@class PlayerJob
---@field name string
---@field label string
---@field grade PlayerJobGrade
---@field onDuty boolean?

---@param rawJob table
---@return PlayerJob?
function Formatting.formatPlayerJob(rawJob)
    local onDuty = rawJob.onduty
    if (onDuty == nil) then onDuty = rawJob.onDuty end

    if (Framework == "ESX") then
        local formattedJob = {
            name = rawJob.name,
            label = rawJob.label,
            grade = {
                level = rawJob.grade,
                name = rawJob.grade_name
            },
            onDuty = onDuty
        }

        return formattedJob
    elseif (Framework == "QB") then
        local formattedJob = {
            name = rawJob.name,
            label = rawJob.label,
            grade = {
                level = rawJob.grade.level,
                name = rawJob.grade.name
            },
            onDuty = onDuty
        }

        return formattedJob
    end

    return error("Could not find framework.")
end

return Formatting.formatPlayerJob