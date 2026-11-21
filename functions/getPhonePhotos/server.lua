---@class PhonePhoto
---@field id string @ The phone's own id for the photo
---@field url string @ Wherever the phone hosts it, such as Fivemanage or Zyke Media Studio
---@field isVideo boolean
---@field favorite boolean
---@field takenAt integer @ Unix seconds

-- Most photos one read returns, sd-phone's own page size
local maxPhotos = 200

-- Gallery reads keyed by PhoneSystem, each returning the photos newest first or nil when the player carries no phone
-- Only sd-phone exports its gallery, the other phones keep it to themselves
---@type table<string, fun(plyId: PlayerId, identifier: CharacterIdentifier, limit: integer): table[]?>
local reads = {
    ["sd-phone"] = function(plyId, identifier, limit)
        -- The gallery belongs to the character, the phone item only opens it
        if (not exports["sd-phone"]:hasPhone(plyId)) then return nil end

        local photos = {}

        for _, photo in ipairs(exports["sd-phone"]:getPhotosByIdentifier(identifier, {limit = limit}) or {}) do
            photos[#photos + 1] = {id = photo.id, url = photo.url, isVideo = photo.isVideo == true, favorite = photo.favorite == true, takenAt = math.floor(tonumber(photo.timestamp) or 0)}
        end

        return photos
    end,
}

-- Yields, call it from a thread or handler
-- URLs are the phone's own, never copy them anywhere a player can't already see them
---@param player PlayerId | Character
---@param limit? integer @ At most 200, the default
---@return PhonePhoto[]? photos @ Newest first
---@return string? reason @ "invalidPlayer", "noPhoneSystem", "noPhone", "unsupported" or "failed"
function Functions.getPhonePhotos(player, limit)
    if (not PhoneSystem) then return nil, "noPhoneSystem" end

    local read = reads[PhoneSystem]
    if (not read) then return nil, "unsupported" end

    local playerData = Functions.getPlayerData(player)
    if (not playerData) then return nil, "invalidPlayer" end

    limit = math.min(math.max(math.floor(tonumber(limit) or maxPhotos), 1), maxPhotos)

    local ok, photos = pcall(read, Functions.getPlayerId(playerData), Functions.getIdentifier(playerData), limit)
    if (not ok) then
        Functions.debug.internal("^1" .. PhoneSystem .. " failed to read a phone gallery: " .. tostring(photos) .. "^7")

        return nil, "failed"
    end

    if (not photos) then return nil, "noPhone" end

    return photos
end

return Functions.getPhonePhotos