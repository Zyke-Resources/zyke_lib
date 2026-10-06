-- Resources that fill the player's weapon hand block weapons through here; the block is kept
-- per resource, so one resource lifting its own never unblocks another's
---@type table<string, true> @ Resource name -> blocking
local blockers = {}
local unarmedHash = `WEAPON_UNARMED`
-- Only a canUseWeapons block placed here is lifted again, another script's stays untouched
local oxBlocked = false
local replicatedBlocked = false

---@return boolean armed
local function isArmed()
    local _, weapon = GetCurrentPedWeapon(PlayerPedId(), true)

    return weapon ~= unarmedHash
end

-- ox_inventory refuses weapon items and holsters the drawn one while canUseWeapons is false;
-- qb-inventory reads the replicated bag in its ItemUsed hook (internals/weaponBlock/server.lua);
-- inventories without a gate get the drawn weapon put away
local function applyWeaponBlock()
    local blocked = next(blockers) ~= nil

    if (blocked ~= replicatedBlocked) then
        replicatedBlocked = blocked
        LocalPlayer.state:set("z:weaponsBlocked", blocked or nil, true)
    end

    if (not blocked) then
        if (not oxBlocked) then return end

        oxBlocked = false
        LocalPlayer.state:set("canUseWeapons", true, false)

        return
    end

    if (Inventory == "OX" and LocalPlayer.state.canUseWeapons ~= false) then
        oxBlocked = true
        LocalPlayer.state:set("canUseWeapons", false, false)
    elseif (isArmed()) then
        Functions.unequipWeapon()
    end
end

-- Blocks or frees weapons for the calling resource; a drawn weapon is put away, and the
-- zyke_lib:WeaponBlocked client event fires whenever a weapon is refused or put away
---@param blocked boolean
Functions.setWeaponsBlocked = function(blocked)
    blockers[GetInvokingResource() or ResName] = blocked == true or nil

    applyWeaponBlock()
end

-- Catches a weapon that got past the block, such as one from an inventory without a gate
-- or after ox_inventory reset canUseWeapons on its own restart
---@param bagName string @ player:<serverId>
---@param key string
---@param value? integer @ Weapon hash, nil while unarmed
---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("currentWeapon", nil, function(bagName, key, value)
    if (value == nil or next(blockers) == nil) then return end
    if (GetPlayerFromStateBagName(bagName) ~= PlayerId()) then return end

    -- Bags can't be written from inside a change handler
    SetTimeout(0, function()
        if (next(blockers) == nil) then return end

        applyWeaponBlock()
        TriggerEvent("zyke_lib:WeaponBlocked")
    end)
end)

-- The server refused a weapon item; resources only handle the local event
RegisterNetEvent("zyke_lib:WeaponUseRefused", function()
    TriggerEvent("zyke_lib:WeaponBlocked")
end)

---@param resourceName string @ Stopping resource name
AddEventHandler("onClientResourceStop", function(resourceName)
    if (resourceName == ResName) then
        blockers = {}
    elseif (blockers[resourceName]) then
        blockers[resourceName] = nil
    else
        return
    end

    applyWeaponBlock()
end)