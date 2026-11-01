-- Discord roles for every resource, fetched one request at a time so the bot token stays under Discord's rate limits
-- Lookups that wait for an answer go before background refreshes, which only use what is left of each bucket

local botToken = GetConvar("zyke_lib:discordBotToken", "")
local guildId = GetConvar("zyke_lib:discordGuildId", "")

local settings = LibConfig.discordRoles or {}
local keepAfterRestart = settings.keepAfterRestart ~= false

local memberUrl = "https://discord.com/api/v10/guilds/%s/members/%s"
local kvpPrefix = "discordRoles:"

-- Seconds
local refreshAge = (settings.refreshMinutes or 10) * 60
local joinRefreshAge = 60
local pruneAge = 14 * 24 * 60 * 60

-- Milliseconds
local refreshInterval = 30000
local lookupTimeout = 5000
local failureBackoff = 5000
local unknownRetryAfter = 60000

-- Discord's error code for a guild ID that does not exist
local unknownGuildCode = 10004

---@class DiscordRolesEntry
---@field roles string[] @ Role IDs, empty when the user is not in the guild
---@field fetchedAt integer @ os.time() of the fetch

---@type table<string, DiscordRolesEntry>
local cache = {}

---@type string[]
local urgentQueue = {}
---@type string[]
local backgroundQueue = {}
---@type table<string, "urgent" | "background">
local queuedAs = {}
---@type string?
local inFlight = nil
local isProcessing = false
-- GetGameTimer() value before which no request is sent
local blockedUntil = 0

-- Counted down here, since error responses carry no rate limit headers
---@type integer?
local bucketLimit = nil
local bucketRemaining = 0
local bucketResetAt = 0
-- Milliseconds, the longest reset seen
local bucketWindow = 0

local isConfigured = botToken ~= "" and guildId ~= ""
local isDisabled = not isConfigured
local hasWarnedUnconfigured = false

---@param reason string
local function disable(reason)
    isDisabled = true

    print(("^1[zyke_lib] Discord roles disabled: %s^7"):format(reason))
end

---@param target PlayerId | string @ Player server ID or Discord user ID
---@return string? discordId
local function getDiscordId(target)
    local identifier = type(target) == "number" and GetPlayerIdentifierByType(tostring(target), "discord") or target
    if (type(identifier) ~= "string") then return nil end

    local discordId = identifier:gsub("^discord:", "")
    if (not discordId:match("^%d+$")) then return nil end

    return discordId
end

---@param entry? DiscordRolesEntry
---@param maxAge integer @ Seconds
---@return boolean isFresh
local function isFresh(entry, maxAge)
    return entry ~= nil and os.time() - entry.fetchedAt <= maxAge
end

---@param discordId string
---@param roles string[]
local function saveEntry(discordId, roles)
    cache[discordId] = {roles = roles, fetchedAt = os.time()}

    if (keepAfterRestart) then SetResourceKvp(kvpPrefix .. discordId, json.encode(cache[discordId])) end
end

---@param headers table<string, string>
---@param name string @ Lowercase header name
---@return number?
local function getHeaderNumber(headers, name)
    for key, value in pairs(headers) do
        if (key:lower() == name) then return tonumber(value) end
    end
end

-- Error bodies are not JSON when Cloudflare answers instead of Discord
---@param body? string
---@return table?
local function decodeBody(body)
    if (not body or body == "") then return nil end

    local success, data = pcall(json.decode, body)
    if (not success or type(data) ~= "table") then return nil end

    return data
end

-- FiveM passes no headers or body for an error status, only "HTTP <status>: <body>" in errorData
---@param errorData? string
---@return table?
local function decodeError(errorData)
    return errorData and decodeBody(errorData:match("^HTTP %d+: (.*)$"))
end

---@param headers table<string, string>
---@param now integer @ GetGameTimer() of the response
local function updateBucket(headers, now)
    local remaining = getHeaderNumber(headers, "x-ratelimit-remaining")
    local resetAfter = getHeaderNumber(headers, "x-ratelimit-reset-after")

    if (remaining and resetAfter) then
        bucketLimit = getHeaderNumber(headers, "x-ratelimit-limit") or bucketLimit
        bucketRemaining = remaining
        bucketResetAt = now + math.ceil(resetAfter * 1000)
        bucketWindow = math.max(bucketWindow, bucketResetAt - now)
    elseif (bucketLimit and now >= bucketResetAt) then
        bucketRemaining = bucketLimit - 1
        bucketResetAt = now + bucketWindow
    else
        bucketRemaining -= 1
    end

    -- An empty bucket is waited out before the next request instead of running into a 429
    if (bucketLimit and bucketRemaining <= 0) then blockedUntil = math.max(blockedUntil, bucketResetAt) end
end

---@param discordId string
---@param status integer
---@param body? string
---@param headers table<string, string>
---@param errorData? string
---@return boolean retry
local function handleResponse(discordId, status, body, headers, errorData)
    local now = GetGameTimer()

    updateBucket(headers, now)

    if (status == 200) then
        local member = decodeBody(body)
        if (member) then saveEntry(discordId, member.roles or {}) end

        return false
    end

    if (status == 429) then
        local retryAfter = decodeError(errorData)?.retry_after
        blockedUntil = math.max(blockedUntil, now + (retryAfter and math.ceil(retryAfter * 1000) or unknownRetryAfter))

        return true
    end

    if (status == 401 or status == 403) then
        disable(("Discord refused the bot token (HTTP %s), check zyke_lib:discordBotToken and that the bot is in the guild"):format(status))

        return false
    end

    if (status == 404) then
        local data = decodeError(errorData)

        if (data and data.code == unknownGuildCode) then
            disable("Discord does not know the guild in zyke_lib:discordGuildId")
        else
            saveEntry(discordId, {})
        end

        return false
    end

    -- Discord is down or unreachable, the stored entry is kept
    blockedUntil = math.max(blockedUntil, now + failureBackoff)

    return false
end

---@return string[] queue
---@return integer readyAt @ GetGameTimer() value the next request may be sent at
local function getNextQueue()
    local queue = #urgentQueue > 0 and urgentQueue or backgroundQueue
    local readyAt = blockedUntil

    -- Background refreshes leave the last request of a bucket to lookups that wait for an answer
    if (queue == backgroundQueue and bucketLimit and bucketRemaining <= 1) then readyAt = math.max(readyAt, bucketResetAt) end

    return queue, readyAt
end

---@param queue string[]
local function fetchFirst(queue)
    local discordId = queue[1]
    inFlight = discordId

    local status, body, headers, errorData = PerformHttpRequestAwait(memberUrl:format(guildId, discordId), "GET", "", {["Authorization"] = "Bot " .. botToken})
    inFlight = nil

    if (handleResponse(discordId, status, body, headers or {}, errorData)) then return end

    table.remove(queue, 1)

    queuedAs[discordId] = nil
end

local function processQueue()
    while (not isDisabled) do
        local queue, readyAt = getNextQueue()
        if (#queue == 0) then break end

        local waitTime = readyAt - GetGameTimer()

        if (waitTime > 0) then
            -- Short steps, so a lookup queued meanwhile still goes before a background refresh
            Wait(math.min(waitTime, 100))
        else
            fetchFirst(queue)
        end
    end

    urgentQueue = {}
    backgroundQueue = {}
    queuedAs = {}
    isProcessing = false
end

---@param discordId string
---@param isUrgent boolean @ A lookup is waiting for the answer
local function queueFetch(discordId, isUrgent)
    if (isDisabled or inFlight == discordId) then return end

    local queuedPriority = queuedAs[discordId]
    if (queuedPriority == "urgent" or (queuedPriority and not isUrgent)) then return end

    -- Moved up from the background queue
    if (queuedPriority) then
        for i = 1, #backgroundQueue do
            if (backgroundQueue[i] == discordId) then table.remove(backgroundQueue, i) break end
        end
    end

    local queue = isUrgent and urgentQueue or backgroundQueue
    queue[#queue + 1] = discordId
    queuedAs[discordId] = isUrgent and "urgent" or "background"

    if (isProcessing) then return end

    isProcessing = true

    CreateThread(processQueue)
end

-- Answers from the cache straight away and refreshes old entries in the background
-- With maxAge, an older entry is fetched again first, and the cached roles are the fallback when Discord does not answer in time
---@param target PlayerId | string @ Player server ID or Discord user ID
---@param maxAge? integer @ Seconds a cached answer may be old
---@return string[]? roles @ Role IDs, empty when not in the guild, nil when unknown
local function getDiscordRoles(target, maxAge)
    if (not isConfigured and not hasWarnedUnconfigured) then
        hasWarnedUnconfigured = true

        print("^3[zyke_lib] Discord roles were requested, but zyke_lib:discordBotToken or zyke_lib:discordGuildId is not set^7")
    end

    local discordId = getDiscordId(target)
    if (not discordId) then return nil end

    local entry = cache[discordId]

    if (entry and (not maxAge or isFresh(entry, maxAge))) then
        if (not isFresh(entry, refreshAge)) then queueFetch(discordId, false) end

        return entry.roles
    end

    queueFetch(discordId, true)

    local timeoutAt = GetGameTimer() + lookupTimeout
    while (queuedAs[discordId] and GetGameTimer() < timeoutAt) do
        Wait(50)
    end

    return cache[discordId]?.roles
end

exports("GetDiscordRoles", getDiscordRoles)

---@param target string @ Server ID, Discord ID, or another identifier of an online player such as license:...
---@return string? discordId
local function resolveTarget(target)
    if (target:match("^%d+$") and #target <= 6) then return getDiscordId(tonumber(target) --[[@as PlayerId]]) end
    if (not target:find(":") or target:find("^discord:")) then return getDiscordId(target) end

    local identifierType = target:match("^(%w+):")
    if (not identifierType) then return nil end

    local players = GetPlayers()

    for i = 1, #players do
        if (GetPlayerIdentifierByType(players[i], identifierType) == target) then return getDiscordId(tonumber(players[i]) --[[@as PlayerId]]) end
    end
end

-- Printed for the server console, which keeps who refreshed what, and shown to a player who used the command
---@param plyId PlayerId @ 0 for the server console
---@param message string
local function reply(plyId, message)
    print(("[zyke_lib] %s: %s"):format(plyId == 0 and "console" or GetPlayerName(tostring(plyId)), message))

    -- No nil gaps before raw: with the trailing nils of notify, the client can receive only the message
    if (plyId ~= 0) then Functions.notify(plyId, message, {}, 7000, true) end
end

---@param plyId PlayerId @ 0 for the server console
---@param target string
local function refreshTarget(plyId, target)
    if (target == "all") then
        local players = GetPlayers()
        local queued = 0

        for i = 1, #players do
            local discordId = getDiscordId(tonumber(players[i]) --[[@as PlayerId]])

            if (discordId) then
                queueFetch(discordId, false)

                queued += 1
            end
        end

        return reply(plyId, ("queued %s online players for a Discord role refresh"):format(queued))
    end

    local discordId = resolveTarget(target)
    if (not discordId) then return reply(plyId, ("%s is not online with Discord linked, or not a server ID or Discord ID"):format(target)) end

    local previous = cache[discordId]
    local roles = getDiscordRoles(discordId, 0)

    if (cache[discordId] == previous) then return reply(plyId, ("Discord did not answer for %s, the cached roles are kept"):format(target)) end

    reply(plyId, ("refreshed the Discord roles of %s (%s): %s roles"):format(target, discordId, #roles))
end

local refreshCommand = settings.refreshCommand

-- Server-side only with no net event, the same way txAdmin keeps its commands safe
-- The server console and txAdmin's live console always pass, players need one of the permissions in config.lua
if (refreshCommand) then
    ---@param plyId PlayerId @ 0 for the server console
    ---@param args string[]
    RegisterCommand(refreshCommand.command, function(plyId, args)
        if (not Functions.hasPermission(plyId, refreshCommand.permission)) then return end
        if (not isConfigured or isDisabled) then return reply(plyId, "Discord roles are not set up or were switched off, see the server console") end
        if (not args[1]) then return reply(plyId, ("usage: %s <server id | Discord ID | identifier | all>"):format(refreshCommand.command)) end

        CreateThread(function()
            refreshTarget(plyId, args[1])
        end)
    end, false)
end

-- A role changed while the player was away, or while the server was down, is corrected right after they connect
AddEventHandler("playerConnecting", function()
    local discordId = getDiscordId(source)
    if (not discordId) then return end

    local entry = cache[discordId]
    if (not isFresh(entry, joinRefreshAge)) then queueFetch(discordId, entry == nil) end
end)

-- Loaded before any lookup, so a restart answers from the stored roles instead of fetching every player again
do
    local handle = StartFindKvp(kvpPrefix)
    local expiredKeys = {}

    while (true) do
        local key = FindKvp(handle)
        if (not key) then break end

        local entry = json.decode(GetResourceKvpString(key))

        if (keepAfterRestart and isFresh(entry, pruneAge)) then
            cache[key:sub(#kvpPrefix + 1)] = entry
        else
            expiredKeys[#expiredKeys + 1] = key
        end
    end

    EndFindKvp(handle)

    for i = 1, #expiredKeys do
        DeleteResourceKvp(expiredKeys[i])
    end
end

-- Online players are kept up to date with what is left of each bucket
CreateThread(function()
    while (not isDisabled) do
        Wait(refreshInterval)

        local players = GetPlayers()

        for i = 1, #players do
            local discordId = getDiscordId(tonumber(players[i]) --[[@as PlayerId]])
            if (discordId and not isFresh(cache[discordId], refreshAge)) then queueFetch(discordId, false) end
        end
    end
end)