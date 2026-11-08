local _, override = ...

if (override == "none") then
    Functions.debug.internal("^2Dispatch system override set to 'none', alerts use the notification & blip fallback^7")

    return
end

-- cd_dispatch3d comes first since it also answers the alerts of the dispatches it replaces
-- lb-tablet comes last, servers often run it for its other apps beside another dispatch
local systems = {
    "cd_dispatch3d",
    "ps-dispatch",
    "cd_dispatch",
    "qs-dispatch",
    "rcore_dispatch",
    "core_dispatch",
    "tk_dispatch",
    "codem-dispatchv2",
    "lb-tablet",
}

local candidates = systems
if (override ~= "auto") then
    local isValid = false
    for i = 1, #systems do
        if (systems[i] == override) then isValid = true end
    end

    if (not isValid) then
        local valid = {"auto", "none"}
        for i = 1, #systems do valid[#valid+1] = systems[i] end

        print(("^1[zyke_lib] Invalid dispatch override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))

        return
    end

    candidates = {override}
end

---@param resourceName string
---@param started? string @ Resource whose start event is running, since its state may not read as started yet
---@return boolean isStarted
local function isStarted(resourceName, started)
    return resourceName == started or GetResourceState(resourceName) == "started"
end

---@param resourceName string
---@param name string
---@return boolean provides @ The resource offers the name through `provide` in its manifest
local function providesName(resourceName, name)
    for i = 0, GetNumResourceMetadata(resourceName, "provide") - 1 do
        if (GetResourceMetadata(resourceName, "provide", i) == name) then return true end
    end

    return false
end

-- Another resource can answer to a dispatch's name through `provide`, such as sd-phone offering lb-tablet's exports
-- The adapter is still picked by that name, but the provider is what runs, gets logged and is watched for stops
---@param resourceName string
---@param excluded? string @ Resource whose stop event is running
---@param started? string
---@return string? providerName @ nil when neither the resource nor a provider of it runs
local function getProvider(resourceName, excluded, started)
    local provider = nil

    for i = 0, GetNumResources() - 1 do
        local candidate = GetResourceByFindIndex(i)

        if (candidate and candidate ~= excluded and isStarted(candidate, started)) then
            if (candidate == resourceName) then return candidate end
            if (not provider and providesName(candidate, resourceName)) then provider = candidate end
        end
    end

    return provider
end

local selectedProvider = nil

-- Dispatches are never awaited, since servers often keep unused ones installed and that would block the loader
-- Instead the selection follows resource starts & stops, which also keeps the list priority regardless of start order
---@param excluded? string @ Resource whose stop event is running, since it can still report as started
---@param started? string
local function selectSystem(excluded, started)
    local selected, provider = nil, nil

    for i = 1, #candidates do
        local resourceName = candidates[i]

        -- Asks the providers directly, since a name offered by a resource that is starting may not read as started yet
        if (resourceName ~= excluded) then
            provider = getProvider(resourceName, excluded, started)

            if (provider) then
                selected = resourceName
                break
            end
        end
    end

    if (selected == DispatchSystem and provider == selectedProvider) then return end

    DispatchSystem, selectedProvider = selected, provider

    local label = provider and provider ~= selected and ("%s, provided by %s"):format(selected, provider) or tostring(selected)
    Functions.debug.internal("^2Using " .. label .. " as dispatch system^7")
end

local watched = {}
for i = 1, #systems do watched[systems[i]] = true end

---@param resourceName string
---@return boolean concerns @ The resource is a dispatch, offers a dispatch's name, or provides the selected one
local function concernsSelection(resourceName)
    if (watched[resourceName] or resourceName == selectedProvider) then return true end

    for i = 1, #candidates do
        if (providesName(resourceName, candidates[i])) then return true end
    end

    return false
end

selectSystem()

---@param resourceName string
local function onSystemStart(resourceName)
    if (not concernsSelection(resourceName)) then return end

    selectSystem(nil, resourceName)
end

---@param resourceName string
local function onSystemStop(resourceName)
    if (not concernsSelection(resourceName)) then return end

    selectSystem(resourceName)
end

if (IsDuplicityVersion()) then
    AddEventHandler("onResourceStart", onSystemStart)
    AddEventHandler("onResourceStop", onSystemStop)
else
    AddEventHandler("onClientResourceStart", onSystemStart)
    AddEventHandler("onClientResourceStop", onSystemStop)
end