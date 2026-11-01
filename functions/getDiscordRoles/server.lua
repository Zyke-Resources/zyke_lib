---@param target PlayerId | string @ Player server ID or Discord user ID
---@param maxAge? integer @ Seconds a cached answer may be old, older is fetched from Discord first
---@return string[]? roles @ Role IDs, empty when not in the guild, nil when unknown
function Functions.getDiscordRoles(target, maxAge)
    return exports[LibName]:GetDiscordRoles(target, maxAge)
end

return Functions.getDiscordRoles