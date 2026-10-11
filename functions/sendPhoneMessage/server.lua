---@class PhoneMessageSender
---@field number? string @ Number the text comes from, use digits only since sd-phone strips everything else
---@field name? string @ Display name, shown by phones that support one

-- A string made of digits and separators is a phone number, any other string is a character identifier
local phoneNumberPattern = "^%+?[%d%s%-%(%)]+$"

-- Quasar only sends as an app to an online player, so its sends take the target's source
local sourceOnly = {
    ["qs-smartphone"] = true,
    ["qs-smartphone-pro"] = true,
}

-- Sends keyed by PhoneSystem, each returning whether the phone accepted the text
-- Exports that return nothing are treated as sent
---@type table<string, fun(to: string, message: string, sender: PhoneMessageSender, plyId?: PlayerId): boolean>
local sends = {
    ["sd-phone"] = function(to, message, sender)
        -- Stored for offline targets as well
        return exports["sd-phone"]:sendSystemMessage(sender.number, sender.name, to, message) == true
    end,
    ["lb-phone"] = function(to, message, sender)
        return exports["lb-phone"]:SendMessage(sender.number, to, message) ~= nil
    end,
    ["yseries"] = function(to, message, sender)
        -- Fails when the target number does not exist
        return exports["yseries"]:SendMessageTo(sender.number, to, message) ~= nil
    end,
    ["okokPhone"] = function(to, message, sender)
        return exports["okokPhone"]:sendMessage({sender = sender.number, receiver = to, message = message}) ~= nil
    end,
    ["roadphone"] = function(to, message, sender)
        return exports["roadphone"]:sendMessage(sender.number, to, message) == true
    end,
    ["gksphone"] = function(to, message, sender)
        local result = exports["gksphone"]:SendSystemMessage(to, message, sender.name or sender.number)

        return type(result) == "table" and result.status == true
    end,
    ["qs-smartphone"] = function(_, message, sender, plyId)
        exports["qs-smartphone"]:SendNewMessageFromApp(plyId, sender.name, message)

        return true
    end,
    ["qs-smartphone-pro"] = function(to, message, sender, plyId)
        exports["qs-smartphone-pro"]:sendNewMessageFromApp(plyId, to, message, sender.name)

        return true
    end,
    ["high-phone"] = function(to, message, sender)
        exports["high-phone"]:sendMessage({sender = sender.number, recipient = to, content = message})

        return true
    end,
    ["npwd"] = function(to, message, sender)
        -- Async JS export that returns nothing, and throws when an onMessage handler watches a target texted by a number nobody owns
        exports["npwd"]:emitMessage({senderNumber = sender.number, targetNumber = to, message = message})

        return true
    end,
}

-- Yields, call it from a thread or handler
-- Prefer a player target, a number target has to match the phone's stored format exactly on most phones
---@param target PlayerId | CharacterIdentifier | Character | string @ A player, or a number as Z.getPhoneNumber returned it
---@param message string
---@param sender? PhoneMessageSender @ Defaults to number "0000" and the calling resource's name
---@return boolean sent
---@return string? reason @ "invalidPlayer", "noPhoneSystem", "noNumber", "offlineUnsupported", "unsupported" or "failed"
function Functions.sendPhoneMessage(target, message, sender)
    local send = PhoneSystem and sends[PhoneSystem]
    if (not send) then return false, "unsupported" end
    if (type(message) ~= "string" or message == "") then return false, "failed" end

    sender = sender or {}

    local from = {number = sender.number or "0000", name = sender.name or ResName}
    local isNumberTarget = type(target) == "string" and target:match(phoneNumberPattern) ~= nil
    local to, plyId = nil, nil

    if (isNumberTarget) then
        if (sourceOnly[PhoneSystem]) then return false, "unsupported" end

        to = target
    else
        local reason = nil
        to, reason = Functions.getPhoneNumber(target)
        if (not to) then return false, reason end

        plyId = Functions.getPlayerData(target) and Functions.getPlayerId(target)
        if (sourceOnly[PhoneSystem] and not plyId) then return false, "offlineUnsupported" end
    end

    local ok, sent = pcall(send, to, message, from, plyId)
    if (not ok) then
        Functions.debug.internal("^1" .. PhoneSystem .. " failed to send a phone message: " .. tostring(sent) .. "^7")

        return false, "failed"
    end

    if (not sent) then return false, "failed" end

    return true
end

return Functions.sendPhoneMessage