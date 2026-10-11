-- Lookups from a number to the owning character, which also find offline owners, keyed by PhoneSystem
---@type table<string, fun(phoneNumber: string): CharacterIdentifier?>
local identifierLookups = {
    ["sd-phone"] = function(phoneNumber)
        -- Accepts any formatting, sd-phone compares digits only
        return exports["sd-phone"]:getIdentifierByNumber(phoneNumber)
    end,
}

-- Lookups from a number to the online player using it, keyed by PhoneSystem
-- These compare the exact stored string, so pass the number as Z.getPhoneNumber returned it
-- Quasar exports no lookup, and 17mov_Phone has no entry since its export signatures are not verified
---@type table<string, fun(phoneNumber: string): any>
local sourceLookups = {
    ["lb-phone"] = function(phoneNumber)
        -- Returns false when nobody online has the number equipped
        return exports["lb-phone"]:GetSourceFromNumber(phoneNumber)
    end,
    ["yseries"] = function(phoneNumber)
        -- Only matches the phone set as the owner's primary one
        return exports["yseries"]:GetPlayerSourceIdByPhoneNumber(phoneNumber)
    end,
    ["okokPhone"] = function(phoneNumber)
        return exports["okokPhone"]:getSourceFromPhoneNumber(phoneNumber)
    end,
    ["roadphone"] = function(phoneNumber)
        -- RoadPhone Pro documents a framework player here and base RoadPhone a source, so accept both
        local player = exports["roadphone"]:getPlayerFromPhone(phoneNumber)
        if (type(player) == "table") then return Functions.getPlayerId(player) end

        return player
    end,
    ["gksphone"] = function(phoneNumber)
        return exports["gksphone"]:GetSourceByPhone(phoneNumber)
    end,
    ["high-phone"] = function(phoneNumber)
        local player = exports["high-phone"]:getPlayerByPhone(phoneNumber)

        return player and player.id
    end,
    ["npwd"] = function(phoneNumber)
        -- Async JS export, awaited by the Lua runtime
        local playerData = exports["npwd"]:getPlayerData({phoneNumber = phoneNumber})

        return playerData and playerData.source
    end,
}

-- Used when no phone is running, the framework is then the only place a number can live
---@param phoneNumber string
---@return CharacterIdentifier? identifier
---@return PlayerId? plyId
---@return string? reason
local function lookupFramework(phoneNumber)
    if (Framework == "QB") then
        local player = QB.Functions.GetPlayerByPhone(phoneNumber)
        if (player) then return player.PlayerData.citizenid, player.PlayerData.source end
        if (not MySQL) then return nil, nil, "offlineUnsupported" end

        local identifier = MySQL.scalar.await("SELECT citizenid FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.phone')) = ? LIMIT 1", {phoneNumber})
        if (not identifier) then return nil, nil, "noNumber" end

        return identifier, nil
    end

    if (Framework == "ESX") then
        -- es_extended keeps no number, users.phone_number only exists when a phone resource added it
        if (not Functions.hasDatabaseColumn("users", "phone_number")) then return nil, nil, "noPhoneSystem" end

        local identifier = MySQL.scalar.await("SELECT identifier FROM users WHERE phone_number = ? LIMIT 1", {phoneNumber})
        if (not identifier) then return nil, nil, "noNumber" end

        return identifier, Functions.getPlayerId(identifier)
    end

    return nil, nil, "noPhoneSystem"
end

-- Yields, call it from a thread or handler
---@param phoneNumber string
---@return CharacterIdentifier? identifier
---@return PlayerId? plyId @ nil when the owner is offline
---@return string? reason @ "noPhoneSystem", "noNumber", "offlineUnsupported", "unsupported" or "failed"
function Functions.getPhoneNumberOwner(phoneNumber)
    -- Framework and phone lookups compare strings, a number key would never match
    if (type(phoneNumber) == "number") then phoneNumber = tostring(math.tointeger(phoneNumber) or phoneNumber) end
    if (type(phoneNumber) ~= "string" or phoneNumber == "") then return nil, nil, "noNumber" end
    if (not PhoneSystem) then return lookupFramework(phoneNumber) end

    local lookupIdentifier = identifierLookups[PhoneSystem]
    if (lookupIdentifier) then
        local ok, identifier = pcall(lookupIdentifier, phoneNumber)
        if (not ok) then return nil, nil, "failed" end
        if (not identifier) then return nil, nil, "noNumber" end

        return identifier, Functions.getPlayerId(identifier)
    end

    local lookupSource = sourceLookups[PhoneSystem]
    if (not lookupSource) then return nil, nil, "unsupported" end

    local ok, plyId = pcall(lookupSource, phoneNumber)
    if (not ok) then return nil, nil, "failed" end

    -- These phones only find online owners, so a miss can still be an offline owner
    plyId = tonumber(plyId)
    if (not plyId) then return nil, nil, "offlineUnsupported" end

    local identifier = Functions.getIdentifier(plyId)
    if (not identifier) then return nil, nil, "offlineUnsupported" end

    return identifier, plyId
end

return Functions.getPhoneNumberOwner