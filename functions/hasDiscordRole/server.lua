---@param target PlayerId | string @ Player server ID or Discord user ID
---@param roleIds string[] | string @ Role IDs as strings, an array passes when any one role is held
---@param maxAge? integer @ Seconds a cached answer may be old, older is fetched from Discord first
---@return boolean hasRole
function Functions.hasDiscordRole(target, roleIds, maxAge)
    local roles = Functions.getDiscordRoles(target, maxAge)
    if (not roles) then return false end

    local wanted = type(roleIds) == "table" and roleIds or {roleIds}

    for i = 1, #roles do
        for j = 1, #wanted do
            if (roles[i] == wanted[j]) then return true end
        end
    end

    return false
end

return Functions.hasDiscordRole