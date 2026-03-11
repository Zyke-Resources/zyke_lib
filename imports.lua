HasLoaderFinished = false
LibName = "zyke_lib"
Context = IsDuplicityVersion() and "server" or "client"

ResName = GetCurrentResourceName()
TrimmedResName = ResName:sub(6, #ResName) -- Removes zyke_

-- Id/name for keymapping, to track if you are still holding the button
HoldingKeys = {}

local function empty() end

-- Load the chunk & function
local function loadFunc(path, self, index)
    self[index] = empty

    local contextChunk = LoadResourceFile(LibName, ("%s/%s/%s.lua"):format(path, index, Context))
    local sharedChunk = LoadResourceFile(LibName, ("%s/%s/shared.lua"):format(path, index))

    local chunk = sharedChunk or contextChunk
    local _context = sharedChunk and "shared" or Context

    if (chunk) then
        local func, err = load(chunk, ("@@%s/%s/%s/%s.lua"):format(LibName, path, index, _context))
        if (not func or err) then return error(err) end

        local res = func()

        -- Check if this is a cached function
        if (type(res) == "table" and res.cached == true and res.fetch and res.get) then
            -- If we're in zyke_lib itself, register the fetcher with central cache
            if (ResName == LibName and RegisterCachedFunction) then
                RegisterCachedFunction(index, res.fetch)
            end

            -- Create a wrapper that fetches from cache once, then uses local cache
            local cacheKey = "_zykeCache_" .. index
            local getFunc = res.get

            local function cachedWrapper(...)
                local localCache = rawget(_G, cacheKey)
                if (localCache == nil) then
                    -- First call in this resource: fetch from central cache via export
                    localCache = exports[LibName]:getCachedData(index)
                    rawset(_G, cacheKey, localCache or false) -- false to mark "attempted but nil"
                end

                -- If cache is false (nil result), return nil
                if (localCache == false) then return nil end

                return getFunc(localCache, ...)
            end

            self[index] = cachedWrapper

            return cachedWrapper
        end

        self[index] = res or empty

        return self[index]
    end
end

-- If the function is not cached, load it and cache it
-- Once it is cached, this will no longer run
local function execute(path, self, index, ...)
    local module = loadFunc(path, self, index)

    if (not module) then
        local function export(...)
            return exports[LibName][index](nil, ...)
        end

        if (not ...) then
            self[index] = export
        end

        return export
    end

    return module
end

local debug_getinfo = debug.getinfo

Functions = setmetatable({
    name = LibName,
}, {
    __newindex = function(self, key, fn)
        rawset(self, key, fn)

        -- Auto-register exports when set from zyke_lib's own interfaces
        if (debug_getinfo(2, 'S').short_src:find('@zyke_lib/interfaces')) then
            exports(key, fn)
        end
    end,
    __index = function(self, index)
        return execute("functions", self, index)
    end,
    __call = function(self, index, ...)
        return execute("functions", self, index, ...)
    end,
})

Formatting = setmetatable({
    name = LibName,
}, {
    __index = function(self, index)
        return execute("formatting", self, index)
    end,
    __call = function(self, index, ...)
        return execute("formatting", self, index, ...)
    end,
})

-- Shorthand
Z = Functions

-- ##### Basics ##### --

LibConfig = load(LoadResourceFile(LibName, "config.lua"))()
T, Translations = load(LoadResourceFile(LibName, "translations.lua"))()

-- Verify UI build
local hasUISrc = LoadResourceFile(GetCurrentResourceName(), "nui_source/index.html")
local hasUIBuild = LoadResourceFile(GetCurrentResourceName(), "nui/index.html")
if (hasUISrc and not hasUIBuild) then
    while (1) do
        print("^1UI source files found, but no UI build found. Please build the UI or download the build version from the GitHub repository.^7")
        print("https://docs.zykeresources.com/common-issues/downloading-source-files")

        Wait(1000)
    end
end

local loaderChunk = LoadResourceFile(LibName, "loader.lua")
local loaderFunc, err = load(loaderChunk, ("@@%s/loader.lua"):format(LibName))
if (not loaderFunc or err) then
    error(err)
end

loaderFunc()

-- ##### Force Loading ##### --

-- Force loading to ensure both contexts are started
local forceLoad = {
    "notify/client.lua",
    "createUniqueId/server.lua",
    "hasPermission/server.lua",
    "getPlayersOnJob/server.lua",
    "getJobData/server.lua",
    "getGangData/server.lua",
    "getCharacter/server.lua",
    "getVehicles/server.lua",
    "getAccountIdentifier/server.lua",
    "getJobs/server.lua",
    "getPlayers/server.lua",
    "getPlayersInArea/server.lua",
    "getVehicleClass/server.lua",
    "getModelMaxSeats/server.lua",
    "getModelLabel/server.lua",
}

for i = 1, #forceLoad do
    local start = forceLoad[i]:find("/")
    local name = forceLoad[i]:sub(1, start - 1)

    loadFunc("functions", Functions, name)
end

-- Automatically version checking with support for legacy system where we individually imported this
if (Context == "server") then
    ---@param metadataKey string
    ---@param idx integer
    ---@return boolean
    local function isScriptVersionChecker(metadataKey, idx)
        local script = GetResourceMetadata(GetCurrentResourceName(), metadataKey, idx)

        return script:find("@zyke_lib/versionchecker.lua") ~= nil
    end

    -- Legacy support for resources that import the versionchecker in their fxmanifest
    local shouldSkip = false
    local serverScripts = GetNumResourceMetadata(GetCurrentResourceName(), "server_script")
    for i = 1, serverScripts do
        if (isScriptVersionChecker("server_script", i - 1)) then
            shouldSkip = true
            break
        end
    end

    if (not shouldSkip) then
        local loaderScripts = GetNumResourceMetadata(GetCurrentResourceName(), "loader")
        for i = 1, loaderScripts do
            if (isScriptVersionChecker("loader", i - 1)) then
                shouldSkip = true
                break
            end
        end
    end

    if (not shouldSkip) then
        local versionChunk = LoadResourceFile(LibName, "versionchecker.lua")
        local versionFunc, err = load(versionChunk, ("@@%s/versionchecker.lua"):format(LibName))
        if (not versionFunc or err) then
            error(err)
        end

        versionFunc()
    end
end

HasLoaderFinished = true
TriggerEvent("zyke_lib:OnLoaderFinished")