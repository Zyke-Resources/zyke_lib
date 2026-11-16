-- The mission tracker, drawn by zyke_lib's NUI so the missions of every resource stack in one column instead of
-- overlapping. The column's corner is zyke_lib's missionTracker setting, and a stopped resource's missions are removed

Functions.missionTracker = {}

---@alias MissionStepState "done" | "current" | "pending" | "failed"

---@class MissionStep
---@field label string
---@field detail? string @ A line under the label, shown while the step is not done
---@field state MissionStepState

---@class MissionCountdown
---@field endsAt integer @ GetGameTimer() when it reaches zero
---@field duration? integer @ Milliseconds it runs in all, it turns orange in its last fifth; it always turns red in the last minute

---@class MissionData
---@field title string
---@field steps MissionStep[]
---@field countdown? MissionCountdown
---@field exitable? boolean @ Shows the exit command under the mission, the resource takes it away in its onExit handler

-- Shows a mission, or replaces what a shown one holds while it keeps its place in the column
---@param id string | integer @ Picked by this resource, unique among its own missions
---@param mission MissionData
---@return boolean shown
function Functions.missionTracker.show(id, mission)
    return exports[LibName]:setMission(id, mission)
end

-- Replaces some fields of a shown mission, such as its steps
---@param id string | integer
---@param changes table @ Fields of MissionData
---@return boolean updated @ False when no mission of this resource has this id
function Functions.missionTracker.update(id, changes)
    return exports[LibName]:updateMission(id, changes)
end

---@param id string | integer
---@return boolean removed
function Functions.missionTracker.hide(id)
    return exports[LibName]:removeMission(id)
end

-- Removes every mission of this resource
---@return boolean removed
function Functions.missionTracker.hideAll()
    return exports[LibName]:removeMissions()
end

-- Runs when the player leaves one of this resource's exitable missions with the exit command. The mission stays until
-- the handler hides it
---@param handler fun(id: string)
function Functions.missionTracker.onExit(handler)
    ---@param resource string
    ---@param id string
    AddEventHandler("zyke_lib:missionExit", function(resource, id)
        if (resource ~= ResName) then return end

        handler(id)
    end)
end

return Functions.missionTracker