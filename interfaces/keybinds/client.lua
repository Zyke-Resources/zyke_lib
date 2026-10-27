-- Draws the key panels of every resource from Z.keybinds, in the order they were first shown so they stack instead of
-- overlapping. The pause menu covers the game, so the panels go with it

---@type {id: string, resource: string, data: KeybindPanelData}[]
local panels = {}
local hidden = false
local watching = false
local pauseCheckMs = 100

local function sync()
    local list = {}

    if (not hidden) then
        for i = 1, #panels do
            list[i] = {id = panels[i].id, data = panels[i].data}
        end
    end

    SendNUIMessage({event = "SetKeybindPanels", data = {panels = list}})
end

local function watchPauseMenu()
    if (watching) then return end

    watching = true

    CreateThread(function()
        while (#panels > 0) do
            local paused = IsPauseMenuActive()

            if (paused ~= hidden) then
                hidden = paused

                sync()
            end

            Wait(pauseCheckMs)
        end

        watching = false
    end)
end

---@param id string
---@return integer? index
local function getIndex(id)
    for i = 1, #panels do
        if (panels[i].id == id) then return i end
    end
end

---@param id string @ The calling resource's name and a number, from Z.keybinds.show
---@param data KeybindPanelData
exports("setKeybindPanel", function(id, data)
    local index = getIndex(id)

    if (index) then
        panels[index].data = data
    else
        panels[#panels + 1] = {id = id, resource = GetInvokingResource() or ResName, data = data}
    end

    sync()
    watchPauseMenu()
end)

---@param id string
exports("removeKeybindPanel", function(id)
    local index = getIndex(id)
    if (not index) then return end

    table.remove(panels, index)

    sync()
end)

-- The page asks once it has loaded, so panels shown before then are sent again
---@param _ table
---@param cb function
RegisterNUICallback("Eventhandler:Keybinds", function(_, cb)
    cb("ok")

    sync()
end)

---@param resourceName string
AddEventHandler("onClientResourceStop", function(resourceName)
    local removed = false

    for i = #panels, 1, -1 do
        if (panels[i].resource == resourceName) then
            table.remove(panels, i)
            removed = true
        end
    end

    if (removed) then sync() end
end)