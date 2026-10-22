-- Returns the player IDs of all players in the area, server IDs when fetched from the server
-- Ignores self

---@param useServer? boolean
---@param pos? vector3 | Vector3Table @ Defaults to your position
---@param maxDst? number @ 400 default
---@return integer[] @ Client player indexes, or server IDs with useServer
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getPlayersInArea(useServer, pos, maxDst)
    if (useServer) then return Functions.callback.await(ResName .. ":GetPlayersInArea", pos, maxDst) end

    if (not pos) then pos = GetEntityCoords(PlayerPedId()) end
    if (not maxDst) then maxDst = 400 end

    local x, y, z = pos.x, pos.y, pos.z
    local players = GetActivePlayers()
    local selfPed = PlayerPedId()

    local inArea = {}
    for i = 1, #players do
        local ply = GetPlayerPed(players[i])
        local targetPos = GetEntityCoords(ply)
        local dst = #(targetPos - vec3(x, y, z))

        if (selfPed ~= ply and dst <= maxDst) then
            inArea[#inArea+1] = players[i]
        end
    end

    return inArea
end

return Functions.getPlayersInArea