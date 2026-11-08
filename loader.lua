Functions.debug.internal("Initializing loader...")

-- Loading our basic dependencies to redirect dependency calls within the library / bridge

-- Load dependency overrides
local dependencyOverrides = {}
do
    local overrideChunk = LoadResourceFile(LibName, "dependency_override.lua")
    if (overrideChunk) then
        local func, err = load(overrideChunk, ("@@%s/dependency_override.lua"):format(LibName))
        if (func and not err) then
            local ok, result = pcall(func)
            if (ok and type(result) == "table") then
                dependencyOverrides = result
            end
        end
    end
end

local preloadedLoaderFiles = {}

---@param fileName string
---@param context "shared" | "server" | "client"
---@param resourceName string @ Resource that owns the file
---@return string key
local function getLoaderFileKey(fileName, context, resourceName)
    return ("%s:%s:%s"):format(resourceName, context, fileName)
end

---@param fileName string
---@param resourceName string @ Resource that owns the file
local function loadLoaderFile(fileName, resourceName)
    Functions.debug.internal("Attempting to load", resourceName, fileName)

    local chunk = LoadResourceFile(resourceName, fileName)
    if (not chunk) then
        error(("Failed to load %s (%s)"):format(resourceName, fileName))
    end

    Functions.debug.internal("Loaded chunk! Attempting to execute function...")

    local func, err = load(chunk, ("@@%s/%s"):format(resourceName, fileName))
    if (not func or err) then
        error(err)
    end

    func()

    Functions.debug.internal("Function executed!")
end

---@param fileName string
---@param context "shared" | "server" | "client"
local function preloadLoaderFile(fileName, context)
    if (context ~= "shared" and context ~= Context) then return end

    loadLoaderFile(fileName, ResName)
    preloadedLoaderFiles[getLoaderFileKey(fileName, context, ResName)] = true
end

if (ResName == LibName) then
    -- Central cache exports must exist even while dependency detection is waiting
    preloadLoaderFile("internals/centralCache/server.lua", "server")
end

-- Warning for extensive dependency loading time
-- Usually warning about dependency loading would only happen if we have debug enabled
--- But through testing it appears that quite a few servers keep scripts in their servers without starting them
--- This would cause the dependency loader to get stuck indefinitely without any warnings
local warnDependencyLoadingTime = 3 * 1000

local pendingStates = {starting = true, stopping = true, stopped = true}

---@param subject string @ Sentence start naming what we are waiting for
local function warnDependencyLoading(subject)
    print("^1========== [WARNING] ==========^7")
    print("^1> " .. subject .. "^7")
    print("^1> If this warning persists & our resources are not behaving as expected, please visit:^7")
    print("^1> https://docs.zykeresources.com/common-issues/zyke_lib-error#awaiting-dependencies-indefinitely^7")
end

---@param fileName string
---@return "started" | "starting" | "stopping" | "stopped" | "missing" | "uninitialized" | "unknown"
local function awaitSystemStarting(fileName)
    local resState = GetResourceState(fileName)

    -- If the resource does exist but is not started yet, we need to wait for it
    -- This is a more foolproof approach to avoid having exact resource starting sequences
    if (pendingStates[resState]) then
        local started = GetGameTimer()
        local silenceWarnings = LibConfig.silenceWarnings

        while (1) do
            resState = GetResourceState(fileName)
            if (resState == "started") then Wait(50) return resState end

            if (silenceWarnings ~= true and GetGameTimer() - started > warnDependencyLoadingTime) then
                warnDependencyLoading("\"" .. fileName .. "\" is taking a long time to start...")

                Wait(5000)
            end

            Functions.debug.internal("^1Waiting for " .. fileName .. " to start...^7")
            Wait(10)
        end
    end

    return resState
end

-- Auto-detection can not await the candidates one by one, since servers often keep an unused alternative installed
-- Awaiting a higher listed resource that never starts would block the one they actually run
---@generic T: {fileName: string}
---@param systems T[] @ Candidates in priority order
---@return T? system @ nil if no candidate is installed
local function awaitAnySystemStarting(systems)
    local started = GetGameTimer()
    local silenceWarnings = LibConfig.silenceWarnings

    while (1) do
        local pending = {}
        local isAwaitingPriority = false

        for i = 1, #systems do
            local fileName = systems[i].fileName
            local resState = GetResourceState(fileName)

            if (resState == "started" and not isAwaitingPriority) then Wait(50) return systems[i] end

            -- A higher listed candidate that is mid-start will finish shortly, so it keeps its priority
            if (resState == "starting") then isAwaitingPriority = true end
            if (pendingStates[resState]) then pending[#pending+1] = fileName end
        end

        if (#pending == 0) then return nil end

        if (silenceWarnings ~= true and GetGameTimer() - started > warnDependencyLoadingTime) then
            warnDependencyLoading("None of \"" .. table.concat(pending, "\", \"") .. "\" have started yet...")

            Wait(5000)
        end

        Functions.debug.internal("^1Waiting for any of " .. table.concat(pending, ", ") .. " to start...^7")
        Wait(10)
    end
end

---@param fileName string
---@return function
local function compileSystem(fileName)
    local chunk = LoadResourceFile(LibName, ("systems/%s.lua"):format(fileName))
    local func, err = load(chunk, ("@@%s/systems/%s.lua"):format(LibName, fileName))

    if (not func or err) then
        error(err)
    end

    return func
end

---@class SystemDefinition
---@field name string @ File in systems/ & key in dependency_override.lua
---@field global string @ Global the system file selects
---@field isAlwaysAwaited? boolean @ Its system file fetches data once, so it can not be selected again later
---@field isSelfFollowing? boolean @ Never waits & follows resource starts & stops by itself, so it only runs once

---@type SystemDefinition[]
local systemDefinitions = {
    {name = "framework", global = "Framework", isAlwaysAwaited = true},
    {name = "inventory", global = "Inventory", isAlwaysAwaited = true},
    {name = "target", global = "Target"},
    {name = "gang", global = "GangSystem"},
    {name = "fuel", global = "FuelSystem"},
    {name = "vehicleKeys", global = "VehicleKeysSystem"},
    {name = "doorlock", global = "DoorlockSystem"},
    {name = "death", global = "DeathSystem"},
    {name = "hud", global = "HudSystem"},
    {name = "banking", global = "BankingSystem"},
    {name = "notification", global = "NotificationSystem"},
    {name = "phone", global = "PhoneSystem", isSelfFollowing = true},
    {name = "dispatch", global = "DispatchSystem", isSelfFollowing = true},
    {name = "progressbar", global = "ProgressBarSystem"},
    {name = "billing", global = "BillingSystem"},
    {name = "jail", global = "JailSystem"},
    {name = "mileage", global = "MileageSystem"},
    {name = "appearance", global = "AppearanceSystem"},
}

-- From zyke_systems {...}, which FiveM stores as "zyke_system" entries
---@type table<string, true>?
local listedSystems = nil

local listedCount = GetNumResourceMetadata(ResName, "zyke_system")
if (listedCount > 0) then
    listedSystems = {}

    local validNames, isValidName = {}, {}
    for i = 1, #systemDefinitions do
        validNames[i] = systemDefinitions[i].name
        isValidName[systemDefinitions[i].name] = true
    end

    for i = 0, listedCount - 1 do
        local name = GetResourceMetadata(ResName, "zyke_system", i)

        if (not isValidName[name]) then
            print(("^1[zyke_lib] %s lists the unknown system '%s' in zyke_systems. Valid systems: %s^7"):format(ResName, name, table.concat(validNames, ", ")))
        end

        listedSystems[name] = true
    end
end

---@param definition SystemDefinition
---@param func function
---@param override string
local function loadSystem(definition, func, override)
    local startedAt = GetGameTimer()

    func(awaitSystemStarting, override, awaitAnySystemStarting)

    Functions.debug.internal(("Loaded %s in %dms"):format(definition.name, GetGameTimer() - startedAt), _G[definition.global])
end

---@type table<string, fun(startedName?: string, stoppedName?: string)[]> @ Selectors by the resource names they select from
local followers = {}

---@param providerName string
---@param resourceName string
---@return boolean isProvided
local function isProvidedBy(providerName, resourceName)
    for i = 0, GetNumResourceMetadata(providerName, "provide") - 1 do
        if (GetResourceMetadata(providerName, "provide", i) == resourceName) then return true end
    end

    return false
end

-- During its stop event a resource still reads as started, and during its server start event as starting, as do the names it provides
---@param resourceName string
---@param startedName? string @ Resource whose start event is running
---@param stoppedName? string @ Resource whose stop event is running
---@return boolean isStarted
local function isResourceStarted(resourceName, startedName, stoppedName)
    if (stoppedName and (resourceName == stoppedName or isProvidedBy(stoppedName, resourceName))) then return false end

    -- A client start event can arrive after the resource stopped again, its state then keeps it from being selected
    if (startedName and (resourceName == startedName or isProvidedBy(startedName, resourceName))) then
        local state = GetResourceState(startedName)

        return state == "started" or state == "starting"
    end

    return GetResourceState(resourceName) == "started"
end

-- Never waits: selects from the resources running now & again whenever one of them starts or stops
---@param definition SystemDefinition
---@param func function
---@param override string
local function followSystem(definition, func, override)
    local watched = {}
    local startedName, stoppedName = nil, nil
    local selectSystem

    ---@param resourceName string
    local function watch(resourceName)
        if (watched[resourceName]) then return end

        watched[resourceName] = true

        local selectors = followers[resourceName] or {}
        selectors[#selectors + 1] = selectSystem
        followers[resourceName] = selectors
    end

    -- Stands in for awaitSystemStarting, without waiting
    ---@param fileName string
    ---@return string state
    local function readSystemState(fileName)
        watch(fileName)

        if (isResourceStarted(fileName, startedName, stoppedName)) then return "started" end

        local state = GetResourceState(fileName)

        return state == "started" and "stopping" or state
    end

    -- Stands in for awaitAnySystemStarting, without waiting
    ---@generic T: {fileName: string}
    ---@param systems T[] @ Candidates in priority order
    ---@return T? system @ nil while no candidate runs
    local function readStartedSystem(systems)
        for i = 1, #systems do
            watch(systems[i].fileName)
        end

        for i = 1, #systems do
            if (isResourceStarted(systems[i].fileName, startedName, stoppedName)) then return systems[i] end
        end
    end

    -- An exact override is only selected while that resource runs, so one that starts later logs no warning
    local isExactOverride = override ~= "auto" and override ~= "none"

    ---@param started? string @ Resource whose start event is running
    ---@param stopped? string @ Resource whose stop event is running
    function selectSystem(started, stopped)
        startedName, stoppedName = started, stopped
        _G[definition.global] = nil

        if (not isExactOverride or isResourceStarted(override, started, stopped)) then
            func(readSystemState, override, readStartedSystem)
        end

        Functions.debug.internal(("Following %s"):format(definition.name), _G[definition.global])
    end

    if (isExactOverride) then watch(override) end

    selectSystem()
end

-- A resource also answers for the names it provides
---@param resourceName string
---@param started? string @ Resource whose start event is running
---@param stopped? string @ Resource whose stop event is running
local function selectFollowers(resourceName, started, stopped)
    local names = {resourceName}
    for i = 0, GetNumResourceMetadata(resourceName, "provide") - 1 do
        names[#names + 1] = GetResourceMetadata(resourceName, "provide", i)
    end

    local isSelected = {}
    for i = 1, #names do
        local selectors = followers[names[i]] or {}

        for j = 1, #selectors do
            if (not isSelected[selectors[j]]) then
                isSelected[selectors[j]] = true

                selectors[j](started, stopped)
            end
        end
    end
end

-- Registered before any system is selected, so no start or stop can fall between a selection & its handlers
if (listedSystems) then
    ---@param resourceName string
    local function onResourceStart(resourceName)
        selectFollowers(resourceName, resourceName, nil)
    end

    ---@param resourceName string
    local function onResourceStop(resourceName)
        selectFollowers(resourceName, nil, resourceName)
    end

    if (Context == "server") then
        AddEventHandler("onResourceStart", onResourceStart)
    else
        AddEventHandler("onClientResourceStart", onResourceStart)
    end

    -- Clients hear onResourceStop a frame before onClientResourceStop, while the resource still runs
    AddEventHandler("onResourceStop", onResourceStop)
end

---@type table<string, string> @ System names by their global, for the systems this resource did not list
local unlistedSystems = {}

for i = 1, #systemDefinitions do
    local definition = systemDefinitions[i]
    local func = compileSystem(definition.name)
    local override = dependencyOverrides[definition.name] or "auto"

    -- Without a list every system is awaited, as it was before the list existed
    local isAwaited = not listedSystems or definition.isAlwaysAwaited or listedSystems[definition.name]

    if (not isAwaited) then unlistedSystems[definition.global] = definition.name end

    if (isAwaited or definition.isSelfFollowing) then
        loadSystem(definition, func, override)
    else
        followSystem(definition, func, override)
    end
end

-- imports.lua warns when this resource uses one of them, since it is not awaited while the resource starts
if (listedSystems) then UnlistedSystems = unlistedSystems end

HasLoadedDependencies = true

-- EXPERIMENTAL LOADER
-- An experimental custom loader to handle dependencies before loading any of the files
-- To put it shortly, this allows our resources to be started wherever in the startup sequence since we wait for dependencies to be loaded properly
-- This also ensures that the server side is always loaded before the client side

AddEventHandler("onResourceStop", function(resName)
    if (resName ~= ResName) then return end

    GlobalState[ResName .. ":loader:serverLoaded"] = false
end)

-- We need to make sure that all of our dependencies are loaded before we start loading our files
-- We also have to check if they are using our loader or not, to wait for the global state to be set
-- If the resource is labeled a dependency, it will automatically start that resource so we don't have to do anything other than waiting
-- For some reason you just can't check for "dependencies", you have to type out each dependency as "dependency" in the fxmanifest.lua and then check for it in here
local dependencyCount = GetNumResourceMetadata(GetCurrentResourceName(), "dependency")
for i = 1, dependencyCount do
    local dependency = GetResourceMetadata(GetCurrentResourceName(), "dependency", i - 1)

    -- Check if we are using our loader, and if so, wait for the global state
    -- If we are not using it, just ignore
    local isUsingLoader = GetResourceMetadata(dependency, "loader", 0) ~= nil
    if (isUsingLoader) then
        while (not GlobalState[dependency .. ":loader:serverLoaded"]) do
            Functions.debug.internal("Waiting for", dependency, "to load...")

            Wait(100)
        end

        Functions.debug.internal(dependency, "has loaded!")
    end
end

-- Fetch the total number of files specified in the "loader" metadata
local fileCount = GetNumResourceMetadata(GetCurrentResourceName(), "loader")

-- If we don't have any loader files, just ignore
-- We keep this for backwards compatibility
if (fileCount == 0) then
    if (Context == "server") then
        GlobalState[ResName .. ":loader:serverLoaded"] = true
    end
end

-- Check for Cfx-styled imports of files, ex. @zyke_lib/imports.lua would use the zyke_lib resource
---@param filePath string
---@return string | nil
local function getImportName(filePath)
    local isImport = filePath:sub(1, 1) == "@"
    if (isImport) then
        -- We extract the resource name for the import
        return filePath:sub(2):match("^([^/]+)")
    end
end

local contexts = {"client", "server", "shared"}

-- We allow a prefix of the <context>:x to be specified in the loader metadata
-- This is just to allow any naming conventions to be used
-- Goofy ahh code because regex didn't work for some reason, so we're using a simpler approach
---@param filePath string
---@return string | nil, "shared" | "server" | "client" | nil, string | nil @Return optional import file name to use instead of current resource name
local function extractMetadataDetails(filePath)
	filePath = filePath:gsub('^"(.-)"$', '%1')
	filePath = filePath:gsub('^[ \t]*(.-)[ \t\r]*$', '%1')

    for i = 1, #contexts do
        local context = nil

        -- Check for context:path format
        if (
            filePath:find(("^%s:"):format(contexts[i])) -- Check for context:path format
        ) then
            context = contexts[i]
            filePath = filePath:sub(context:len() + 2) -- Trim the context: from the file path
        elseif (
            filePath:find(("^%s/"):format(contexts[i])) -- Check for context/path format
            or filePath:find(("/%s/"):format(contexts[i])) -- Check for /context/path format
        ) then
            context = contexts[i]
        elseif (
            filePath:find(("%s.lua"):format(contexts[i])) -- Check for context.lua format
        ) then
            context = contexts[i]
        end

        if (context and filePath) then
            local importName = getImportName(filePath)
            if (importName) then
                filePath = filePath:sub(importName:len() + 3)
            end

            return filePath, context, importName
        end
    end

    -- If we are down here, warn that something is wrong
    return nil, nil, nil
end

local files = {}
for i = 1, fileCount do
	files[i] = GetResourceMetadata(GetCurrentResourceName(), "loader", i - 1)
end

local toLoad = {}

Functions.debug.internal("Iterating", fileCount, "files...")
for i = 1, #files do
	local fileName, context, importName = extractMetadataDetails(files[i])
    if (fileName == nil) then goto continue end

    -- Make sure we are in the right context
	if (
        context == nil
        or (
            context ~= "shared"
            and context ~= Context
        )
    ) then
		goto continue
	end

    toLoad[#toLoad+1] = {
        fileName = fileName,
        context = context,
        importName = importName
    }

	::continue::
end

Functions.debug.internal("Finished iterating files!")

if (Context == "client") then
    while (not GlobalState[ResName .. ":loader:serverLoaded"]) do
        Functions.debug.internal("Waiting for server to finish loading...")
        Wait(10)
    end
end

Functions.debug.internal("Loading files...")
for i = 1, #toLoad do
    local fileName = toLoad[i].fileName
    local context = toLoad[i].context
    local resourceName = toLoad[i].importName or ResName
    local loaderFileKey = getLoaderFileKey(fileName, context, resourceName)

    if (not preloadedLoaderFiles[loaderFileKey]) then
        loadLoaderFile(fileName, resourceName)
    end
end

Functions.debug.internal("Finished loading files!")

if (Context == "server") then
    GlobalState[ResName .. ":loader:serverLoaded"] = true
end

Functions.debug.internal("Loader finished!")