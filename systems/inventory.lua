local awaitSystemStarting, override, awaitAnySystemStarting = ...

-- one_inventory provides ox_inventory, so it has to be listed first or the alias would select ox_inventory
local systems = {
    {fileName = "one_inventory", variable = "ONE"},
    {fileName = "qs-inventory", variable = "QS"},
    {fileName = "ox_inventory", variable = "OX"},
    {fileName = "tgiann-inventory", variable = "TGIANN"},
    {fileName = "codem-inventory", variable = "CODEM"},
    {fileName = "core_inventory", variable = "C8RE"}, -- QB Only
    {fileName = "DEFAULT_INVENTORY", variable = "DEFAULT"},
}

if (override ~= "auto") then
    for i = 1, #systems do
        if (systems[i].fileName == override) then
            local resState = awaitSystemStarting(override)

            if (resState ~= "started") then
                print("^1========== [WARNING] ==========^7")
                print(("^1> Inventory override '%s' is set, but the resource is not started (state: %s)^7"):format(override, resState))
                print("^1> Please make sure the resource is installed and started in your server.cfg^7")
                print("^1> You can change this in dependency_override.lua^7")
            else
                Inventory = systems[i].variable
                Functions.debug.internal("^2Using " .. override .. " as inventory system (override)^7")
            end

            break
        end
    end

    if (not Inventory) then
        local valid = {}
        for i = 1, #systems do valid[#valid+1] = systems[i].fileName end
        print(("^1[zyke_lib] Invalid inventory override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))
    end
else
    local system = awaitAnySystemStarting(systems)
    if (system) then
        Inventory = system.variable
        Functions.debug.internal("^2Using " .. system.fileName .. " as inventory system^7")
    end
end

---@return table? items
local function fetchItems()
    local items = {}

    if (Inventory == "OX") then
        items = exports["ox_inventory"]:Items()
    elseif (Inventory == "ONE") then
        items = exports["one_inventory"]:GetAllItemDefinitions()
    elseif (Inventory == "TGIANN") then
        items = exports["tgiann-inventory"]:Items()

        -- We're forced to iterate all items and translate them because of a new stupid design choice breaking compatibility
        for _, itemData in pairs(items) do
            if (type(itemData.label) == "table") then
                itemData.label = itemData.label["en"]
            end

            if (type(itemData.description) == "table") then
                itemData.description = itemData.description["en"]
            end
        end
    elseif (Inventory == "CODEM") then
        items = exports["codem-inventory"]:GetItemList()
    elseif (Inventory == "QS") then
        items = exports['qs-inventory']:GetItemList()
    else
        -- ESX items only exist on the server side for some reason
        if (Framework == "ESX") then
            if (Context == "server") then
                Z.callback.register("zyke_lib:FetchItems", function()
                    return ESX.Items
                end)
            else
                items = Z.callback.request("zyke_lib:FetchItems")
            end
        elseif (Framework == "QB") then
            items = QB.Shared.Items
        end
    end

    return items
end

-- See systems/framework.lua for more info on why we're doing this
---@param resName? string @ Inventory resource, retrying stops once it is no longer started
---@return boolean success, table? items
local function awaitItems(resName)
    local success, items

    repeat
        success, items = pcall(fetchItems)

        Wait(50)
    until (success or (resName and GetResourceState(resName) ~= "started"))

    return success, items
end

-- A client re-downloads a restarted inventory and can start it after this resource, so its items are read again on every start
---@param resName string
local function onInventoryStart(resName)
    if (override ~= "auto" and override ~= resName) then return end

    for i = 1, #systems do
        local system = systems[i]

        if (system.fileName == resName) then
            if (Inventory and Inventory ~= "DEFAULT" and Inventory ~= system.variable) then return end

            Inventory = system.variable

            local success, items = awaitItems(resName)
            if (success) then Items = items end

            return
        end
    end
end

AddEventHandler(Context == "server" and "onResourceStart" or "onClientResourceStart", onInventoryStart)

local selectedInventory = Inventory
local _, items = awaitItems()

-- An inventory start handled while awaiting has already read its items
if (Inventory == selectedInventory) then
    Inventory = Inventory or "DEFAULT"
    Items = items
end

AddEventHandler("one_inventory:onDefinitionsUpdated", function()
    if (Inventory ~= "ONE") then return end

    Items = exports["one_inventory"]:GetAllItemDefinitions()
end)