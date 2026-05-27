local awaitSystemStarting, override = ...

if (override == "none") then
    Functions.debug.internal("^2Notification system override set to 'none', using framework notifications^7")
    return
end

local systems = {
    {fileName = "ox_lib", variable = "OX"},
}

if (override ~= "auto") then
    for i = 1, #systems do
        if (systems[i].fileName == override) then
            local resState = awaitSystemStarting(override)

            if (resState ~= "started") then
                print("^1========== [WARNING] ==========^7")
                print(("^1> Notification override '%s' is set, but the resource is not started (state: %s)^7"):format(override, resState))
                print("^1> Please make sure the resource is installed and started in your server.cfg^7")
                print("^1> You can change this in dependency_override.lua^7")
            else
                NotificationSystem = systems[i].variable
                Functions.debug.internal("^2Using " .. override .. " as notification system (override)^7")
            end

            return
        end
    end

    local valid = {"none"}
    for i = 1, #systems do valid[#valid+1] = systems[i].fileName end
    print(("^1[zyke_lib] Invalid notification override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))
else
    for i = 1, #systems do
        local resState = awaitSystemStarting(systems[i].fileName)

        if (resState == "started") then
            NotificationSystem = systems[i].variable
            Functions.debug.internal("^2Using " .. systems[i].fileName .. " as notification system^7")

            break
        end
    end
end
