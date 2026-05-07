-- This wrapper runs in the resource that calls Z.openForm
-- onSelect functions stay here, while zyke_lib receives serializable button metadata for the NUI form

local selectHandlerCounter = 0
FormSelectHandlers = FormSelectHandlers or {}
local selectHandlers = FormSelectHandlers

---@param index integer @ Button index from the options array
---@return string
local function getButtonKey(index)
    return ("button_%s"):format(index)
end

---@param options table @ Form options to sanitize before exporting
---@param includeButtons boolean @ Whether to include the buttons array
---@return table
local function copyFormOptions(options, includeButtons)
    local nuiOptions = {}

    for k, v in pairs(options) do
        if (k ~= "__select" and (includeButtons or k ~= "buttons") and type(v) ~= "function") then
            nuiOptions[k] = v
        end
    end

    return nuiOptions
end

---@param options? table @ Form options from the calling resource
---@return table | nil nuiOptions
---@return table | nil registration
local function prepareOptions(options)
    if (type(options) ~= "table") then return options, nil end

    local buttons = options.buttons
    local handlers = {}
    local hasHandlers = false
    local nuiOptions = copyFormOptions(options, false)

    if (type(buttons) ~= "table") then return nuiOptions, nil end

    nuiOptions.buttons = {}

    for i = 1, #buttons do
        local button = buttons[i]

        if (type(button) == "table") then
            local buttonKey = getButtonKey(i)
            local handler = type(button.onSelect) == "function" and button.onSelect or nil

            if (button.close == false and handler) then
                handlers[buttonKey] = handler
                hasHandlers = true
            end

            local nuiButton = {}
            for k, v in pairs(button) do
                if (k ~= "onSelect") then nuiButton[k] = v end
            end

            nuiButton.buttonKey = buttonKey
            nuiOptions.buttons[i] = nuiButton
        else
            nuiOptions.buttons[i] = button
        end
    end

    if (not hasHandlers) then return nuiOptions, nil end

    selectHandlerCounter = selectHandlerCounter + 1
    local handlerId = ("%s:%s"):format(ResName, selectHandlerCounter)

    nuiOptions.__select = {
        resource = ResName,
        handlerId = handlerId,
    }

    return nuiOptions, {
        id = handlerId,
        handlers = handlers,
    }
end

---@param title string @ Form title
---@param inputs table[] @ Input definitions
---@param nuiOptions? table @ Serializable modal options
---@return table | nil
local function runOpenFormExport(title, inputs, nuiOptions)
    -- FiveM Lua exports discard the method-style self slot, so dynamic dot calls pass nil first
    return exports[LibName].openForm(nil, title, inputs, nuiOptions)
end

---@param title string @ Form title
---@param inputs table[] @ Input definitions
---@param options? table @ Modal options
---@return table | nil
local function openForm(title, inputs, options)
    local nuiOptions, registration = prepareOptions(options)

    if (not registration) then
        return runOpenFormExport(title, inputs, nuiOptions)
    end

    selectHandlers[registration.id] = registration.handlers

    -- Always clear the local handler registry after zyke_lib resolves or errors
    local ok, result = pcall(function()
        return runOpenFormExport(title, inputs, nuiOptions)
    end)

    selectHandlers[registration.id] = nil

    if (not ok) then error(result, 2) end

    return result
end

return openForm