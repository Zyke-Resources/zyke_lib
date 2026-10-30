-- MySQL would fail the JSON_EXTRACT on an ESX row whose vehicle column isn't JSON, so those rows are left out
local queries = {
    ESX = "SELECT `plate`, `owner` AS `identifier`, JSON_UNQUOTE(JSON_EXTRACT(`vehicle`, '$.model')) AS `model` FROM `owned_vehicles` WHERE `plate` LIKE ? AND JSON_VALID(`vehicle`) LIMIT ?",
    QB = "SELECT `plate`, `citizenid` AS `identifier`, COALESCE(`hash`, `vehicle`) AS `model` FROM `player_vehicles` WHERE `plate` LIKE ? LIMIT ?",
}

-- Needs the calling resource to load @oxmysql/lib/MySQL.lua
---@param platePrefix string @ Upper case, LIKE wildcards escaped by the caller
---@param limit integer
---@return OwnedVehicle[] vehicles
function Functions.searchOwnedVehicles(platePrefix, limit)
    local query = queries[Framework]
    if (not query) then return {} end

    return MySQL.query.await(query, {platePrefix .. "%", limit}) or {}
end

return Functions.searchOwnedVehicles