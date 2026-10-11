local _, override = ...

if (override == "none") then
    Functions.debug.internal("^2Phone system override set to 'none', using framework phone numbers^7")

    return
end

-- Keep sd-phone first because its provide aliases report the phones it imitates as started
-- Item-based phones come before npwd, which servers often leave installed beside a newer phone
-- qb-phone has no entry since it reads the framework's charinfo.phone, which the methods fall back to
local systems = {
    "sd-phone",
    "lb-phone",
    "yseries",
    "okokPhone",
    "roadphone",
    "gksphone",
    "qs-smartphone-pro",
    "qs-smartphone",
    "high-phone",
    "17mov_Phone",
    "npwd",
}

-- Legacy qs-smartphone shares the resource name of the current one but reads numbers through qs-base
local qsBase = "qs-base"

local candidates = systems
if (override ~= "auto") then
    local isValid = false
    for i = 1, #systems do
        if (systems[i] == override) then isValid = true end
    end

    if (not isValid) then
        local valid = {"auto", "none"}
        for i = 1, #systems do valid[#valid+1] = systems[i] end

        print(("^1[zyke_lib] Invalid phone override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))

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

-- Resolve provide aliases to the real resource, so an alias never selects the adapter of the phone it imitates
---@param resourceName string
---@param excluded? string @ Resource whose stop event is running
---@param started? string
---@return string? providerName @ nil when the alias belongs to a resource that is not running
local function resolveProvidedSystem(resourceName, excluded, started)
    for i = 1, #systems do
        local candidate = systems[i]
        local state = candidate == started and "started" or GetResourceState(candidate)

        if (candidate ~= resourceName and (state == "started" or state == "starting" or state == "stopping")) then
            local count = GetNumResourceMetadata(candidate, "provide")
            for j = 0, count - 1 do
                if (GetResourceMetadata(candidate, "provide", j) == resourceName) then
                    if (candidate == excluded or state ~= "started") then return nil end

                    return candidate
                end
            end
        end
    end

    return resourceName
end

-- Phones are never awaited, since servers often keep unused ones installed and that would block the loader
-- Instead the selection follows resource starts & stops, which also keeps the list priority regardless of start order
---@param excluded? string @ Resource whose stop event is running, since it can still report as started
---@param started? string
local function selectSystem(excluded, started)
    local selected = nil

    for i = 1, #candidates do
        local resourceName = candidates[i]
        if (resourceName ~= excluded and isStarted(resourceName, started)) then
            selected = resolveProvidedSystem(resourceName, excluded, started)
            if (selected) then break end
        end
    end

    if (selected == "qs-smartphone" and qsBase ~= excluded and isStarted(qsBase, started)) then
        selected = "qs-smartphone-legacy"
    end

    if (selected == PhoneSystem) then return end

    PhoneSystem = selected

    Functions.debug.internal("^2Using " .. tostring(selected) .. " as phone system^7")
end

local watched = {[qsBase] = true}
for i = 1, #systems do watched[systems[i]] = true end

selectSystem()

---@param resourceName string
local function onSystemStart(resourceName)
    if (not watched[resourceName]) then return end

    selectSystem(nil, resourceName)
end

---@param resourceName string
local function onSystemStop(resourceName)
    if (not watched[resourceName]) then return end

    selectSystem(resourceName)
end

if (IsDuplicityVersion()) then
    AddEventHandler("onResourceStart", onSystemStart)
    AddEventHandler("onResourceStop", onSystemStop)
else
    AddEventHandler("onClientResourceStart", onSystemStart)
    AddEventHandler("onClientResourceStop", onSystemStop)
end