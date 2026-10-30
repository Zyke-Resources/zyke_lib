-- An owned vehicle row: model is a model name or hash. On ESX a vehicle column that isn't JSON leaves the model out
---@class OwnedVehicle
---@field plate string
---@field identifier? CharacterIdentifier
---@field model? string | integer

local queries = {
    ESX = "SELECT `plate`, `owner` AS `identifier`, IF(JSON_VALID(`vehicle`), JSON_UNQUOTE(JSON_EXTRACT(`vehicle`, '$.model')), NULL) AS `model` FROM `owned_vehicles` WHERE `owner` = ? LIMIT ?",
    QB = "SELECT `plate`, `citizenid` AS `identifier`, COALESCE(`hash`, `vehicle`) AS `model` FROM `player_vehicles` WHERE `citizenid` = ? LIMIT ?",
}

-- Online or offline, needs the calling resource to load @oxmysql/lib/MySQL.lua
---@param identifier CharacterIdentifier
---@param limit integer
---@return OwnedVehicle[] vehicles
function Functions.getOwnedVehicles(identifier, limit)
    local query = queries[Framework]
    if (not query) then return {} end

    return MySQL.query.await(query, {identifier, limit}) or {}
end

return Functions.getOwnedVehicles