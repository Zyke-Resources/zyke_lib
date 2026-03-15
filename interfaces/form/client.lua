local pending = {}
local formCounter = 0
local activeFormId = nil

-- Registered once, matches formId to resolve the correct promise
RegisterNUICallback("Eventhandler:Form", function(passed, cb)
    cb("ok")
    SetNuiFocus(false, false)

    local data = passed.data
    local formId = data.formId
    local p = pending[formId]

    if (not p) then return end

    pending[formId] = nil
    activeFormId = nil

    if (data.submitted) then
        p:resolve(data.values)
    else
        p:resolve(nil)
    end
end)

--- Preprocess special input types before sending to NUI
---@param inputs table[]
---@return table[]
local function preprocessInputs(inputs)
    local processed = {}

    for i, input in ipairs(inputs) do
        local entry = {}
        for k, v in pairs(input) do entry[k] = v end

        if (entry.type == "select-player") then
            entry.type = "select"
            entry.searchable = entry.searchable ~= false -- default true

            local players = Z.getPlayers()
            local playerDetails = Z.getCharacter(players)
            local content = {}

            for _, detail in pairs(playerDetails) do
                if (detail.identifier) then
                    content[#content+1] = {
                        label = "(" .. detail.source .. ") " .. (detail?.firstname or "Unknown") .. " " .. (detail?.lastname or ""),
                        value = detail.identifier,
                    }
                end
            end

            entry.content = content

            -- Default icon to person if none set
            if (not entry.icon) then entry.icon = "person" end
        end

        processed[i] = entry
    end

    return processed
end

--- Close a form by its formId, resolving the pending promise as nil
---@param formId string
local function resolveAndClose(formId)
    local p = pending[formId]
    if (not p) then return end

    pending[formId] = nil
    if (activeFormId == formId) then activeFormId = nil end

    SendNUIMessage({ event = "CloseForm" })
    SetNuiFocus(false, false)

    p:resolve(nil)
end

--- Open a form dialog and yield until the player submits or cancels
---@param title string @ Title displayed in the form header
---@param inputs table[] @ Array of input definitions ({ type, name, label, ... })
---@param options? table @ Optional: { icon, width, submitText, submitIcon, submitColor, disableClickOutside, showCancel }
---@return table | nil @ Values keyed by input name, or nil if cancelled
local function openForm(title, inputs, options)
    -- Close any existing form first
    if (activeFormId) then resolveAndClose(activeFormId) end

    formCounter = formCounter + 1
    local formId = "form_" .. formCounter

    local p = promise.new()
    pending[formId] = p
    activeFormId = formId

    local processedInputs = preprocessInputs(inputs)

    SendNUIMessage({
        event = "OpenForm",
        data = { formId = formId, title = title, inputs = processedInputs, options = options }
    })

    SetNuiFocus(true, true)

    return Citizen.Await(p)
end

--- Check if any form is currently open
---@return boolean
local function isFormOpen()
    return activeFormId ~= nil
end

--- Get the ID of the currently open form
---@return string | nil
local function getOpenFormId()
    return activeFormId
end

--- Close the currently open form (resolves as nil / cancelled)
local function closeForm()
    if (not activeFormId) then return end
    resolveAndClose(activeFormId)
end

--- Close a specific form by ID (resolves as nil / cancelled)
---@param formId string
local function closeFormById(formId)
    if (not formId or not pending[formId]) then return end
    resolveAndClose(formId)
end

Functions.openForm = openForm
Functions.isFormOpen = isFormOpen
Functions.getOpenFormId = getOpenFormId
Functions.closeForm = closeForm
Functions.closeFormById = closeFormById