-- FiveM can keep a stopped resource's change handler for a key, and the next local set of that key throws
-- "bad function call" from inside :set, which would end the loop that made the call
---@param bag table @ State bag, such as LocalPlayer.state
---@param key string
---@param value any
---@param replicated boolean
---@return boolean success
local function trySetState(bag, key, value, replicated)
    return (pcall(bag.set, bag, key, value, replicated))
end

-- Set the vehicle you are currently in
CreateThread(function()
    local prevVeh = nil
    local prevNetId = nil
    local prevEntering = nil
    local nextReconcileAt = 0

    while (true) do
        local sleep = 250
        local ply = PlayerPedId()
        local veh = GetVehiclePedIsIn(ply, false)
        local entering = GetVehiclePedIsEntering(ply)
        local currentVehicle = veh ~= 0 and veh or nil
        local netId = Functions.network.getNetId(veh)
        -- Rapid entity replacement keeps the handle but changes the network id
        local changed = prevVeh ~= veh or prevNetId ~= netId

        -- Every LocalPlayer.state read builds a proxy and decodes the bag, so external drift is reconciled less often
        if (not changed and GetGameTimer() >= nextReconcileAt) then
            local state = LocalPlayer.state
            nextReconcileAt = GetGameTimer() + 2000
            changed = state.currentVehicle ~= currentVehicle or state.currentVehicleNetId ~= netId
        end

        -- A failed set keeps the previous values, so the next tick tries again
        if (changed) then
            local state = LocalPlayer.state
            if (trySetState(state, "currentVehicle", currentVehicle, false) and trySetState(state, "currentVehicleNetId", netId, true)) then
                prevVeh = veh
                prevNetId = netId
            end
        end

        -- Maybe doesn't really fit in here, but we'll run it for now
        if (prevEntering ~= entering and trySetState(LocalPlayer.state, "enteringVehicle", entering ~= 0 and entering or nil, false)) then
            prevEntering = entering
        end

        Wait(sleep)
    end
end)

-- Fading of vehicles that are queued to be removed (functions/queueEntityRemoval/server.lua)
---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("removing", nil, function(bagName, _, value)
    local entity = GetEntityFromStateBagName(bagName)
    if (entity == 0 or not DoesEntityExist(entity)) then return end

    local isVeh = IsEntityAVehicle(entity)
    if (not isVeh) then return end

    SetEntityCollision(entity, false, true)
    for i = 255, 0, -1 do
        Wait(math.floor(255 / value))

        SetEntityAlpha(entity, i, false)
    end
end)

-- Verify your client has properly loaded into the game
CreateThread(function()
    trySetState(LocalPlayer.state, "z:hasLoaded", false, true) -- Needs resetting if script is restarted

    while (1) do
        local hasLoaded = NetworkIsPlayerActive(PlayerId())

        if (hasLoaded and trySetState(LocalPlayer.state, "z:hasLoaded", true, true)) then break end

        Wait(500)
    end
end)

-- I feel like an ape for doing this, but I can't find a cheaper way to reliably grab the server id from an entity on the server
CreateThread(function()
    while (LocalPlayer.state["z:hasLoaded"] ~= true) do Wait(500) end

    local prevEntityId = nil

    while (1) do
        local newEntityId = PlayerPedId()
        if (prevEntityId ~= newEntityId and trySetState(Entity(newEntityId).state, "z:serverId", GetPlayerServerId(PlayerId()), true)) then
            prevEntityId = newEntityId
        end

        Wait(1000)
    end
end)

-- Set the weapon you are currently holding, this avoids us similar loops in several resources
CreateThread(function()
    local prevWeapon = nil
    local unarmedHash = `WEAPON_UNARMED`

    while (true) do
        local _, weapon = GetCurrentPedWeapon(PlayerPedId(), true)

        if (prevWeapon ~= weapon and trySetState(LocalPlayer.state, "currentWeapon", weapon ~= unarmedHash and weapon or nil, false)) then
            prevWeapon = weapon
        end

        Wait(250)
    end
end)