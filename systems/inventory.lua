local awaitSystemStarting, override = ...

local systems = {
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
    for i = 1, #systems do
        local resState = awaitSystemStarting(systems[i].fileName)

        -- If it's started, we use it
        if (resState == "started") then
            Inventory = systems[i].variable
            Functions.debug.internal("^2Using " .. systems[i].fileName .. " as inventory system^7")

            break
        end
    end
end

local items = {}
local success = false

-- See systems/framework.lua for more info on why we're doing this
repeat
    success, items = pcall(function()
        if (Inventory == "OX") then
            items = exports["ox_inventory"]:Items()
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
                    items = Z.callback.await("zyke_lib:FetchItems")
                end
            elseif (Framework == "QB") then
                items = QB.Shared.Items
            end
        end

        return items
    end)

    Wait(50)
until success

if (not Inventory) then
    Inventory = "DEFAULT"
end

Items = items