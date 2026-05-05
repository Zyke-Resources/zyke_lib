---@alias FormInputType "paragraph" | "text" | "number" | "select" | "select-player" | "checkbox" | "slider" | "textarea"

---@class FormInput
---@field type FormInputType
---@field name? string @ Key used in the returned values table. Not required for paragraph inputs.
---@field label? string
---@field text? string | string[] @ Paragraph content when type is "paragraph"
---@field placeholder? string
---@field description? string
---@field icon? string @ Resolved via IconRegistry, falls back to Material Icons
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
---@field color? string @ CSS color (e.g. "var(--blue1)")
---@field action? string @ Forwarded to caller via `result._action`
---@field timeout? number @ Seconds the button stays disabled after the form opens

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

---@type integer
local formCounter = 0

---@type string | nil
local activeFormId = nil

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
        local values = data.values
        if (type(values) == "table" and data.action) then
            values._action = data.action
        end
        p:resolve(values)
    else
        p:resolve(nil)
    end
end)

---@param inputs FormInput[]
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

--- Opens a modal form and yields until submitted or cancelled. Only one form can be active at a time.
--- When `buttons[]` is used, `result._action` contains the clicked button's `action` field.
---@param title string
---@param inputs FormInput[]
---@param options? FormOptions
---@return FormResult | nil @ nil if cancelled
local function openForm(title, inputs, options)
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

---@return boolean
local function isFormOpen()
    return activeFormId ~= nil
end

---@return string | nil
local function getOpenFormId()
    return activeFormId
end

local function closeForm()
    if (not activeFormId) then return end

    resolveAndClose(activeFormId)
end

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