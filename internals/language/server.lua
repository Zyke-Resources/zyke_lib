-- Each player's own language lives in a replicated player state, so every resource reads the same choice on both sides
local stateKey = "zyke_lib:language"
-- Milliseconds, each change reloads the text of every resource that opts in
local changeCooldown = 1000

---@type table<string, true>
local allowedLanguages = {[LibConfig.language or "en"] = true}
for i = 1, #(LibConfig.playerLanguages or {}) do
    allowedLanguages[LibConfig.playerLanguages[i]] = true
end

---@type table<PlayerId, integer> @ When each player last changed language
local lastChanges = {}
---@type table<PlayerId, string> @ The newest choice of a player who changed again during the cooldown
local pendingLanguages = {}

---@param plyId PlayerId
---@param language string
local function setLanguage(plyId, language)
    lastChanges[plyId] = GetGameTimer()

    Player(plyId).state:set(stateKey, language, true)
end

-- Sent from the player's stored choice when zyke_lib starts on their client, & whenever they pick one
---@param language string
RegisterNetEvent("zyke_lib:setLanguage", function(language)
    if (type(language) ~= "string" or not allowedLanguages[language]) then return end

    local plyId = source
    local waitTime = (lastChanges[plyId] or -changeCooldown) + changeCooldown - GetGameTimer()
    if (waitTime <= 0) then return setLanguage(plyId, language) end

    -- Quick changes keep only the newest one, set once the cooldown ends
    local isScheduled = pendingLanguages[plyId] ~= nil
    pendingLanguages[plyId] = language
    if (isScheduled) then return end

    SetTimeout(waitTime, function()
        local pendingLanguage = pendingLanguages[plyId]
        pendingLanguages[plyId] = nil

        if (pendingLanguage and GetPlayerName(plyId)) then setLanguage(plyId, pendingLanguage) end
    end)
end)

AddEventHandler("playerDropped", function()
    lastChanges[source] = nil
    pendingLanguages[source] = nil
end)