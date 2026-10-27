-- The key panel at the bottom of the screen, drawn by zyke_lib's NUI so the panels of every resource stack instead of
-- overlapping. The resource reads its own keys with Z.keybinds.handle; zyke_lib only draws

Functions.keybinds = {}

---@class KeybindItem
---@field label string
---@field key? string | string[] @ Z.keys names, such as "LEFTMOUSE" or {"SCROLLUP", "SCROLLDOWN"}
---@field hiddenKey? string | string[] @ Works without being shown, such as "BACKSPACE" beside "ESC"
---@field command? string @ A key mapping from Z.keybinds.addKeyMapping, which the player can rebind
---@field activate? string @ Z.keys name that has to be held for the item to show and work
---@field disable? string @ Z.keys name that hides and stops the item while held
---@field hold? boolean @ Runs func every frame the key is held instead of once per press
---@field func? fun(key?: string, keyCode?: integer) @ Leave out for a key the resource reads itself, which only shows

---@class KeybindDetail
---@field text string
---@field danger? boolean @ Shown in red

---@class KeybindBarItem
---@field label string
---@field image? string @ An nui:// path to its inventory icon
---@field amount? integer @ How many there are, left out for none shown

---@class KeybindBar @ A row of items over the panel, such as what can be taken into the hands
---@field items KeybindBarItem[]
---@field selected? integer @ Index of the item marked as in use

---@class KeybindOptions
---@field title? string
---@field detail? string | KeybindDetail @ Shown beside the title, such as a distance
---@field warning? string @ Why what the panel is about can not be done, floating above it
---@field hint? string @ What to do next, floating above it; a warning takes its place
---@field position? "bottom-left" | "bottom-center" | "bottom-right" @ Defaults to "bottom-center"
---@field bar? KeybindBar

---@class KeybindPanelData
---@field items {label: string, keys: string[]}[]
---@field title? string
---@field detail? KeybindDetail
---@field warning? string
---@field hint? string
---@field position string
---@field bar? {items: KeybindBarItem[], selected: integer} @ selected counts from 0, as the NUI does

local keys = Functions.keys.getAll()
-- Control IDs, as the S and D of Z.keys are the fly axes W and A move too
local controls = {S = 33, D = 35}
-- Only the keys whose cap is not their name
local caps = {LEFTMOUSE = "LMB", RIGHTMOUSE = "RMB", MIDDLEMOUSE = "MMB", SCROLLUP = "Scroll", SCROLLDOWN = "Scroll", LEFTSHIFT = "Shift", LEFTCTRL = "Ctrl", LEFTALT = "Alt", BACKSPACE = "Backspace", ESC = "Esc", SPACE = "Space", ENTER = "Enter", TAB = "Tab"}
-- Backspace and Escape, which open the pause menu too unless held back
local cancelControls = {[202] = true, [322] = true}
local pauseControls = {199, 200}
local pauseHoldMs = 500

-- The shown panels of this resource by their items table, each with its id in zyke_lib and what it last sent
---@type table<KeybindItem[], {id: string, options?: KeybindOptions, json?: string, modifiers?: boolean}>
local panels = {}
local panelCount = 0
-- Each shown command's bound control, so the game does not act on the key too
---@type table<string, integer>
local commandControls = {}

---@param key string | string[]
---@return string[] shown @ The caps of the keys, each once
local function getCaps(key)
    local shown, seen = {}, {}

    for _, name in ipairs(type(key) == "table" and key or {key}) do
        local cap = caps[name] or name

        if (not seen[cap]) then
            seen[cap] = true
            shown[#shown + 1] = cap
        end
    end

    return shown
end

---@param name string
---@return integer? control
local function getControl(name)
    return controls[name] or (keys[name] and keys[name].keyCode)
end

-- Whether the item's activate and disable keys let it show and work right now
---@param item KeybindItem
---@return boolean active
local function isActive(item)
    local activate = item.activate and getControl(item.activate)
    local disable = item.disable and getControl(item.disable)
    if (activate and not IsDisabledControlPressed(0, activate)) then return false end
    if (disable and IsDisabledControlPressed(0, disable)) then return false end

    return true
end

-- Builds what the NUI shows and sends it to zyke_lib when it changed
---@param items KeybindItem[]
local function send(items)
    local panel = panels[items]
    local options = panel.options or {}
    local buttons = {}

    for i = 1, #items do
        local item = items[i]

        if (isActive(item)) then
            local bound = item.command and Functions.keys.getKeyDataForCommand(item.command)
            if (item.command) then commandControls[item.command] = bound and bound.keyCode end

            buttons[#buttons + 1] = {label = item.label, keys = item.command and {bound and bound.label or "?"} or getCaps(item.key)}
        end
    end

    local detail = type(options.detail) == "string" and {text = options.detail} or options.detail
    local bar = options.bar and {items = options.bar.items, selected = (options.bar.selected or 0) - 1}
    local data = {items = buttons, title = options.title, detail = detail, warning = options.warning, hint = options.hint, position = options.position or "bottom-center", bar = bar}
    local encoded = json.encode(data)
    if (encoded == panel.json) then return end

    panel.json = encoded

    exports[LibName]:setKeybindPanel(panel.id, data)
end

-- The cancel that just closed whatever showed the panel would open the pause menu a frame later
local function holdPauseMenu()
    CreateThread(function()
        local heldUntil = GetGameTimer() + pauseHoldMs

        while (GetGameTimer() < heldUntil or IsDisabledControlPressed(0, 200) or IsDisabledControlPressed(0, 202)) do
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 202, true)

            if (IsPauseMenuActive()) then SetFrontendActive(false) end

            Wait(0)
        end
    end)
end

-- Shows a panel with these items, or changes what the panel of these items shows. Each items table is its own panel,
-- so several can be up at once and stack, from this resource and others
---@param items KeybindItem[]
---@param options? KeybindOptions
function Functions.keybinds.show(items, options)
    if (not panels[items]) then
        panelCount += 1
        panels[items] = {id = ("%s:%s"):format(ResName, panelCount)}
    end

    local modifiers = false

    for i = 1, #items do
        if (items[i].activate or items[i].disable) then modifiers = true end
    end

    panels[items].options = options
    panels[items].modifiers = modifiers

    send(items)
end

---@param item KeybindItem
---@param key string
local function processKey(item, key)
    local control = getControl(key)
    if (not control) then return end

    local isCancel = cancelControls[control]

    DisableControlAction(0, control, true)

    if (isCancel) then
        for i = 1, #pauseControls do
            DisableControlAction(0, pauseControls[i], true)
        end
    end

    -- An item without func only shows a key the resource reads itself, kept from the game all the same
    if (not item.func) then return end

    local pressed = item.hold and IsDisabledControlPressed(0, control) or IsDisabledControlJustPressed(0, control)
    if (not pressed) then return end

    if (isCancel) then holdPauseMenu() end

    item.func(key, control)
end

---@param item KeybindItem
---@param value? string | string[] @ The item's key or hiddenKey
local function processKeys(item, value)
    if (type(value) == "table") then
        for _, key in ipairs(value) do
            processKey(item, key)
        end
    elseif (value) then
        processKey(item, value)
    end
end

-- Reads the keys of the items and keeps the game from acting on them. Run it every frame the panel is up, so it makes
-- no tables or closures that the garbage collector would have to clear
---@param items KeybindItem[]
function Functions.keybinds.handle(items)
    for i = 1, #items do
        local item = items[i]
        local control = item.command and commandControls[item.command]
        if (control) then DisableControlAction(0, control, true) end

        if (isActive(item)) then
            processKeys(item, item.key)
            processKeys(item, item.hiddenKey)
        end
    end

    -- Activate and disable keys change which items show
    if (panels[items] and panels[items].modifiers) then send(items) end
end

-- Hides the panel of these items
---@param items KeybindItem[]
function Functions.keybinds.hide(items)
    local panel = panels[items]
    if (not panel) then return end

    panels[items] = nil

    exports[LibName]:removeKeybindPanel(panel.id)
end

-- Runs the item of a shown panel that uses the command, so the key does nothing while no panel offers it
---@param command string
local function press(command)
    for items in pairs(panels) do
        for i = 1, #items do
            local item = items[i]

            if (item.command == command and item.func and isActive(item)) then item.func() return end
        end
    end
end

-- A key players can rebind under Settings > Key Bindings > FiveM; an item takes it by naming the command
---@param command string
---@param description string
---@param key string @ The default key, a key mapping name such as "E"
function Functions.keybinds.addKeyMapping(command, description, key)
    RegisterCommand(command, function() press(command) end, false)
    RegisterKeyMapping(command, description, "keyboard", key)

    -- Kept out of the chat suggestions, as pressing the key is how it is used
    CreateThread(function()
        Wait(1000)

        TriggerEvent("chat:removeSuggestion", "/" .. command)
    end)
end

return Functions.keybinds