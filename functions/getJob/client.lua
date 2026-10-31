-- Reading the framework's player data copies all of it, inventory included, so the job is kept here and replaced by
-- zyke_lib:OnJobUpdate, which the framework's job and duty changes trigger
---@type PlayerJob | nil
local cachedJob

-- A copy, so a caller changing it can't change the kept job
---@param job PlayerJob
---@return PlayerJob job
local function copyJob(job)
    local grade = type(job.grade) == "table" and {level = job.grade.level, name = job.grade.name} or job.grade

    return {name = job.name, label = job.label, grade = grade, onDuty = job.onDuty}
end

---@return PlayerJob | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getJob()
    if (cachedJob) then return copyJob(cachedJob) end

    local playerData = Functions.getPlayerData()
    if (not playerData or not playerData.job) then return nil end

    local job = Formatting.formatPlayerJob(playerData.job)
    if (not job) then return nil end

    cachedJob = job

    return copyJob(job)
end

---@param job? PlayerJob
RegisterNetEvent("zyke_lib:OnJobUpdate", function(job)
    cachedJob = type(job) == "table" and job or nil
end)

-- Another character's job is read again
AddEventHandler("zyke_lib:OnCharacterSelect", function()
    cachedJob = nil
end)

RegisterNetEvent("zyke_lib:OnCharacterLogout", function()
    cachedJob = nil
end)

return Functions.getJob