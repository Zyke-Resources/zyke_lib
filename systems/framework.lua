local awaitSystemStarting, override = ...

local systems = {
    {fileName = "es_extended", variable = "ESX", fetching = function(fileName)
        -- Since FiveM is... FiveM... a resource is registered as started before it's actually started
        -- So we need to wrap this in a pcall because this will most likely fail and throw and error if your resource starting sequence is chaotic

        local success = false
        repeat
            success, ESX = pcall(function() return exports[fileName]:getSharedObject() end)
            Wait(50)
        until success
    end},
    {fileName = "qb-core", variable = "QB", fetching = function(fileName)
        local success = false

        repeat
            success, QB = pcall(function() return exports[fileName]:GetCoreObject() end)
            Wait(50)
        until success
    end}
}

if (override ~= "auto") then
    for i = 1, #systems do
        if (systems[i].fileName == override) then
            local resState = awaitSystemStarting(override)

            if (resState ~= "started") then
                print("^1========== [WARNING] ==========^7")
                print(("^1> Framework override '%s' is set, but the resource is not started (state: %s)^7"):format(override, resState))
                print("^1> Please make sure the resource is installed and started in your server.cfg^7")
                print("^1> You can change this in dependency_override.lua^7")
            else
                systems[i].fetching(override)
                Framework = systems[i].variable
                Functions.debug.internal("^2Using " .. override .. " as framework (override)^7")
            end

            return
        end
    end

    local valid = {}
    for i = 1, #systems do valid[#valid+1] = systems[i].fileName end
    print(("^1[zyke_lib] Invalid framework override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))
else
    for i = 1, #systems do
        local resState = awaitSystemStarting(systems[i].fileName)

        -- If it's started, we use it
        if (resState == "started") then
            systems[i].fetching(systems[i].fileName)
            Framework = systems[i].variable
            Functions.debug.internal("^2Using " .. systems[i].fileName .. " as framework^7")

            break
        end
    end
end