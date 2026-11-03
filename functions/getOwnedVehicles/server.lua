-- An owned vehicle row: model is a model name or hash. On ESX a vehicle column that isn't JSON leaves the model out
---@class OwnedVehicle
---@field plate string
---@field identifier? CharacterIdentifier
---@field model? string | integer

---@class OwnedVehicleWithState : OwnedVehicle
---@field state "stored" | "out" | "impounded" @ ESX has no impound state, its vehicles are stored or out

-- ESX owned_vehicles.stored is 1 in a garage, QB and Qbox player_vehicles.state is 0 out, 1 in a garage, 2 impounded
local queries = {
    ESX = "SELECT `plate`, `owner` AS `identifier`, IF(JSON_VALID(`vehicle`), JSON_UNQUOTE(JSON_EXTRACT(`vehicle`, '$.model')), NULL) AS `model`, IF(`stored` = 1, 'stored', 'out') AS `state` FROM `owned_vehicles` WHERE `owner` = ? ORDER BY `plate` LIMIT ?",
    QB = "SELECT `plate`, `citizenid` AS `identifier`, COALESCE(`hash`, `vehicle`) AS `model`, CASE `state` WHEN 1 THEN 'stored' WHEN 2 THEN 'impounded' ELSE 'out' END AS `state` FROM `player_vehicles` WHERE `citizenid` = ? ORDER BY `plate` LIMIT ?",
}

-- Online or offline, needs the calling resource to load @oxmysql/lib/MySQL.lua
---@param identifier CharacterIdentifier
---@param limit integer
---@return OwnedVehicleWithState[] vehicles @ Sorted by plate
function Functions.getOwnedVehicles(identifier, limit)
    local query = queries[Framework]
    if (not query) then return {} end

    return MySQL.query.await(query, {identifier, limit}) or {}
end

return Functions.getOwnedVehicles