local isOpen = {}

--- Show a prompt / text ui on screen
---@param id string @ Unique identifier (allows updates & removal)
---@param key string @ Key label to display in the kbd element (e.g. "E", "U")
---@param label string @ Text label next to the key
Functions.showPrompt = function(id, key, label)
    SendNUIMessage({
        event = "ShowPrompt",
        data = { id = id, key = key, label = label }
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
