local awaitSystemStarting, override = ...

if (override == "none") then return end

-- Exact overrides can use any resource name; this list only controls auto-detection order
-- illenium-appearance answers skinchanger's and qb-clothing's events too, so it comes first
local systems = {
    "onex-creation",
    "rcore_clothing",
    "illenium-appearance",
    "qb-clothing",
    "esx_skin",
}

if (override ~= "auto") then
    if (ResName ~= LibName and ResName ~= override) then awaitSystemStarting(override) end

    AppearanceSystem = override

    return
end

-- Clothes are only changed once a player plays, so detection never waits for an appearance resource that has not started
-- Precedence is running, starting, then installed to avoid choosing a dormant one over an active one
for _, wantedState in ipairs({"started", "starting"}) do
    for i = 1, #systems do
        if (GetResourceState(systems[i]) == wantedState) then
            AppearanceSystem = systems[i]

            return
        end
    end
end

for i = 1, #systems do
    local state = GetResourceState(systems[i])
    if (state ~= "missing" and state ~= "unknown") then
        AppearanceSystem = systems[i]

        return
    end
end
