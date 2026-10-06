-- QBCore and Qbox expose their groups as ACE permissions; ESX only keeps the group name on the player
---@param player Character | CharacterIdentifier | PlayerId
---@return string? group
local function getEsxGroup(player)
    if (Framework ~= "ESX") then return nil end

    local playerData = Functions.getPlayerData(player)
    if (not playerData) then return nil end

    return playerData.getGroup()
end

---@param player Character | CharacterIdentifier | PlayerId
---@param permission string[] | string @ ACE permission (usually "command") or framework group; an array passes when any one entry is held. ESX groups match the exact group name
---@return boolean allowed
---@diagnostic disable-next-line: duplicate-set-field
function Functions.hasPermission(player, permission)
    if (player == 0) then return true end -- Server request

    local plyId = Functions.getPlayerId(player)
    if (not plyId) then return false end

    local permissions = type(permission) == "table" and permission or {permission}

    for i = 1, #permissions do
        if (IsPlayerAceAllowed(tostring(plyId), permissions[i])) then return true end
    end

    local group = getEsxGroup(player)
    if (not group) then return false end

    for i = 1, #permissions do
        if (permissions[i] == group) then return true end
    end

    return false
end

Z.callback.register(ResName .. ":HasPermission", function(plyId, permission)
    return Functions.hasPermission(plyId, permission)
end)

return Functions.hasPermission