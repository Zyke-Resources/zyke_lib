---@class PlayerIdentifiers
---@field identifier string
---@field source integer
---@field steamid string?
---@field license string?
---@field discord string?
---@field xbl string?
---@field liveid string?

---@field firstname? string
---@field lastname? string

---@type table<string, PlayerIdentifiers>
local playerIdentifiers = {}

---@param player Character | CharacterIdentifier
local function insertIntoIdentifiers(player)
    local player = Functions.getPlayerData(player)
    if (not player) then return end

    local playerId, identifier = Functions.getPlayerId(player), Functions.getIdentifier(player)
    if (not playerId or not identifier) then return end

    local character = Functions.getCharacter(identifier)

    playerIdentifiers[identifier] = {
        identifier = identifier,
        source = playerId,
        firstname = character?.firstname,
        lastname = character?.lastname,
    }

    -- https://docs.fivem.net/docs/scripting-reference/runtimes/lua/functions/GetPlayerIdentifiers/
    for _, id in pairs(GetPlayerIdentifiers(playerId)) do
        local separator = id:find(":")
        if (separator) then
            local key = id:sub(1, separator - 1)
            if (key == "ip") then goto continue end

            local value = id:sub(separator + 1)

            playerIdentifiers[identifier][key] = value

            Player(playerId).state:set("identifier:" .. key, value, true)
            ::continue::
        end
    end
end

AddEventHandler("zyke_lib:OnCharacterSelect", function(plyId, player)
    insertIntoIdentifiers(player)
end)

---@param identifier CharacterIdentifier
---@return PlayerIdentifiers | nil
exports("GetPlayerIdentifiers", function(identifier)
    return playerIdentifiers[identifier] or {}
end)

while (Framework == nil) do Wait(10) end
local players = Functions.getPlayers()
for i = 1, #players do
    local player = Functions.getIdentifier(players[i])
    if (not player) then goto continue end

    insertIntoIdentifiers(player)

    ::continue::
end