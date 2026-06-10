local openPrompts = {}

---@param resourceName string @ Owning resource name
---@param id string @ Prompt identifier from the owning resource
local function setPromptOpen(resourceName, id)
    local resourcePrompts = openPrompts[resourceName]
    if (not resourcePrompts) then
        resourcePrompts = {}
        openPrompts[resourceName] = resourcePrompts
    end

    resourcePrompts[id] = true
end

---@return string resourceName
local function getPromptResourceName()
    return GetInvokingResource() or ResName
end

-- Show a prompt / text ui on screen
-- Possibility to automatically resolve key label from command name to get the actual key bound to the action, without extra work
---@param id string @ Unique identifier (allows updates & removal)
---@param key string @ Key label to display in the kbd element (ex. "E", "U"), or a command name prefixed with "+" (ex. "+storeVehicle") to auto-resolve the key label
---@param label string @ Text label next to the key
Functions.showPrompt = function(id, key, label)
    local resourceName = getPromptResourceName()
    local resolvedKey = key

    if (#key > 1 and key:byte(1) == 43) then
        local keyData = Functions.keys.getKeyDataForCommand(key)
        resolvedKey = keyData and keyData.label or "?"
    end

    SendNUIMessage({
        event = "ShowPrompt",
        data = { id = id, resource = resourceName, key = resolvedKey, label = label }
    })

    setPromptOpen(resourceName, id)
end

-- Remove a prompt / text ui from screen
---@param id string @ Prompt identifier from the owning resource
Functions.hidePrompt = function(id)
    local resourceName = getPromptResourceName()

    SendNUIMessage({
        event = "RemovePrompt",
        data = { id = id, resource = resourceName }
    })

    local resourcePrompts = openPrompts[resourceName]
    if (not resourcePrompts) then return end

    resourcePrompts[id] = nil
    if (next(resourcePrompts) ~= nil) then return end

    openPrompts[resourceName] = nil
end

--- Check if a prompt / text ui is currently shown
---@param id string @ Prompt identifier from the owning resource
---@return boolean isOpen
Functions.isPromptOpen = function(id)
    local resourcePrompts = openPrompts[getPromptResourceName()]
    if (not resourcePrompts) then return false end

    return resourcePrompts[id] == true
end

---@param resourceName string @ Stopping resource name
AddEventHandler("onClientResourceStop", function(resourceName)
    SendNUIMessage({
        event = "RemovePrompt",
        data = { resource = resourceName }
    })

    openPrompts[resourceName] = nil
end)