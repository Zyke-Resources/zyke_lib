local awaitSystemStarting, override = ...

if (override == "none") then
    Functions.debug.internal("^2Gang system override set to 'none', using framework default^7")
    return
end

local systems = {
    {fileName = "zyke_gangs", variable = "zyke"}
}

if (override ~= "auto") then
    for i = 1, #systems do
        if (systems[i].fileName == override) then
            local resState = awaitSystemStarting(override)

            if (resState ~= "started") then
                print("^1========== [WARNING] ==========^7")
                print(("^1> Gang override '%s' is set, but the resource is not started (state: %s)^7"):format(override, resState))
                print("^1> Please make sure the resource is installed and started in your server.cfg^7")
                print("^1> You can change this in dependency_override.lua^7")
            else
                GangSystem = systems[i].variable
                Functions.debug.internal("^2Using " .. override .. " as gang system (override)^7")
            end

            return
        end
    end

    local valid = {}
    for i = 1, #systems do valid[#valid+1] = systems[i].fileName end
    print(("^1[zyke_lib] Invalid gang override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))
else
    for i = 1, #systems do
        local resState = awaitSystemStarting(systems[i].fileName)

        -- If it's started, we use it
        if (resState == "started") then
            GangSystem = systems[i].variable
            Functions.debug.internal("^2Using " .. systems[i].fileName .. " as gang system^7")

            break
        end
    end
end