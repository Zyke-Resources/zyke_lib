---@alias FormInputType "paragraph" | "hint" | "text" | "number" | "select" | "select-player" | "checkbox" | "slider" | "textarea"
---@alias FormHintSeverity "info" | "warning" | "error" | "danger"

---@class FormInput
---@field type FormInputType
---@field name? string @ Key used in the returned values table. Not required for static paragraph/hint inputs
---@field label? string
---@field title? string @ Hint title when type is "hint". Falls back to label
---@field text? string | string[] @ Static text for paragraph/hint inputs
---@field placeholder? string
---@field description? string
---@field icon? string | false @ Resolved via IconRegistry, falls back to Material Icons. Set false on hints to hide the default icon
---@field severity? FormHintSeverity @ Hint color/icon severity when type is "hint" (default "info")
---@field disabled? boolean
---@field defaultValue? any
---@field content? { label: string, value: any }[] @ select/multiselect options
---@field searchable? boolean @ select: enable search filtering (default true)
---@field multiselect? boolean @ select: allow multiple selections
---@field min? number @ number/slider
---@field max? number @ number/slider
---@field step? number @ number/slider
---@field marks? { value: number, label?: string }[] @ slider tick marks
---@field minRows? number @ textarea (default 3)
---@field maxRows? number @ textarea (default 6)
---@field maxLength? number @ textarea

---@class FormButton
---@field text string
---@field icon? string
---@field color? string @ CSS color (e.g. "var(--blue2)")
---@field action? string @ Forwarded to caller via `result._action`
---@field timeout? number @ Seconds the button stays disabled after the form opens
---@field close? boolean @ If false, runs this button's onSelect without closing the form
---@field onSelect? fun(values: table, formId: string, action: string): table | nil @ Handles this button when `close = false`

---@class FormOptions
---@field icon? string @ Header icon
---@field width? string @ CSS width (default "30rem")
---@field showCancel? boolean @ Default true
---@field disableClickOutside? boolean
---@field buttons? FormButton[]
---@field submitText? string @ **@deprecated** use buttons[]
---@field submitIcon? string @ **@deprecated** use buttons[]
---@field submitColor? string @ **@deprecated** use buttons[]

---@class FormResult
---@field _action? string @ The clicked button's `action` field
---@field [string] any @ Values keyed by input `name`

---@type table<string, promise>
local pending = {}

---@type table<string, table<string, fun(values: table, formId: string, action: string): table | nil>>
local selectHandlers = {}

---@type integer
local formCounter = 0

---@type string | nil
local activeFormId = nil

local formSelectExport = "__zyke_formSelect"

-- Non-closing button callbacks are kept in Lua and never sent to NUI
-- For external resources, __select metadata tells zyke_lib where to call the stored onSelect

---@param index integer @ Button index from the options array
---@return string
local function getButtonKey(index)
    return ("button_%s"):format(index)
end

---@param target table @ Serialized select bridge details
---@param buttonKey string @ Internal button key generated from button order
---@param values table @ Current form values
---@param formId string @ Active form id
---@param action string @ Button action value
---@return table
local function runExternalSelect(target, buttonKey, values, formId, action)
    local resource = target.resource
    local handlerId = target.handlerId

    if (type(resource) ~= "string" or type(handlerId) ~= "string") then return {} end

    local ok, result = pcall(function()
        -- FiveM Lua exports discard the method-style self slot, so dynamic dot calls pass nil first
        return exports[resource][formSelectExport](nil, handlerId, buttonKey, values, formId, action)
    end)

    if (not ok) then
        print(("^1[FORM] External select handler failed for form '%s' in resource '%s': %s^7"):format(formId, resource, tostring(result)))
        return {}
    end

    if (type(result) ~= "table") then return {} end

    return result
end

-- Strip Lua-only fields before sending options to NUI. NUI only needs serializable button data
---@param options table @ Form options to sanitize for NUI
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

---@param passed? table @ NUI callback payload
---@param cb function @ NUI callback response
local function handleFormNuiCallback(passed, cb)
    passed = passed or {}

    local event = passed.event
    local data = passed.data or {}
    local formId = data.formId
    local p = pending[formId]

    if (not p) then
        cb(event == "FormSelect" and {} or "ok")
        return
    end

    -- FormSelect is used only by close=false buttons. Submit/cancel resolution stays on the normal path below
    if (event == "FormSelect") then
        local buttonKey = data.buttonKey or data.action or "primary"
        local handler = selectHandlers[formId] and selectHandlers[formId][buttonKey]

        if (not handler) then
            print(("^1[FORM] No select handler registered for form '%s' button '%s' action '%s'.^7"):format(
                tostring(formId),
                tostring(buttonKey),
                tostring(data.action)
            ))
            cb({})
            return
        end

        cb({ pending = true })

        CreateThread(function()
            -- The select callback can yield, so NUI gets an immediate pending response and receives the result by message
            local ok, result = pcall(handler, data.values or {}, formId, data.action)
            local response = {}

            if (ok) then
                response = type(result) == "table" and result or {}
            else
                print(("^1[FORM] Select handler failed for form '%s': %s^7"):format(formId, tostring(result)))
            end

            SendNUIMessage({
                event = "FormSelectResult",
                data = {
                    formId = formId,
                    action = data.action,
                    buttonKey = buttonKey,
                    response = response or {},
                }
            })
        end)

        return
    end

    cb("ok")
    SetNuiFocus(false, false)

    pending[formId] = nil
    selectHandlers[formId] = nil
    activeFormId = nil

    if (data.submitted) then
        local values = data.values

        if (type(values) == "table" and data.action) then
            values._action = data.action
        end

        p:resolve(values)
    else
        p:resolve(nil)
    end
end

RegisterNUICallback("Eventhandler:Form", handleFormNuiCallback)

---@param inputs FormInput[] @ Input definitions from Lua
---@return FormInput[]
local function preprocessInputs(inputs)
    local processed = {}

    for i, input in ipairs(inputs) do
        local entry = {}

        for k, v in pairs(input) do entry[k] = v end

        if (entry.type == "select-player") then
            entry.type = "select"
            entry.searchable = entry.searchable ~= false

            local players = Z.getPlayers()
            local playerDetails = Z.getCharacter(players)
            if (not playerDetails or type(playerDetails) ~= "table") then playerDetails = {} end

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

            if (not entry.icon) then entry.icon = "person" end
        end

        processed[i] = entry
    end

    return processed
end

---@param formId string @ Form id to resolve and close
local function resolveAndClose(formId)
    local p = pending[formId]
    if (not p) then return end

    pending[formId] = nil
    selectHandlers[formId] = nil
    if (activeFormId == formId) then activeFormId = nil end

    SendNUIMessage({ event = "CloseForm" })
    SetNuiFocus(false, false)

    p:resolve(nil)
end

---@param options? FormOptions @ Form options from Lua
---@param formId string @ Active form id
---@return FormOptions | nil
local function prepareFormOptions(options, formId)
    if (type(options) ~= "table") then return options end

    local externalSelect = type(options.__select) == "table" and options.__select or nil
    local buttons = options.buttons
    if (type(buttons) ~= "table") then return copyFormOptions(options, true) end

    local nuiOptions = copyFormOptions(options, false)
    nuiOptions.buttons = {}

    for i = 1, #buttons do
        local button = buttons[i]

        if (type(button) == "table") then
            -- Generated keys keep callbacks stable even if multiple buttons share text or action values
            local buttonKey = getButtonKey(i)
            local handler = type(button.onSelect) == "function" and button.onSelect or nil

            if (button.close == false and not handler and externalSelect) then
                handler = function(values, currentFormId, action)
                    return runExternalSelect(externalSelect, buttonKey, values, currentFormId, action)
                end
            end

            if (button.close == false and handler) then
                if (not selectHandlers[formId]) then selectHandlers[formId] = {} end
                selectHandlers[formId][buttonKey] = handler
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

    return nuiOptions
end

--- Opens a modal form and yields until submitted or cancelled
---@param title string @ Form title
---@param inputs FormInput[] @ Input definitions
---@param options? FormOptions @ Modal options
---@return FormResult | nil @ nil if cancelled
local function openForm(title, inputs, options)
    if (activeFormId) then resolveAndClose(activeFormId) end

    formCounter = formCounter + 1
    local formId = "form_" .. formCounter

    local p = promise.new()
    pending[formId] = p
    activeFormId = formId

    local processedInputs = preprocessInputs(inputs)
    local nuiOptions = prepareFormOptions(options, formId)

    SendNUIMessage({
        event = "OpenForm",
        data = { formId = formId, title = title, inputs = processedInputs, options = nuiOptions }
    })

    SetNuiFocus(true, true)

    return Citizen.Await(p)
end

---@return boolean
local function isFormOpen()
    return activeFormId ~= nil
end

---@return string | nil
local function getOpenFormId()
    return activeFormId
end

--- Closes the active form
local function closeForm()
    if (not activeFormId) then return end

    resolveAndClose(activeFormId)
end

---@param formId string @ Form id to close
local function closeFormById(formId)
    if (not formId or not pending[formId]) then return end

    resolveAndClose(formId)
end

Functions.openForm = openForm
Functions.isFormOpen = isFormOpen
Functions.getOpenFormId = getOpenFormId
Functions.closeForm = closeForm
Functions.closeFormById = closeFormById