-- qb-inventory runs weapon items through a cancellable ItemUsed hook, so a blocked player's
-- weapon is refused before it is drawn; the client handles every other inventory
-- (interfaces/weaponBlock/client.lua)
if (Inventory ~= "DEFAULT") then return end

---@param payload {source: integer, item: {name: string, type: string}}
---@return boolean? allowed @ False cancels the use, nil leaves it alone
local function refuseWeaponUse(payload)
    if (payload.item.type ~= "weapon") then return nil end
    if (Player(payload.source).state["z:weaponsBlocked"] ~= true) then return nil end

    TriggerClientEvent("zyke_lib:WeaponUseRefused", payload.source)

    return false
end

-- AddHook is missing on older qb-inventory versions, and a missing export throws; the client
-- still puts the weapon away there
local function registerWeaponHook()
    if (GetResourceState("qb-inventory") ~= "started") then return end

    pcall(function()
        exports["qb-inventory"]:AddHook("ItemUsed", refuseWeaponUse)
    end)
end

registerWeaponHook()

-- qb-inventory drops its hooks when it restarts
---@param resourceName string
AddEventHandler("onResourceStart", function(resourceName)
    if (resourceName ~= "qb-inventory") then return end

    registerWeaponHook()
end)