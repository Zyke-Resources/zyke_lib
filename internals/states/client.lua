-- Set the vehicle you are currently in
CreateThread(function()
    local prevVeh = nil
    local prevEntering = nil

    while (true) do
        local sleep = 250
        local ply = PlayerPedId()
        local veh = GetVehiclePedIsIn(ply, false)
        local entering = GetVehiclePedIsEntering(ply)

        if (prevVeh ~= veh) then
            LocalPlayer.state:set("currentVehicle", veh ~= 0 and veh or nil, false)

            local netId = veh and veh ~= 0 and VehToNet(veh) or nil
            LocalPlayer.state:set("currentVehicleNetId", netId, true)

            prevVeh = veh
        end

        -- Maybe doesn't really fit in here, but we'll run it for now
        if (prevEntering ~= entering) then
            LocalPlayer.state:set("enteringVehicle", entering ~= 0 and entering or nil, false)
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
    LocalPlayer.state:set("z:hasLoaded", false, true) -- Needs resetting if script is restarted

    while (1) do
        local hasLoaded = NetworkIsPlayerActive(PlayerId())

        if (hasLoaded) then
            LocalPlayer.state:set("z:hasLoaded", true, true)

            break
        end

        Wait(500)
    end
end)

-- I feel like an ape for doing this, but I can't find a cheaper way to reliably grab the server id from an entity on the server
CreateThread(function()
    while (LocalPlayer.state["z:hasLoaded"] ~= true) do Wait(500) end

    local prevEntityId = nil

    while (1) do
        local newEntityId = PlayerPedId()
        if (prevEntityId ~= newEntityId) then
            prevEntityId = newEntityId

            Entity(newEntityId).state:set("z:serverId", GetPlayerServerId(PlayerId()), true)
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

        if (prevWeapon ~= weapon) then
            local hasWeapon = weapon ~= unarmedHash
            LocalPlayer.state:set("currentWeapon", hasWeapon and weapon or nil, false)

            prevWeapon = weapon
        end

        Wait(250)
    end
end)