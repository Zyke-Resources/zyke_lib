-- The time of day from the time sync system (systems/time.lua). Without one the server has no game clock, so nil is
-- returned and the caller decides, such as from a client's clock

---@return integer? hour @ 0-23, nil when no time sync system runs
---@return integer? minute @ 0-59
function Functions.getGameTime()
    if (TimeSystem == "cd_easytime") then
        local data = exports["cd_easytime"]:GetAllData()
        if (data and data.hours) then return math.floor(data.hours) % 24, math.floor(data.mins or 0) % 60 end
    elseif (TimeSystem == "qb-weathersync") then
        local hour, minute = exports["qb-weathersync"]:getTime()
        if (hour) then return hour, minute or 0 end
    end

    return nil, nil
end

return Functions.getGameTime