local isOpen = {}

--- Show a prompt / text ui on screen
--- Possibility to automatically resolve key label from command name to get the actual key bound to the action, without extra work
---@param id string @ Unique identifier (allows updates & removal)
---@param key string @ Key label to display in the kbd element (ex. "E", "U"), or a command name prefixed with "+" (ex. "+storeVehicle") to auto-resolve the key label
---@param label string @ Text label next to the key
Functions.showPrompt = function(id, key, label)
    local resolvedKey = key

    if (key:byte(1) == 43) then
        local keyData = Functions.keys.getKeyDataForCommand(key)
        resolvedKey = keyData and keyData.label or "?"
    end

    SendNUIMessage({
        event = "ShowPrompt",
        data = { id = id, key = resolvedKey, label = label }
    })

    isOpen[id] = true
end

--- Remove a prompt / text ui from screen
---@param id string
Functions.hidePrompt = function(id)
    SendNUIMessage({
        event = "RemovePrompt",
        data = { id = id }
    })

    isOpen[id] = nil
end

--- Check if a prompt / text ui is currently shown
---@param id string
---@return boolean
Functions.isPromptOpen = function(id)
    return isOpen[id] == true
end
