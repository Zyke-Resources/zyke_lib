Functions.network = {}

---@param entity? Entity
---@return boolean valid
function Functions.network.isEntityValid(entity)
    return entity ~= nil and entity ~= 0 and DoesEntityExist(entity)
end

---@param netId? NetId @ Network id
---@return Entity? entity
function Functions.network.getEntity(netId)
    if (not netId or netId <= 0) then return nil end
    if (Context == "client" and not NetworkDoesNetworkIdExist(netId)) then return nil end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if (not Functions.network.isEntityValid(entity)) then return nil end

    return entity
end

---@param entity? Entity
---@return NetId? netId
function Functions.network.getNetId(entity)
    if (not Functions.network.isEntityValid(entity)) then return nil end
    if (Context == "client" and NetworkGetEntityIsNetworked(entity) ~= 1) then return nil end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if (not netId or netId == 0) then return nil end

    return netId
end

---@param entity? Entity
---@param timeoutMs? integer @ Max wait time
---@param intervalMs? integer @ Poll interval
---@return NetId? netId
function Functions.network.waitForNetId(entity, timeoutMs, intervalMs)
    local timeoutAt = GetGameTimer() + (timeoutMs or 5000)
    local waitMs = intervalMs or 10

    while (GetGameTimer() < timeoutAt) do
        local netId = Functions.network.getNetId(entity)
        if (netId) then return netId end

        Wait(waitMs)
    end

    return nil
end

---@param netId? NetId
---@param timeoutMs? integer @ Max wait time
---@param intervalMs? integer @ Poll interval
---@return Entity? entity
function Functions.network.waitForEntity(netId, timeoutMs, intervalMs)
    local timeoutAt = GetGameTimer() + (timeoutMs or 5000)
    local waitMs = intervalMs or 10

    while (GetGameTimer() < timeoutAt) do
        local entity = Functions.network.getEntity(netId)
        if (entity) then return entity end

        Wait(waitMs)
    end

    return nil
end

return Functions.network