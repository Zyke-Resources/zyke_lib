-- Catching events on the client to translate them

-- Framework updates
-- For QB there is no event dispatched, has to catch the SetPlayerData event
if (Inventory == "OX") then
    AddEventHandler("ox_inventory:updateInventory", function(changes)
        TriggerEvent("zyke_lib:InventoryUpdated", changes)
        TriggerServerEvent("zyke_lib:InventoryUpdated", changes)
    end)
elseif (Inventory == "ONE") then
    RegisterNetEvent("one_inventory:onInventoryUpdate", function(payload)
        TriggerEvent("zyke_lib:InventoryUpdated", payload)
        TriggerServerEvent("zyke_lib:InventoryUpdated", payload)
    end)
elseif (Inventory == "TGIANN") then
    RegisterNetEvent("tgiann-inventory:updateInventory", function()
        Wait(250) -- There is a delay for the items to actually update and exist, so we wait a bit before triggering the event

        TriggerEvent("zyke_lib:InventoryUpdated")
        TriggerServerEvent("zyke_lib:InventoryUpdated")
    end)
elseif (Inventory == "CODEM") then
    local events = {
        "codem-inventory:removeitemtoclientInventory",
        "codem-inventory:client:additem",
    }

    for i = 1, #events do
        RegisterNetEvent(events[i], function()
            Wait(250) -- There is a delay for the items to actually update and exist, so we wait a bit before triggering the event

            TriggerEvent("zyke_lib:InventoryUpdated")
            TriggerServerEvent("zyke_lib:InventoryUpdated")
        end)
    end
else
    if (Framework == "QB") then
        -- Create a slight delay, because all player updates triggers this event (hunger, thirst, stress, inventory etc)
        -- For example, updating hunger, water & stress at the same time will trigger 3 updates, and probably a fourth if you ate
        local lastUpdate = GetGameTimer()
        local awaitingSync = false

        RegisterNetEvent("QBCore:Player:SetPlayerData", function()
            if (awaitingSync == true) then return end

            awaitingSync = true

            lastUpdate = GetGameTimer()
            while (GetGameTimer() - lastUpdate < 200) do Wait(25) end

            awaitingSync = false

            TriggerEvent("zyke_lib:InventoryUpdated")
            TriggerServerEvent("zyke_lib:InventoryUpdated")
        end)
    elseif (Framework == "ESX") then
        RegisterNetEvent("esx:addInventoryItem", function()
            TriggerEvent("zyke_lib:InventoryUpdated")
            TriggerServerEvent("zyke_lib:InventoryUpdated")
        end)

        RegisterNetEvent("esx:removeInventoryItem", function()
            TriggerEvent("zyke_lib:InventoryUpdated")
            TriggerServerEvent("zyke_lib:InventoryUpdated")
        end)

        RegisterNetEvent("esx:setInventoryItem", function()
            TriggerEvent("zyke_lib:InventoryUpdated")
            TriggerServerEvent("zyke_lib:InventoryUpdated")
        end)
    end
end

-- Character Selection
if (Framework == "QB") then
    RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
        Wait(1)

        TriggerEvent("zyke_lib:OnCharacterSelect")
    end)
elseif (Framework == "ESX") then -- Not tested (Not in use for any active releases yet)
    RegisterNetEvent("esx:playerLoaded", function()
        Wait(1)

        TriggerEvent("zyke_lib:OnCharacterSelect")
    end)
end