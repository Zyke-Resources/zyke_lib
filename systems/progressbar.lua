local awaitSystemStarting, override = ...

ProgressBarSystem = "ZYKE"

if (override == "auto" or override == "zyke_lib") then
    Functions.debug.internal("^2Using zyke_lib as progressbar system^7")
    return
end

if (override == "ox_lib" or override == "lation_ui") then
    local resState = awaitSystemStarting(override)

    if (resState ~= "started") then
        print("^1========== [WARNING] ==========^7")
        print(("^1> Progressbar override '%s' is set, but the resource is not started (state: %s)^7"):format(override, resState))
        print("^1> Please make sure the resource is installed and started in your server.cfg^7")
        print("^1> You can change this in dependency_override.lua^7")
    else
        ProgressBarSystem = override == "lation_ui" and "LATION" or "OX"
        Functions.debug.internal("^2Using " .. override .. " as progressbar system (override)^7")
    end

    return
end

print(("^1[zyke_lib] Invalid progressbar override '%s'. Valid options: auto, zyke_lib, ox_lib, lation_ui^7"):format(override))
