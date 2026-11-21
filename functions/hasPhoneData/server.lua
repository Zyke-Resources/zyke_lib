-- Checks keyed by PhoneSystem, each returning whether the player's phone can use mobile data right now
---@type table<string, fun(plyId: PlayerId): boolean, string?>
local checks = {
    ["sd-phone"] = function(plyId)
        if (exports["sd-phone"]:isAirplaneMode(plyId)) then return false, "airplaneMode" end

        -- Signal from its cell towers or a Wi-Fi network the phone is on, always true while it has no towers
        if (not exports["sd-phone"]:hasService(plyId, "data")) then return false, "noService" end

        return true
    end,
    ["lb-phone"] = function(plyId)
        local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(plyId)
        if (not phoneNumber) then return false, "noPhone" end

        -- lb-phone has no signal the server can read
        if (exports["lb-phone"]:HasAirplaneMode(phoneNumber)) then return false, "airplaneMode" end

        return true
    end,
    ["yseries"] = function(plyId)
        local phoneImei = exports["yseries"]:GetPhoneImeiBySourceId(plyId)
        if (not phoneImei) then return false, "noPhone" end

        -- YSeries tracks airplane mode via player state bags; it has no server-side signal export
        if (Player(plyId).state.airplaneMode == true) then return false, "airplaneMode" end

        return true
    end,
}

-- Whether the player's phone can go online over mobile data right now, such as for an app that loads from the server
---@param plyId PlayerId
---@return boolean hasData
---@return string? reason @ "unsupported", "noPhone", "airplaneMode" or "noService"
function Functions.hasPhoneData(plyId)
    local check = PhoneSystem and checks[PhoneSystem]
    if (not check) then return false, "unsupported" end

    return check(plyId)
end

return Functions.hasPhoneData
