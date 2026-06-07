---@param job string | string[]
---@param requirement integer
---@param onDuty boolean? @Only count players whose job duty state matches this value
---@return boolean
function Functions.enoughWorkers(job, requirement, onDuty)
    local onJob = Functions.getPlayersOnJob(job, nil, onDuty)

    return #onJob >= requirement
end

return Functions.enoughWorkers