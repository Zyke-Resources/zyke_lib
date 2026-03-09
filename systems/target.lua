local awaitSystemStarting, override = ...

local systems = {
    {fileName = "ox_target", variable = "OX"},
    {fileName = "qb-target", variable = "QB"},
}

if (override ~= "auto") then
    for i = 1, #systems do
        if (systems[i].fileName == override) then
            local resState = awaitSystemStarting(override)

            if (resState ~= "started") then
                print("^1========== [WARNING] ==========^7")
                print(("^1> Target override '%s' is set, but the resource is not started (state: %s)^7"):format(override, resState))
                print("^1> Please make sure the resource is installed and started in your server.cfg^7")
                print("^1> You can change this in dependency_override.lua^7")
            else
                Target = systems[i].variable
                Functions.debug.internal("^2Using " .. override .. " as target system (override)^7")
            end

            return
        end
    end

    local valid = {}
    for i = 1, #systems do valid[#valid+1] = systems[i].fileName end
    print(("^1[zyke_lib] Invalid target override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))
else
    for i = 1, #systems do
        local resState = awaitSystemStarting(systems[i].fileName)

        -- If it's started, we use it
        if (resState == "started") then
            Target = systems[i].variable
            Functions.debug.internal("^2Using " .. systems[i].fileName .. " as target system^7")

            break
        end
    end
end