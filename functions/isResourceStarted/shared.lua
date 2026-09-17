local resourceStates = {}

---@param resourceName string
---@return boolean started
function Functions.isResourceStarted(resourceName)
    local started = resourceStates[resourceName]
    if (started ~= nil) then return started end

    started = GetResourceState(resourceName) == "started"
    resourceStates[resourceName] = started

    return started
end

---@param resourceName string
local function markResourceStarted(resourceName)
    if (resourceStates[resourceName] ~= nil) then resourceStates[resourceName] = true end
end

---@param resourceName string
local function markResourceStopped(resourceName)
    if (resourceStates[resourceName] ~= nil) then resourceStates[resourceName] = false end
end

if (IsDuplicityVersion()) then
    AddEventHandler("onResourceStart", markResourceStarted)
    AddEventHandler("onResourceStop", markResourceStopped)
else
    AddEventHandler("onClientResourceStart", markResourceStarted)
    AddEventHandler("onClientResourceStop", markResourceStopped)
end

return Functions.isResourceStarted