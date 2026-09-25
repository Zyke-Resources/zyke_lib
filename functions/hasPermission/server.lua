---@param player Character | CharacterIdentifier | PlayerId
---@param permission string[] | string @Usually "command", array only checks if you have at least one of the permissions, not all
---@return boolean
---@diagnostic disable-next-line: duplicate-set-field
function Functions.hasPermission(player, permission)
    if (player == 0) then return true end -- Server request

    local plyId = Functions.getPlayerId(player)
    if (not plyId) then return false end

    if (type(permission) == "table") then
        for i = 1, #permission do
            if (IsPlayerAceAllowed(tostring(plyId), permission[i])) then
                return true
            end
        end
    else
        -- The native answers 1 when allowed, and client checks compare against true
        return IsPlayerAceAllowed(tostring(plyId), permission) and true or false
    end

    return false
end

Z.callback.register(ResName .. ":HasPermission", function(plyId, permission)
    return Functions.hasPermission(plyId, permission)
end)

return Functions.hasPermission