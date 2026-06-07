---@param job string | string[]
---@param getRanks boolean? @Get the rank name for each index in a ranks array
---@param onDuty boolean? @Only return players whose job duty state matches this value
---@return PlayerId[], string[]
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getPlayersOnJob(job, getRanks, onDuty)
    if (onDuty ~= nil and getRanks == nil) then getRanks = false end

    return Functions.callback.await(ResName .. ":GetPlayersOnJob", job, getRanks, onDuty)
end

return Functions.getPlayersOnJob