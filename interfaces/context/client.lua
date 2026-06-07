---@alias ContextPosition 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
---@alias ContextMode 'action' | 'select' | 'multiselect'
---@alias ContextHints string | string[]

---@class ContextMetadata
---@field label string
---@field value any
---@field progress? number @ Progress bar value (0--100)
---@field colorScheme? string @ CSS variable name for progress bar colour

---@class ContextAmount
---@field default number @ Starting value (default: 1)
---@field min number @ Minimum value (default: 1)
---@field max number @ Maximum value
---@field step? number @ Increment per scroll tick (default: 1)
---@field vars? table<string, number> @ Named variables accessible in template expressions (e.g. `{ price = 30 }`)

---@class ContextOption
---@field title string @ Supports `{amount}` templates when `amount` is set
---@field description? string @ Supports `{amount}` templates when `amount` is set
---@field icon? string @ Resolved via IconRegistry, falls back to Material Icons
---@field iconColor? string @ CSS color for the icon
---@field image? string @ Image URL (e.g. from `Z.getInventoryImagePath`). Takes priority over `icon`
---@field disabled? boolean @ Greys out the option and prevents interaction
---@field readOnly? boolean @ Prevents selection/navigation while keeping normal text, icon, hover, and metadata styling
---@field menu? string | table @ String id (registered menu) or inline ContextMenuData table
---@field close? boolean @ If false, runs this option's action without closing the context menu
---@field onSelect? fun(args?: any, amount?: number)
---@field onHover? fun(args?: any)
---@field event? string @ Client event to trigger on select
---@field serverEvent? string @ Server event to trigger on select
---@field args? any @ Data forwarded to onSelect, event, or serverEvent
---@field value? any @ Value returned when selected (used in select/multiselect modes)
---@field arrow? boolean @ Force-show or hide the navigation arrow. Auto-shown when `menu` is set
---@field metadata? ContextMetadata[] @ Array of metadata entries shown in the hover popout. `label`/`value` support `{amount}` templates
---@field progress? number @ Progress bar value (0--100) rendered below the title
---@field colorScheme? string @ CSS variable name for progress bar colour
---@field amount? ContextAmount @ Scrollable amount tracker. Title/description/metadata update in real-time

---@class ContextMenuData
---@field id? string @ Unique identifier. Auto-generated if omitted
---@field title string
---@field description? string
---@field icon? string @ Header icon name
---@field position? ContextPosition @ Default `"top-right"`
---@field mode? ContextMode @ Default `"action"`
---@field canClose? boolean @ Default `true`
---@field hints? ContextHints @ Optional footer hint, or rotating list of hints, shown bottom-right
---@field menu? string @ Parent menu id for back navigation
---@field onExit? fun() @ Callback fired when the menu closes
---@field onBack? fun() @ Callback fired when the player presses back
---@field onHoverEnd? fun() @ Callback fired when the player stops hovering an option
---@field options ContextOption[]

--- Registered menus indexed by ID. Populated by `registerContext()`.
---@type table<string, ContextMenuData>
local registeredMenus = {}

--- Menu data for currently active (opened) menus. Includes both registered and inline menus.
---@type table<string, ContextMenuData>
local activeMenuData = {}

--- NUI-safe menu payloads for currently active menus.
---@type table<string, ContextMenuData>
local activeMenuPayloads = {}

--- Parent menu IDs for active inline menus.
---@type table<string, string>
local activeMenuParents = {}

--- Pending promises indexed by menu ID. Each promise resolves when the menu closes or an option is selected.
---@type table<string, promise>
local pending = {}

--- ID of the currently open context menu, or `nil` if none.
---@type string|nil
local activeMenuId = nil

--- ID of the menu that owns the pending promise for the current navigation tree.
---@type string|nil
local rootMenuId = nil

--- Auto-incrementing counter used to generate unique menu IDs.
---@type integer
local contextCounter = 0

--- Resolves a menu reference to its ContextMenuData table.
--- If `data` is a string, looks up in `activeMenuData` then `registeredMenus`.
--- If `data` is already a table, returns it as-is.
---@param data string|table
---@return ContextMenuData|nil
local function resolveMenuData(data)
    if (type(data) == "string") then
        return activeMenuData[data] or registeredMenus[data]
    end
    return data
end

---@param menuData ContextMenuData
---@param prefix? string
---@return string menuId
local function ensureMenuId(menuData, prefix)
    if (menuData.id) then return menuData.id end

    contextCounter = contextCounter + 1
    menuData.id = (prefix or "context") .. "_" .. contextCounter

    return menuData.id
end

---@param value any
---@param seen? table<table, boolean>
---@return any payloadValue
local function copyPayloadValue(value, seen)
    if (type(value) ~= "table") then return value end

    seen = seen or {}
    if (seen[value]) then return nil end
    seen[value] = true

    local copy = {}

    for key, childValue in pairs(value) do
        if (type(childValue) ~= "function") then
            copy[key] = copyPayloadValue(childValue, seen)
        end
    end

    seen[value] = nil

    return copy
end

---@param option ContextOption
---@param parentId string
---@return ContextOption payload
local function buildOptionPayload(option, parentId)
    local payload = {}

    for key, value in pairs(option) do
        if (key ~= "menu" and type(value) ~= "function") then
            payload[key] = copyPayloadValue(value)
        end
    end

    if (type(option.menu) == "table") then
        local childData = option.menu
        local childId = ensureMenuId(childData, "inline")
        activeMenuParents[childId] = childData.menu or parentId
        activeMenuData[childId] = childData
        payload.menu = childId
    elseif (type(option.menu) == "string") then
        payload.menu = option.menu
    end

    return payload
end

---@param menuData ContextMenuData
---@param parentId? string
---@return ContextMenuData payload
local function buildMenuPayload(menuData, parentId)
    local menuId = ensureMenuId(menuData)
    local payload = {}

    activeMenuData[menuId] = menuData

    for key, value in pairs(menuData) do
        if (key ~= "options" and type(value) ~= "function") then
            payload[key] = copyPayloadValue(value)
        end
    end

    payload.id = menuId
    payload.menu = menuData.menu or parentId
    payload.options = {}

    for i = 1, #(menuData.options or {}) do
        payload.options[i] = buildOptionPayload(menuData.options[i], menuId)
    end

    activeMenuPayloads[menuId] = payload

    return payload
end

--- Clears the pending promise and active data for a given menu ID.
--- Resets all active context state because only one context tree can be open at a time.
---@param menuId string
local function cleanupPending(menuId)
    local pendingMenuId = pending[menuId] and menuId or rootMenuId
    if (pendingMenuId) then
        pending[pendingMenuId] = nil
    end

    activeMenuId = nil
    rootMenuId = nil
    activeMenuData = {}
    activeMenuPayloads = {}
    activeMenuParents = {}
end

---@param menuId string
---@return promise? pendingPromise
local function getPendingPromise(menuId)
    if (pending[menuId]) then return pending[menuId] end
    if (rootMenuId and pending[rootMenuId]) then return pending[rootMenuId] end

    return nil
end

---@param option? ContextOption @ Selected context option
---@return boolean shouldClose
local function shouldCloseOption(option)
    if (not option) then return true end
    if (option.close == false) then return false end
    if (type(option.args) == "table" and option.args.close == false) then return false end

    return true
end

---@param menuId string @ Active menu ID
local function refreshOpenMenu(menuId)
    local menuData = resolveMenuData(menuId)
    if (not menuData) then return end

    local parentId = activeMenuParents[menuId] or menuData.menu
    local payload = buildMenuPayload(menuData, parentId)
    activeMenuId = payload.id

    SendNUIMessage({
        event = menuId == rootMenuId and "OpenContextMenu" or "NavigateContextMenu",
        data = payload,
    })
    SetNuiFocus(true, true)
end

--- Fully closes a context menu: cleans up pending state, sends close to NUI, removes NUI focus,
--- optionally fires the menu's `onExit` callback, and resolves the pending promise as `nil`.
---@param menuId string
---@param runOnExit? boolean @ Whether to fire the `onExit` callback
local function doClose(menuId, runOnExit)
    local p = getPendingPromise(menuId)
    if (not p) then return end

    local menuData = resolveMenuData(menuId) or (rootMenuId and resolveMenuData(rootMenuId))
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
        local p = getPendingPromise(menuId)
        if (not p) then return end

        local menuData = resolveMenuData(menuId)
        local optionIndex = data.optionIndex
        local option = menuData and menuData.options and menuData.options[optionIndex]
        local shouldClose = shouldCloseOption(option)

        if (shouldClose) then
            cleanupPending(menuId)
            SendNUIMessage({ event = "CloseContextMenu" })
            SetNuiFocus(false, false)
        end

        if (option) then
            if (option.onSelect) then
                option.onSelect(option.args, data.amount)
            end

            if (option.event) then
                TriggerEvent(option.event, option.args)
            end

            if (option.serverEvent) then
                TriggerServerEvent(option.serverEvent, option.args)
            end

            local result = option.args ~= nil and option.args or option.value or true
            if (data.amount ~= nil) then
                if (type(result) == "table") then
                    result.amount = data.amount
                else
                    result = { value = result, amount = data.amount }
                end
            end

            if (shouldClose) then
                p:resolve(result)
            else
                refreshOpenMenu(menuId)
            end
        else
            p:resolve(nil)
        end
    elseif (action == "confirm") then
        local menuId = data.menuId
        local p = getPendingPromise(menuId)
        if (not p) then return end

        cleanupPending(menuId)
        SendNUIMessage({ event = "CloseContextMenu" })
        SetNuiFocus(false, false)

        p:resolve(data.selected)
    elseif (action == "hover") then
        local menuId = data.menuId
        if (not getPendingPromise(menuId)) then return end

        local menuData = resolveMenuData(menuId)
        local optionIndex = data.optionIndex
        local option = menuData and menuData.options and menuData.options[optionIndex]

        if (option and option.onHover) then
            option.onHover(option.args or option.value)
        end
    elseif (action == "hoverEnd") then
        local menuId = data.menuId
        if (not getPendingPromise(menuId)) then return end

        local menuData = resolveMenuData(menuId)

        if (menuData and menuData.onHoverEnd) then
            menuData.onHoverEnd()
        end
    elseif (action == "navigate") then
        local menuId = data.menuId
        local targetId = data.targetId
        local targetData = resolveMenuData(targetId)

        if (targetData) then
            local targetPayload = buildMenuPayload(targetData, type(targetId) == "string" and activeMenuParents[targetId] or menuId)

            SendNUIMessage({
                event = "NavigateContextMenu",
                data = targetPayload,
            })

            activeMenuId = targetPayload.id
        end
    elseif (action == "back") then
        local menuId = data.menuId
        local currentData = resolveMenuData(menuId)

        if (currentData and currentData.onBack) then
            currentData.onBack()
        end

        local parentId = currentData and currentData.menu or activeMenuParents[menuId]
        if (parentId) then
            local parentPayload = activeMenuPayloads[parentId]
            if (not parentPayload) then
                local parentData = resolveMenuData(parentId)
                parentPayload = parentData and buildMenuPayload(parentData) or nil
            end

            if (parentPayload) then
                SendNUIMessage({
                    event = "NavigateContextMenu",
                    data = parentPayload,
                })
                activeMenuId = parentPayload.id or parentId
            end
        else
            doClose(menuId, true)
        end
    elseif (action == "close") then
        local menuId = data.menuId
        doClose(menuId, true)
    end
end)

---@param context ContextMenuData
---@return nil
local function registerSingleContext(context)
    if (type(context) ~= "table") then return end

    local id = context.id
    if (not id) then return end

    registeredMenus[id] = context
    if (activeMenuData[id]) then
        activeMenuData[id] = context
        activeMenuPayloads[id] = nil
    end
end

--- Registers one or more context menus by ID so they can be opened with `showContext()` or used as sub-menu targets.
--- Does not open the menu.
---@param context ContextMenuData | ContextMenuData[]
local function registerContext(context)
    if (type(context) ~= "table") then return end

    if (not context.id and type(context[1]) == "table") then
        for i = 1, #context do
            registerSingleContext(context[i])
        end

        return
    end

    registerSingleContext(context)
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
    rootMenuId = menuId
    activeMenuData[menuId] = menuData

    SendNUIMessage({
        event = "OpenContextMenu",
        data = buildMenuPayload(menuData),
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
    rootMenuId = menuId
    activeMenuData[menuId] = data

    SendNUIMessage({
        event = "OpenContextMenu",
        data = buildMenuPayload(data),
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
