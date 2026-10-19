Functions.doorlock = {}

---@class DoorlockDoor
---@field model string | integer
---@field coords vector3
---@field heading number

---@class DoorlockEntry
---@field name string @ Unique name the door is found by, renaming it adds the door again
---@field doors DoorlockDoor[] @ One door, or both halves of a double door
---@field label? string @ Name door locks show for it, the name when left out
---@field group? string @ Building the door belongs to in door locks that group doors, such as rcore_doorlock
---@field jobs? string | string[] | SpecificJob | SpecificJob[]
---@field locked? boolean @ State a new door starts in, true when left out
---@field distance? number @ Metres from the door a player can use it
---@field pin? string @ Code for door locks that can't take a job from another resource, such as rcore_doorlock

-- Add providers by checking DoorlockSystem inside each method and calling their API directly

-- Seconds a door lock that is still starting is waited for
local startTimeout = 10
-- Metres between a door and one the door lock already has for them to count as the same door
local sameDoorDistance = 0.1

---@param model string | integer
---@return integer modelHash
local function getModelHash(model)
    return type(model) == "string" and joaat(model) or model
end

---@param jobs string | string[] | SpecificJob | SpecificJob[]
---@return table<string, integer> groups @ Job name to lowest grade
local function getJobGrades(jobs)
    if (type(jobs) == "string") then jobs = {jobs} end
    if (jobs.name) then jobs = {jobs} end

    local groups = {}
    for i = 1, #jobs do
        local job = jobs[i]

        if (type(job) == "string") then
            groups[job] = 0
        else
            groups[job.name] = job.minGrade or 0
        end
    end

    return groups
end

-- Door locks are detected while the calling resource's scripts load, so a door added at its start waits for that
---@return boolean started
local function awaitProvider()
    while (not HasLoaderFinished) do Wait(10) end

    if (not DoorlockSystem) then return false end

    local timeoutAt = GetGameTimer() + startTimeout * 1000
    while (GetResourceState(DoorlockSystem) == "starting" and GetGameTimer() < timeoutAt) do
        Wait(100)
    end

    return GetResourceState(DoorlockSystem) == "started"
end

-- ox_doorlock fills its door list after its own start, so its table is read directly to not add a door twice
---@param entry DoorlockEntry
---@return boolean ensured
---@return string? reason
local function ensureOxDoor(entry)
    if (not MySQL) then return false, "databaseUnavailable" end

    local exists = MySQL.scalar.await("SELECT 1 FROM ox_doorlock WHERE name = ? LIMIT 1", {entry.name})
    if (exists) then return true end

    local door = {
        name = entry.name,
        groups = entry.jobs and getJobGrades(entry.jobs) or nil,
        state = entry.locked == false and 0 or 1,
        maxDistance = entry.distance or 2.0,
    }

    local doors = {}
    for i = 1, #entry.doors do
        local half = entry.doors[i]
        doors[i] = {
            model = getModelHash(half.model),
            coords = half.coords,
            heading = math.floor(half.heading + 0.5),
        }
    end

    if (#doors == 1) then
        door.model = doors[1].model
        door.coords = doors[1].coords
        door.heading = doors[1].heading
    else
        door.doors = doors
    end

    local doorId = exports["ox_doorlock"]:createDoor(door)
    if (not doorId) then return false, "doorNotAdded" end

    return true
end

-- rcore_doorlock takes one door at a time and has no documented way to give a door a job from another resource,
-- so each half is added on its own and opens with the entry's pin until the server owner sets access in its menu
---@param entry DoorlockEntry
---@return boolean ensured
---@return string? reason
local function ensureRcoreDoor(entry)
    local existing = exports["rcore_doorlock"]:getSqlDoors()

    for i = 1, #entry.doors do
        local half = entry.doors[i]
        local isAdded = false

        for _, door in pairs(existing) do
            local coords = door.coords
            if (coords and #(vec3(coords.x, coords.y, coords.z) - half.coords) < sameDoorDistance) then
                isAdded = true

                break
            end
        end

        if (not isAdded) then
            local added = exports["rcore_doorlock"]:addDoor({
                label = entry.label or entry.name,
                group = entry.group or entry.label or entry.name,
                model = half.model,
                coords = vec4(half.coords.x, half.coords.y, half.coords.z, half.heading),
                distance = entry.distance or 2.0,
                defaultState = entry.locked == false and 0 or 1,
                soundFiles = {lock = "rcore_basic_lock", unlock = "rcore_basic_unlock"},
                access = entry.pin and {pin = {enabled = true, type = "pin", name = entry.pin}} or {},
                createdBy = "admin",
            })
            if (not added) then return false, "doorNotAdded" end
        end
    end

    return true
end

---@return string? providerName
function Functions.doorlock.getProvider()
    return DoorlockSystem
end

---@return boolean available
function Functions.doorlock.isAvailable()
    return DoorlockSystem ~= nil and GetResourceState(DoorlockSystem) == "started"
end

-- Adds the door to the door lock unless it already has it, so a door the server owner changed keeps their changes
-- qb-doorlock reads its doors from its own config files, the resource ships those instead
---@param entry DoorlockEntry
---@return boolean ensured @ The door lock has the door, added now or before
---@return string? reason @ doorlockUnavailable, doorlockConfigOnly, invalidDoor, databaseUnavailable or doorNotAdded
function Functions.doorlock.ensure(entry)
    if (not awaitProvider()) then return false, "doorlockUnavailable" end
    if (DoorlockSystem == "qb-doorlock") then return false, "doorlockConfigOnly" end
    if (type(entry) ~= "table" or type(entry.name) ~= "string" or type(entry.doors) ~= "table") then return false, "invalidDoor" end
    if (#entry.doors < 1 or #entry.doors > 2) then return false, "invalidDoor" end

    if (DoorlockSystem == "ox_doorlock") then return ensureOxDoor(entry) end
    if (DoorlockSystem == "rcore_doorlock") then return ensureRcoreDoor(entry) end

    return false, "doorlockUnavailable"
end

return Functions.doorlock