local queries = {
    ESX = "SELECT `plate`, `owner` AS `identifier`, IF(JSON_VALID(`vehicle`), JSON_UNQUOTE(JSON_EXTRACT(`vehicle`, '$.model')), NULL) AS `model` FROM `owned_vehicles` WHERE `plate` IN (?, ?) LIMIT 1",
    QB = "SELECT `plate`, `citizenid` AS `identifier`, COALESCE(`hash`, `vehicle`) AS `model` FROM `player_vehicles` WHERE `plate` IN (?, ?) LIMIT 1",
}

-- Matches the plate as given or without spaces, needs the calling resource to load @oxmysql/lib/MySQL.lua
---@param plate string
---@return OwnedVehicle? vehicle
function Functions.getOwnedVehicle(plate)
    local query = queries[Framework]
    if (not query) then return nil end

    return MySQL.single.await(query, {plate, (plate:gsub("%s+", ""))})
end

return Functions.getOwnedVehicle