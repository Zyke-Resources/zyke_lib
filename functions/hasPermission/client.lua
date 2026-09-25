-- ACE changes emit no client event, so answers are reused briefly and the server keeps enforcing access
local cacheDuration = 5000
---@type table<string, {expiresAt: integer, allowed?: boolean, request?: promise}>
local permissionCache = {}

---@param permission string[] | string @ Usually "command", array only checks if you have at least one of the permissions, not all
---@return boolean allowed
---@diagnostic disable-next-line: duplicate-set-field
function Functions.hasPermission(permission)
    local key = type(permission) == "table" and table.concat(permission, "\0") or tostring(permission)
    local cached = permissionCache[key]
    local now = GetGameTimer()
    if (cached and cached.expiresAt > now and cached.request) then return Citizen.Await(cached.request) end
    if (cached and cached.expiresAt > now) then return cached.allowed end

    -- Concurrent checks for the same permission share one server request unless it stopped responding
    local request = promise.new()
    local pending = {expiresAt = now + 10000, request = request}
    permissionCache[key] = pending
    local allowed = Functions.callback.await(ResName .. ":HasPermission", permission) == true
    if (permissionCache[key] == pending) then permissionCache[key] = {expiresAt = GetGameTimer() + cacheDuration, allowed = allowed} end
    request:resolve(allowed)

    return allowed
end

-- Character changes can swap the principals behind a permission
AddEventHandler("zyke_lib:OnCharacterSelect", function()
    permissionCache = {}
end)

return Functions.hasPermission