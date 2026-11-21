---@class IncomingPhoneMessage
---@field from string @ The sender's number, as the phone stores it
---@field to string @ The watched number, as the phone stores it
---@field message string
---@field plyId? PlayerId @ The sender, nil when they could not be found online

-- Server events fired when a player sends a text, keyed by PhoneSystem
-- Each read returns nil for a text that is not a plain one from a player
-- Only the selected phone's event is read, since sd-phone also fires lb-phone's event
---@type table<string, {event: string, read: fun(data: table): IncomingPhoneMessage?}>
local listeners = {
    ["sd-phone"] = {
        event = "sd-phone:server:messages:sent",
        read = function(data)
            -- System texts are the ones resources send, replies included
            if (data.system or data.group or data.kind ~= "text") then return nil end

            return {from = data.senderNumber, to = data.targetNumber, message = data.body, plyId = data.source}
        end,
    },
    ["lb-phone"] = {
        event = "lb-phone:messages:messageSent",
        read = function(data)
            if (type(data.message) ~= "string" or not data.recipient) then return nil end

            -- The payload has no source, the sender is found from their number
            local _, plyId = Functions.getPhoneNumberOwner(data.sender)

            return {from = data.sender, to = data.recipient, message = data.message, plyId = plyId}
        end,
    },
    ["yseries"] = {
        event = "yseries:server:messages:sent",
        read = function(data)
            -- Ignore system messages (nil senderImei), group chats (table participants), or non-text payloads
            if (not data.senderImei or type(data.participants) ~= "string" or type(data.content) ~= "string") then
                return nil
            end

            -- targetSource in yseries is the recipient, so resolve the sender via phone number
            local _, plyId = Functions.getPhoneNumberOwner(data.sender)

            return {from = data.sender, to = data.participants, message = data.content, plyId = plyId}
        end,
    },
}

-- Calls the handler when a player texts the number, which works for numbers nobody owns
-- Texts are only heard while a supported phone runs, the handler stays registered while another phone runs
-- The handler may yield
---@param phoneNumber string | number @ Compared with Z.normalizePhoneNumber, use digits only since sd-phone strips everything else
---@param handler fun(message: IncomingPhoneMessage)
function Functions.onPhoneMessage(phoneNumber, handler)
    local watched = Functions.normalizePhoneNumber(phoneNumber)
    if (not watched) then error("Z.onPhoneMessage needs a phone number") end

    for system, listener in pairs(listeners) do
        AddEventHandler(listener.event, function(data)
            if (PhoneSystem ~= system or type(data) ~= "table") then return end

            local rawTarget = data.targetNumber or data.recipient or (type(data.participants) == "string" and data.participants or nil)
            if (Functions.normalizePhoneNumber(rawTarget) ~= watched) then return end

            local message = listener.read(data)
            if (not message or message.message == "") then return end

            handler(message)
        end)
    end
end

return Functions.onPhoneMessage
