local awaitSystemStarting, override = ...

if (override == "none") then return end

-- Exact overrides can use any resource name; this list only controls auto-detection order
-- Keep zyke_vehiclekeys first because its provide aliases can report compatibility resource names as started
local systems = {
    "zyke_vehiclekeys",
    "qb-vehiclekeys",
    "qbx_vehiclekeys",
    "qs-vehiclekeys",
    "wasabi_carlock",
    "Renewed-Vehiclekeys",
}

-- Resolve provide aliases to a supported real resource so the alias cannot select the wrong adapter contract
---@param resourceName string
---@return string providerName
local function resolveProvidedSystem(resourceName)
    for i = 1, #systems do
        local candidate = systems[i]
        if (candidate ~= resourceName) then
            local state = GetResourceState(candidate)
            if (state == "started" or state == "starting") then
                local count = GetNumResourceMetadata(candidate, "provide")
                for j = 0, count - 1 do
                    if (GetResourceMetadata(candidate, "provide", j) == resourceName) then return candidate end
                end
            end
        end
    end

    return resourceName
end

if (override ~= "auto") then
    if (ResName ~= LibName and ResName ~= override) then awaitSystemStarting(override) end

    VehicleKeysSystem = resolveProvidedSystem(override)

    return
end

-- Detection precedence is running, starting, then installed to avoid choosing a dormant provider over an active one
for i = 1, #systems do
    local state = GetResourceState(systems[i])
    if (state == "started") then
        VehicleKeysSystem = resolveProvidedSystem(systems[i])

        return
    end
end

for i = 1, #systems do
    local state = GetResourceState(systems[i])
    if (state == "starting") then
        VehicleKeysSystem = resolveProvidedSystem(systems[i])

        return
    end
end

-- Do not await auto-detected systems because zyke_vehiclekeys imports zyke_lib while starting
for i = 1, #systems do
    local state = GetResourceState(systems[i])
    if (state ~= "missing" and state ~= "unknown") then
        VehicleKeysSystem = resolveProvidedSystem(systems[i])

        return
    end
end