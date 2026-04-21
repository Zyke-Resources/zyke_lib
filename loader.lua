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

-- Warning for extensive dependency loading time
-- Usually warning about dependency loading would only happen if we have debug enabled
--- But through testing it appears that quite a few servers keep scripts in their servers without starting them
--- This would cause the dependency loader to get stuck indefinitely without any warnings
local warnDependencyLoadingTime = 3 * 1000

---@param fileName string
---@return "started" | "starting" | "stopping" | "stopped" | "missing" | "uninitialized" | "unknown"
local function awaitSystemStarting(fileName)
    local resState = GetResourceState(fileName)

    -- If the resource does exist but is not started yet, we need to wait for it
    -- This is a more foolproof approach to avoid having exact resource starting sequences
    if (resState == "starting" or resState == "stopping" or resState == "stopped") then
        local started = GetGameTimer()

        while (1) do
            resState = GetResourceState(fileName)
            if (resState == "started") then Wait(50) return resState end

            if (GetGameTimer() - started > warnDependencyLoadingTime) then
                print("^1========== [WARNING] ==========^7")
                print("^1> \"" .. fileName .. "\" is taking a long time to start...^7")
                print("^1> If this warning persists & our resources are not behaving as expected, please visit:^7")
                print("^1> https://docs.zykeresources.com/common-issues/zyke_lib-error#awaiting-dependencies-indefinitely^7")

                Wait(5000)
            end

            Functions.debug.internal("^1Waiting for " .. fileName .. " to start...^7")
            Wait(10)
        end
    end

    return resState
end

---@param fileName string
---@param overrideKey string
---@return function
local function loadSystem(fileName, overrideKey)
    local chunk = LoadResourceFile(LibName, ("systems/%s.lua"):format(fileName))
    local func, err = load(chunk, ("@@%s/systems/%s.lua"):format(LibName, fileName))

    if (not func or err) then
        error(err)
    end

    local override = dependencyOverrides[overrideKey] or "auto"

    return func(awaitSystemStarting, override)
end

loadSystem("framework", "framework")
Functions.debug.internal("Loaded framework", Framework)

loadSystem("inventory", "inventory")
Functions.debug.internal("Loaded inventory", Inventory)

loadSystem("target", "target")
Functions.debug.internal("Loaded target", Target)

loadSystem("gang", "gang")
Functions.debug.internal("Loaded gang", GangSystem)

loadSystem("fuel", "fuel")
Functions.debug.internal("Loaded fuel", FuelSystem)

loadSystem("death", "death")
Functions.debug.internal("Loaded death", DeathSystem)

loadSystem("banking", "banking")
Functions.debug.internal("Loaded banking", BankingSystem)

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
                filePath = filePath:sub(importName:len() + 2)
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
    local resourceName = toLoad[i].importName or GetCurrentResourceName()

    Functions.debug.internal("Attempting to load", resourceName, fileName)

	local chunk = LoadResourceFile(resourceName, fileName)
	if (not chunk) then
		error("Failed to load " .. "(" .. toLoad[i].fileName .. ")")
	end

    Functions.debug.internal("Loaded chunk! Attempting to execute function...")

	local func = load(chunk, ("@@%s/%s"):format(resourceName, toLoad[i].fileName))
	if (not func) then
		error("Failed to load " .. "(" .. toLoad[i].fileName .. ")")
	end

    func()

    Functions.debug.internal("Function executed!")
end

Functions.debug.internal("Finished loading files!")

if (Context == "server") then
    GlobalState[ResName .. ":loader:serverLoaded"] = true
end

Functions.debug.internal("Loader finished!")