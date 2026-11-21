---@class PhonePhotoChange
---@field change "added" | "removed"
---@field id string @ The phone's id for the photo
---@field url? string
---@field identifier CharacterIdentifier @ Whose gallery changed
---@field plyId? PlayerId @ nil when the owner is offline

-- Server events fired when a gallery gains or loses a photo, keyed by PhoneSystem
---@type table<string, {event: string, change: "added" | "removed"}[]>
local listeners = {
    ["sd-phone"] = {
        {event = "sd-phone:server:photos:added", change = "added"},
        {event = "sd-phone:server:photos:deleted", change = "removed"},
    },
    ["yseries"] = {
        {event = "yseries:server:gallery:on-photo-added", change = "added"},
        {event = "yseries:server:gallery:on-photo-deleted", change = "removed"},
    },
}

-- Calls the handler when a character's phone gallery gains or loses a photo
-- Only heard while sd-phone or yseries runs. Photos taken, saved and deleted on the phone and saved through Z.addPhonePhoto
-- count, an accepted AirShare does not since sd-phone fires no event for it
-- The handler may yield
---@param handler fun(change: PhonePhotoChange)
function Functions.onPhonePhotoChange(handler)
    for system, events in pairs(listeners) do
        for _, listener in ipairs(events) do
            AddEventHandler(listener.event, function(data, playerIdentifier)
                if (PhoneSystem ~= system or type(data) ~= "table") then return end

                if (system == "yseries") then
                    -- Ignore automated 30-day purges where playerIdentifier is nil and wait for permanent delete or handle soft delete
                    if (type(playerIdentifier) ~= "string" or data.id == nil) then return end

                    local plyId = tonumber(data.playerSource) or Functions.getPlayerId(playerIdentifier)

                    handler({change = listener.change, id = tostring(data.id), url = data.image, identifier = playerIdentifier, plyId = plyId})
                    return
                end

                if (type(data.citizenid) ~= "string" or data.id == nil) then return end

                local plyId = tonumber(data.source) or Functions.getPlayerId(data.citizenid)

                handler({change = listener.change, id = tostring(data.id), url = data.url, identifier = data.citizenid, plyId = plyId})
            end)
        end
    end
end

return Functions.onPhonePhotoChange
