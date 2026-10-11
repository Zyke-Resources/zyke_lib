-- Reads for an online player, keyed by PhoneSystem
-- High Phone's ownership model and the qs-smartphone-pro and legacy Quasar exports are only known from vendor docs
-- 17mov_Phone has no entry, its export signatures are not verified
---@type table<string, fun(plyId: PlayerId, identifier: CharacterIdentifier): any>
local onlineReads = {
    ["sd-phone"] = function(plyId)
        -- Assigns a number on first use, the same as opening the phone does
        return exports["sd-phone"]:getPhoneNumber(plyId)
    end,
    ["lb-phone"] = function(plyId)
        return exports["lb-phone"]:GetEquippedPhoneNumber(plyId)
    end,
    ["yseries"] = function(plyId)
        return exports["yseries"]:GetPhoneNumberBySourceId(plyId)
    end,
    ["okokPhone"] = function(plyId)
        return exports["okokPhone"]:getPhoneNumberFromSource(plyId)
    end,
    ["roadphone"] = function(plyId, identifier)
        -- Only RoadPhone Pro reads by source, which also follows its phone item and SIM modes
        local isPro, phoneNumber = pcall(function()
            return exports["roadphone"]:getActivePhoneNumber(plyId)
        end)
        if (isPro) then return phoneNumber end

        return exports["roadphone"]:getNumberFromIdentifier(identifier)
    end,
    ["gksphone"] = function(plyId)
        return exports["gksphone"]:GetPhoneBySource(plyId)
    end,
    ["qs-smartphone-pro"] = function(_, identifier)
        -- Returns false without a phone, and takes the identifier instead of the source
        return exports["qs-smartphone-pro"]:GetPhoneNumberFromIdentifier(identifier, false)
    end,
    ["qs-smartphone"] = function(plyId)
        return exports["qs-smartphone"]:GetCurrentPhoneNumber(plyId)
    end,
    ["qs-smartphone-legacy"] = function(plyId)
        return exports["qs-base"]:GetPlayerPhone(plyId)
    end,
    ["high-phone"] = function(plyId)
        return exports["high-phone"]:getPlayerPhoneNumber(plyId)
    end,
    ["npwd"] = function(plyId)
        -- Async JS export, awaited by the Lua runtime
        local playerData = exports["npwd"]:getPlayerData({source = plyId})

        return playerData and playerData.phoneNumber
    end,
}

-- Reads for an offline character, only for phones that export one
---@type table<string, fun(identifier: CharacterIdentifier): any>
local offlineReads = {
    ["sd-phone"] = function(identifier)
        -- Never pass ensure, so no number is assigned to a character that is not playing
        return exports["sd-phone"]:getPhoneNumberByIdentifier(identifier)
    end,
    ["lb-phone"] = function(identifier)
        return exports["lb-phone"]:GetEquippedPhoneNumber(identifier)
    end,
    ["yseries"] = function(identifier)
        return exports["yseries"]:GetPhoneNumberByIdentifier(identifier)
    end,
    ["roadphone"] = function(identifier)
        return exports["roadphone"]:getNumberFromIdentifier(identifier)
    end,
    ["qs-smartphone-pro"] = function(identifier)
        return exports["qs-smartphone-pro"]:GetPhoneNumberFromIdentifier(identifier, false)
    end,
}

-- Phones return strings, numbers, false or empty strings when there is no number
---@param value any
---@return string? phoneNumber
local function toPhoneNumber(value)
    if (type(value) == "number") then value = tostring(math.tointeger(value) or value) end
    if (type(value) ~= "string" or value == "") then return nil end

    return value
end

---@param read fun(...): any
---@param ... any
---@return string? phoneNumber
---@return string? reason
local function readProvider(read, ...)
    local ok, value = pcall(read, ...)
    if (not ok) then
        Functions.debug.internal("^1" .. tostring(PhoneSystem) .. " failed to read a phone number: " .. tostring(value) .. "^7")

        return nil, "failed"
    end

    local phoneNumber = toPhoneNumber(value)
    if (not phoneNumber) then return nil, "noNumber" end

    return phoneNumber
end

-- Used when no phone is running, the framework is then the only place a number can live
---@param identifier CharacterIdentifier
---@param player? Character @ nil for an offline character
---@return string? phoneNumber
---@return string? reason
local function readFramework(identifier, player)
    if (Framework == "QB") then
        player = player or Functions.getOfflinePlayer(identifier)

        local charinfo = player and player.PlayerData.charinfo
        local phoneNumber = toPhoneNumber(charinfo and charinfo.phone)
        if (not phoneNumber) then return nil, "noNumber" end

        return phoneNumber
    end

    if (Framework == "ESX") then
        local phoneNumber = player and toPhoneNumber(player.get("phoneNumber"))
        if (phoneNumber) then return phoneNumber end

        -- es_extended keeps no number, users.phone_number only exists when a phone resource added it
        if (not Functions.hasDatabaseColumn("users", "phone_number")) then return nil, "noPhoneSystem" end

        phoneNumber = toPhoneNumber(MySQL.scalar.await("SELECT phone_number FROM users WHERE identifier = ?", {identifier}))
        if (not phoneNumber) then return nil, "noPhoneSystem" end

        return phoneNumber
    end

    return nil, "noPhoneSystem"
end

-- Yields, call it from a thread or handler
-- The number is returned as the phone stores it, compare numbers with Z.normalizePhoneNumber
---@param player Character | CharacterIdentifier | PlayerId
---@return string? phoneNumber
---@return string? reason @ "invalidPlayer", "noPhoneSystem", "noNumber", "offlineUnsupported", "unsupported" or "failed"
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getPhoneNumber(player)
    local playerData = Functions.getPlayerData(player)
    if (playerData) then
        local identifier = Functions.getIdentifier(playerData)
        if (not PhoneSystem) then return readFramework(identifier, playerData) end

        local read = onlineReads[PhoneSystem]
        if (not read) then return nil, "unsupported" end

        return readProvider(read, Functions.getPlayerId(playerData), identifier)
    end

    if (not Functions.isCharacterIdentifierValid(player)) then return nil, "invalidPlayer" end
    if (not PhoneSystem) then return readFramework(player) end

    local read = offlineReads[PhoneSystem]
    if (not read) then return nil, onlineReads[PhoneSystem] and "offlineUnsupported" or "unsupported" end

    return readProvider(read, player)
end

---@param plyId PlayerId
Functions.callback.register(ResName .. ":GetPhoneNumber", function(plyId)
    return Functions.getPhoneNumber(plyId)
end)

return Functions.getPhoneNumber