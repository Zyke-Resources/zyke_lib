---@param jobName string | string[]
---@param getRanks boolean? @Get the rank name for each index in a ranks array
---@param onDuty boolean? @Only return players whose job duty state matches this value
---@return PlayerId[], string[]
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getPlayersOnJob(jobName, getRanks, onDuty)
    ---@type PlayerId[]
    local playersOnJob = {}

    ---@type string[]
    local ranks = {}

    ---@param name string
    local function insertRank(name)
        if (not getRanks) then return end

        ranks[#ranks+1] = name
    end

    local players = Functions.getPlayers()
    for i = 1, #players do
        local plyJob = Functions.getJob(players[i])
        if (not plyJob) then goto continue end
        if (onDuty ~= nil and plyJob.onDuty ~= onDuty) then goto continue end

        if (type(jobName) == "string") then
            if (plyJob.name == jobName) then
                playersOnJob[#playersOnJob+1] = players[i]
                insertRank(plyJob.grade.name)
            end
        elseif (type(jobName) == "table") then
            if (Functions.table.contains(jobName, plyJob.name)) then
                playersOnJob[#playersOnJob+1] = players[i]
                insertRank(plyJob.grade.name)
            end
        end

        ::continue::
    end

    return playersOnJob, ranks
end

Functions.callback.register(ResName .. ":GetPlayersOnJob", function(_, job, getRanks, onDuty)
    return Functions.getPlayersOnJob(job, getRanks, onDuty)
end)

return Functions.getPlayersOnJob