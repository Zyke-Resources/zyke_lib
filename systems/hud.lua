local awaitSystemStarting, override = ...

if (override == "none") then
    Functions.debug.internal("^2HUD system override set to 'none', skipping detection^7")
    return
end

local systems = {
    "jg-hud",
    "esx_hud",
    "wais-hudv6",
    "0r-hud-v3",
    "17mov_Hud",
    "izzy-hudv6",
    "vms_hud",
    "rhud",
    "envi-hud",
    "cx-hud",
    "tgiann-lumihud",
    "izzy-hudv7",
    "hex_4_hud",
    "minimal-hud",
    "izzy-hudv5",
    "tgg-hud",
    "sync-hud",
    "hex_hud_prem",
    "bablo-hud"
}

if (override ~= "auto") then
    for i = 1, #systems do
        if (systems[i] == override) then
            local resState = awaitSystemStarting(override)

            if (resState ~= "started") then
                print("^1========== [WARNING] ==========^7")
                print(("^1> HUD override '%s' is set, but the resource is not started (state: %s)^7"):format(override, resState))
                print("^1> Please make sure the resource is installed and started in your server.cfg^7")
                print("^1> You can change this in dependency_override.lua^7")
            else
                HudSystem = systems[i]
                Functions.debug.internal("^2Using " .. override .. " as HUD system (override)^7")
            end

            return
        end
    end

    local valid = {"auto", "none"}
    for i = 1, #systems do valid[#valid+1] = systems[i] end
    print(("^1[zyke_lib] Invalid HUD override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))
else
    local priorities = {}
    for i = 1, #systems do priorities[systems[i]] = i end

    ---@param resourceName string
    local function setSystem(resourceName)
        HudSystem = resourceName
        Functions.debug.internal("^2Using " .. resourceName .. " as HUD system^7")
    end

    ---@param excluded? string @ Resource to skip, since a stopping resource can still report as started
    local function selectStartedSystem(excluded)
        for i = 1, #systems do
            if (systems[i] ~= excluded and GetResourceState(systems[i]) == "started") then
                setSystem(systems[i])

                return
            end
        end
    end

    -- HUDs are never awaited, since servers often keep unused ones installed and that would block the loader
    -- Instead we follow resource starts & stops, which also keeps the list priority regardless of start order
    selectStartedSystem()

    ---@param resourceName string
    local function onSystemStart(resourceName)
        local priority = priorities[resourceName]
        if (not priority) then return end
        if (HudSystem and priorities[HudSystem] <= priority) then return end

        setSystem(resourceName)
    end

    ---@param resourceName string
    local function onSystemStop(resourceName)
        if (HudSystem ~= resourceName) then return end

        HudSystem = nil
        selectStartedSystem(resourceName)
    end

    if (IsDuplicityVersion()) then
        AddEventHandler("onResourceStart", onSystemStart)
        AddEventHandler("onResourceStop", onSystemStop)
    else
        AddEventHandler("onClientResourceStart", onSystemStart)
        AddEventHandler("onClientResourceStop", onSystemStop)
    end
end