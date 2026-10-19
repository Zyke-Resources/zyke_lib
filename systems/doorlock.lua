local awaitSystemStarting, override = ...

if (override == "none") then return end

-- Exact overrides can use any resource name; this list only controls auto-detection order
-- qb-doorlock is detected so Z.doorlock can tell its doors come from a config file instead
local systems = {
    "ox_doorlock",
    "rcore_doorlock",
    "qb-doorlock",
}

if (override ~= "auto") then
    if (ResName ~= LibName and ResName ~= override) then awaitSystemStarting(override) end

    DoorlockSystem = override

    return
end

-- Doors are only added once the server runs, so detection never waits for a door lock that has not started
-- Precedence is running, starting, then installed to avoid choosing a dormant door lock over an active one
for _, wantedState in ipairs({"started", "starting"}) do
    for i = 1, #systems do
        if (GetResourceState(systems[i]) == wantedState) then
            DoorlockSystem = systems[i]

            return
        end
    end
end

for i = 1, #systems do
    local state = GetResourceState(systems[i])
    if (state ~= "missing" and state ~= "unknown") then
        DoorlockSystem = systems[i]

        return
    end
end