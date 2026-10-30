local awaitSystemStarting, override, awaitAnySystemStarting = ...

if (override == "none") then
    Functions.debug.internal("^2Mileage system override set to 'none', skipping detection^7")
    return
end

local systems = {
    {fileName = "jg-vehiclemileage", variable = "jg-vehiclemileage"}
}

if (override ~= "auto") then
    for i = 1, #systems do
        if (systems[i].fileName == override) then
            local resState = awaitSystemStarting(override)

            if (resState ~= "started") then
                print("^1========== [WARNING] ==========^7")
                print(("^1> Mileage override '%s' is set, but the resource is not started (state: %s)^7"):format(override, resState))
                print("^1> Please make sure the resource is installed and started in your server.cfg^7")
                print("^1> You can change this in dependency_override.lua^7")
            else
                MileageSystem = systems[i].variable
                Functions.debug.internal("^2Using " .. override .. " as mileage system (override)^7")
            end

            return
        end
    end

    local valid = {}
    for i = 1, #systems do valid[#valid+1] = systems[i].fileName end
    print(("^1[zyke_lib] Invalid mileage override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))
else
    local system = awaitAnySystemStarting(systems)
    if (system) then
        MileageSystem = system.variable
        Functions.debug.internal("^2Using " .. system.fileName .. " as mileage system^7")
    end
end