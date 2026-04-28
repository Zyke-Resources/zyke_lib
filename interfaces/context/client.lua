---@alias ContextPosition 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
---@alias ContextMode 'action' | 'select' | 'multiselect'

---@class ContextMetadata
---@field label string
---@field value any
---@field progress? number @ Progress bar value (0--100)
---@field colorScheme? string @ CSS variable name for progress bar colour

---@class ContextOption
---@field title string
---@field description? string
---@field icon? string @ Resolved via IconRegistry, falls back to Material Icons
---@field iconColor? string @ CSS color for the icon
---@field image? string @ Image URL (e.g. from `Z.getInventoryImagePath`). Takes priority over `icon`
---@field disabled? boolean @ Greys out the option and prevents interaction
---@field readOnly? boolean @ Prevents interaction but keeps full opacity
---@field menu? string|table @ String id (registered menu) or inline ContextMenuData table
---@field onSelect? fun(args?: any)
---@field event? string @ Client event to trigger on select
---@field serverEvent? string @ Server event to trigger on select
---@field args? any @ Data forwarded to onSelect, event, or serverEvent
---@field value? any @ Value returned when selected (used in select/multiselect modes)
---@field arrow? boolean @ Force-show or hide the navigation arrow. Auto-shown when `menu` is set
---@field metadata? ContextMetadata[] @ Array of metadata entries shown in the hover popout
---@field progress? number @ Progress bar value (0--100) rendered below the title
---@field colorScheme? string @ CSS variable name for progress bar colour

---@class ContextMenuData
---@field id? string @ Unique identifier. Auto-generated if omitted
---@field title string
---@field description? string
---@field icon? string @ Header icon name
---@field position? ContextPosition @ Default `"top-right"`
---@field mode? ContextMode @ Default `"action"`
---@field canClose? boolean @ Default `true`
---@field menu? string @ Parent menu id for back navigation
---@field onExit? fun() @ Callback fired when the menu closes
---@field onBack? fun() @ Callback fired when the player presses back
---@field options ContextOption[]

--- Registered menus indexed by ID. Populated by `registerContext()`.
---@type table<string, ContextMenuData>
local registeredMenus = {}

--- Menu data for currently active (opened) menus. Includes both registered and inline menus.
---@type table<string, ContextMenuData>
local activeMenuData = {}

--- Pending promises indexed by menu ID. Each promise resolves when the menu closes or an option is selected.
---@type table<string, promise>
local pending = {}

--- ID of the currently open context menu, or `nil` if none.
---@type string|nil
local activeMenuId = nil

--- Auto-incrementing counter used to generate unique menu IDs.
---@type integer
local contextCounter = 0

--- Resolves a menu reference to its ContextMenuData table.
--- If `data` is a string, looks up in `registeredMenus` then `activeMenuData`.
--- If `data` is already a table, returns it as-is.
---@param data string|table
---@return ContextMenuData|nil
local function resolveMenuData(data)
    if (type(data) == "string") then
        return registeredMenus[data] or activeMenuData[data]
    end
    return data
end

--- Clears the pending promise and active data for a given menu ID.
--- Resets `activeMenuId` if it matches.
---@param menuId string
local function cleanupPending(menuId)
    if (activeMenuId == menuId) then
        activeMenuId = nil
    end
    pending[menuId] = nil
    activeMenuData[menuId] = nil
end

--- Fully closes a context menu: cleans up pending state, sends close to NUI, removes NUI focus,
--- optionally fires the menu's `onExit` callback, and resolves the pending promise as `nil`.
---@param menuId string
---@param runOnExit? boolean @ Whether to fire the `onExit` callback
local function doClose(menuId, runOnExit)
    local p = pending[menuId]
    if (not p) then return end

    local menuData = resolveMenuData(menuId)
    cleanupPending(menuId)

    SendNUIMessage({ event = "CloseContextMenu" })
    SetNuiFocus(false, false)

    if (runOnExit and menuData and menuData.onExit) then
        menuData.onExit()
    end

    p:resolve(nil)
end

--- NUI callback handler for all context menu actions dispatched from the frontend.
--- Actions:
---   `select`   -- player clicked an option in `action` mode. Fires `onSelect`, `event`, `serverEvent` on the option, then resolves the promise.
---   `confirm`  -- player confirmed selection in `select`/`multiselect` mode. Resolves with the array of selected values.
---   `navigate` -- player clicked an option with a `menu` field. Sends the target menu data to NUI via `NavigateContextMenu`.
---   `back`     -- player pressed back. Fires `onBack` on the current menu, then navigates to the parent or closes if none.
---   `close`    -- player closed the menu (ESC, click-outside, or close button). Calls `doClose`.
RegisterNUICallback("Eventhandler:Context", function(passed, cb)
    cb("ok")

    local action = passed.event
    local data = passed.data

    if (action == "select") then
        local menuId = data.menuId
        local p = pending[menuId]
        if (not p) then return end

        local menuData = resolveMenuData(menuId)
        local optionIndex = data.optionIndex
        local option = menuData and menuData.options and menuData.options[optionIndex]

        cleanupPending(menuId)
        SendNUIMessage({ event = "CloseContextMenu" })
        SetNuiFocus(false, false)

        if (option) then
            if (option.onSelect) then
                option.onSelect(option.args)
            end

            if (option.event) then
                TriggerEvent(option.event, option.args)
            end

            if (option.serverEvent) then
                TriggerServerEvent(option.serverEvent, option.args)
            end

            p:resolve(option.args ~= nil and option.args or option.value or true)
        else
            p:resolve(nil)
        end
    elseif (action == "confirm") then
        local menuId = data.menuId
        local p = pending[menuId]
        if (not p) then return end

        cleanupPending(menuId)
        SendNUIMessage({ event = "CloseContextMenu" })
        SetNuiFocus(false, false)

        p:resolve(data.selected)
    elseif (action == "navigate") then
        local targetId = data.targetId
        local targetData = resolveMenuData(targetId)

        if (targetData) then
            if (type(targetId) ~= "string") then
                contextCounter = contextCounter + 1
                targetData.id = "inline_" .. contextCounter
            end

            SendNUIMessage({
                event = "NavigateContextMenu",
                data = targetData,
            })

            activeMenuId = targetData.id
        end
    elseif (action == "back") then
        local menuId = data.menuId
        local currentData = resolveMenuData(menuId)

        if (currentData and currentData.onBack) then
            currentData.onBack()
        end

        local parentId = currentData and currentData.menu
        if (parentId) then
            local parentData = resolveMenuData(parentId)
            if (parentData) then
                SendNUIMessage({
                    event = "NavigateContextMenu",
                    data = parentData,
                })
                activeMenuId = parentData.id or parentId
            end
        else
            doClose(menuId, true)
        end
    elseif (action == "close") then
        local menuId = data.menuId
        doClose(menuId, true)
    end
end)

--- Registers a context menu by ID so it can be opened with `showContext()` or used as a sub-menu target.
--- Does not open the menu.
---@param context ContextMenuData
local function registerContext(context)
    local id = context.id
    if (not id) then return end

    registeredMenus[id] = context
end

--- Opens a previously registered context menu by ID. Blocks until the player selects an option or closes the menu.
--- Returns the selected option's `args`, `value`, or `true` on select. Returns `nil` if cancelled.
---@param id string
---@return any|nil
local function showContext(id)
    local menuData = resolveMenuData(id)
    if (not menuData) then return nil end

    if (activeMenuId) then
        doClose(activeMenuId, true)
    end

    contextCounter = contextCounter + 1
    local menuId = menuData.id or ("context_" .. contextCounter)
    menuData.id = menuId

    local p = promise.new()
    pending[menuId] = p
    activeMenuId = menuId
    activeMenuData[menuId] = menuData

    SendNUIMessage({
        event = "OpenContextMenu",
        data = menuData,
    })

    SetNuiFocus(true, true)

    return Citizen.Await(p)
end

--- Opens a context menu directly from a table. Blocks until the player selects an option or closes the menu.
--- Returns the selected option's `args`, `value`, or `true` on select. Returns `nil` if cancelled.
---@param data ContextMenuData
---@return any|nil
local function openContext(data)
    if (activeMenuId) then
        doClose(activeMenuId, true)
    end

    contextCounter = contextCounter + 1
    local menuId = data.id or ("context_" .. contextCounter)
    data.id = menuId

    local p = promise.new()
    pending[menuId] = p
    activeMenuId = menuId
    activeMenuData[menuId] = data

    SendNUIMessage({
        event = "OpenContextMenu",
        data = data,
    })

    SetNuiFocus(true, true)

    return Citizen.Await(p)
end

--- Soft-closes the active context menu. Resolves the pending promise as `nil`.
---@param runOnExit? boolean @ Whether to fire the menu's `onExit` callback (default `true`)
local function hideContext(runOnExit)
    if (not activeMenuId) then return end

    doClose(activeMenuId, runOnExit ~= false)
end

--- Closes the active context menu. Always runs the `onExit` callback. Resolves as `nil`.
local function closeContext()
    if (not activeMenuId) then return end

    doClose(activeMenuId, true)
end

---@return boolean
local function isContextOpen()
    return activeMenuId ~= nil
end

---@return string|nil
local function getOpenContextMenu()
    return activeMenuId
end

Functions.registerContext = registerContext
Functions.showContext = showContext
Functions.openContext = openContext
Functions.hideContext = hideContext
Functions.closeContext = closeContext
Functions.isContextOpen = isContextOpen
Functions.getOpenContextMenu = getOpenContextMenu