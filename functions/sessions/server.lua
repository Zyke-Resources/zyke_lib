-- Keeps track of people in sessions / routing buckets
-- Mainly to prevent looping hundreds of players when those few needed can be stored

Functions.sessions = {}

---@class Session
---@field players PlayerId[]
---@field entities NetId[]

---@type Session[]
local sessions = {}

---@param sessionId integer
local function ensureSessionId(sessionId)
    if (not sessions[sessionId]) then
        sessions[sessionId] = {
            players = {},
            entities = {},
        }
    end
end

---@param id integer
local function canRelieveSession(id)
    local session = sessions[id]

    return session == nil or (#session.players == 0 and #session.entities == 0)
end

---@param id integer
local function relieveSession(id)
    if (not canRelieveSession(id)) then return end

    sessions[id] = nil
end

---@param playerId PlayerId
---@param sessionId integer
function Functions.sessions.setPlayer(playerId, sessionId)
    ensureSessionId(sessionId)

    local prevId = GetPlayerRoutingBucket(tostring(playerId))
    if (prevId and prevId ~= 0) then
        Functions.sessions.clearPlayer(playerId, true)
    end

    sessions[sessionId].players[#sessions[sessionId].players+1] = playerId
    SetPlayerRoutingBucket(tostring(playerId), sessionId)
end

---@param netId NetId
---@param sessionId integer
function Functions.sessions.setEntity(netId, sessionId)
    ensureSessionId(sessionId)

    local entity = Functions.network.getEntity(netId)
    if (not entity) then return end

    local prevId = GetEntityRoutingBucket(entity)
    if (prevId and prevId ~= 0) then
        Functions.sessions.clearEntity(entity, true)
    end

    sessions[sessionId].entities[#sessions[sessionId].entities+1] = netId

    SetEntityRoutingBucket(entity, sessionId)
end

---@param playerId PlayerId
---@param blockRelieve? boolean @When chaining multiple together, sometimes you want to wait to relieve
function Functions.sessions.clearPlayer(playerId, blockRelieve)
    local id = GetPlayerRoutingBucket(tostring(playerId))
    if (not id or id == 0 or not sessions[id]) then return end

    for i = 1, #sessions[id].players do
        if (sessions[id].players[i] == playerId) then
            table.remove(sessions[id].players, i)
            break
        end
    end

    SetPlayerRoutingBucket(tostring(playerId), 0)

    if (not blockRelieve) then
        relieveSession(id)
    end
end

---@param netId NetId
---@param blockRelieve? boolean @When chaining multiple together, sometimes you want to wait to relieve
function Functions.sessions.clearEntity(netId, blockRelieve)
    local entity = Functions.network.getEntity(netId)
    if (not entity) then return end

    local id = GetEntityRoutingBucket(entity)
    if (not id or id == 0 or not sessions[id]) then return end

    for i = 1, #sessions[id].entities do
        if (sessions[id].entities[i] == netId) then
            table.remove(sessions[id].entities, i)
            break
        end
    end

    SetEntityRoutingBucket(entity, 0)

    if (not blockRelieve) then
        relieveSession(id)
    end
end

---@param sessionId integer
---@return Session
function Functions.sessions.getSession(sessionId)
    return sessions[sessionId] and sessions[sessionId] or {players = {}, entities = {}}
end

-- TODO: Track routing bucket changes, and add players to that session automatically if they are not in it
-- This is to add compatibility if some other resource is setting routing bucket, so they are in sync with our system

return Functions.sessions