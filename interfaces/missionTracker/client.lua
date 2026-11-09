-- Draws the missions of every resource from Z.missionTracker, one card each, in one column in the order they were
-- first shown, so they stack instead of overlapping. The corner is zyke_lib's own setting, so the column can never
-- split. The pause menu covers the game, so the missions go with it

local settings = LibConfig.missionTracker or {}
local position = settings.position or "top-left"
local offset = settings.offset or {x = 2.5, y = 2.5}

---@type {resource: string, id: string, mission: MissionData}[]
local missions = {}
local hidden = false
local watching = false
local pauseCheckMs = 100

---@param mission MissionData
---@param now integer
---@return {expiresIn: integer, totalMs?: integer}? countdown
local function getCountdown(mission, now)
    local countdown = mission.countdown
    if (type(countdown) ~= "table" or type(countdown.endsAt) ~= "number") then return end

    return {expiresIn = math.max(0, countdown.endsAt - now), totalMs = countdown.duration}
end

local function sync()
    local list = {}

    if (not hidden) then
        local now = GetGameTimer()

        for i = 1, #missions do
            local entry = missions[i]
            local mission = entry.mission

            list[i] = {
                key = ("%s:%s"):format(entry.resource, entry.id),
                resource = entry.resource,
                title = mission.title,
                steps = mission.steps,
                countdown = getCountdown(mission, now),
            }
        end
    end

    SendNUIMessage({event = "SetMissionTracker", data = {missions = list, position = position, offset = offset}})
end

local function watchPauseMenu()
    if (watching) then return end

    watching = true

    CreateThread(function()
        while (#missions > 0) do
            local paused = IsPauseMenuActive()

            if (paused ~= hidden) then
                hidden = paused

                sync()
            end

            Wait(pauseCheckMs)
        end

        watching = false
        hidden = false
    end)
end

---@param resource string
---@param id string
---@return integer? index
local function getIndex(resource, id)
    for i = 1, #missions do
        if (missions[i].resource == resource and missions[i].id == id) then return i end
    end
end

---@param mission any
---@return boolean isValid
local function isValidMission(mission)
    if (type(mission) ~= "table") then return false end
    if (type(mission.title) ~= "string") then return false end
    if (type(mission.steps) ~= "table") then return false end

    return true
end

---@return string resource
local function getResource()
    return GetInvokingResource() or ResName
end

---@param id string | integer @ Picked by the calling resource, unique among its own missions
---@param mission MissionData
---@return boolean shown
exports("setMission", function(id, mission)
    if (not isValidMission(mission)) then return false end

    local resource = getResource()
    local index = getIndex(resource, tostring(id))

    if (index) then
        missions[index].mission = mission
    else
        missions[#missions + 1] = {resource = resource, id = tostring(id), mission = mission}
    end

    sync()
    watchPauseMenu()

    return true
end)

---@param id string | integer
---@param changes table @ Fields of MissionData to replace
---@return boolean updated
exports("updateMission", function(id, changes)
    if (type(changes) ~= "table") then return false end

    local index = getIndex(getResource(), tostring(id))
    if (not index) then return false end

    local mission = {}

    for key, value in pairs(missions[index].mission) do
        mission[key] = value
    end

    for key, value in pairs(changes) do
        mission[key] = value
    end

    if (not isValidMission(mission)) then return false end

    missions[index].mission = mission

    sync()

    return true
end)

---@param id string | integer
---@return boolean removed
exports("removeMission", function(id)
    local index = getIndex(getResource(), tostring(id))
    if (not index) then return false end

    table.remove(missions, index)

    sync()

    return true
end)

---@param resource string
---@return boolean removed
local function removeResourceMissions(resource)
    local removed = false

    for i = #missions, 1, -1 do
        if (missions[i].resource == resource) then
            table.remove(missions, i)

            removed = true
        end
    end

    if (removed) then sync() end

    return removed
end

---@return boolean removed
exports("removeMissions", function()
    return removeResourceMissions(getResource())
end)

-- The page asks once it has loaded, so missions shown before then are sent again
---@param _ table
---@param cb function
RegisterNUICallback("Eventhandler:MissionTracker", function(_, cb)
    cb("ok")

    sync()
end)

---@param resourceName string
AddEventHandler("onClientResourceStop", function(resourceName)
    removeResourceMissions(resourceName)
end)